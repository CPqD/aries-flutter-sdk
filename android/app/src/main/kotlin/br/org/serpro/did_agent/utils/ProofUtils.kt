package br.org.serpro.did_agent.utils

import android.util.Log
import kotlinx.coroutines.runBlocking
import kotlinx.serialization.json.Json
import org.hyperledger.ariesframework.agent.Agent
import org.hyperledger.ariesframework.agent.MessageSerializer
import org.hyperledger.ariesframework.proofs.messages.v1.RequestPresentationMessage
import org.hyperledger.ariesframework.proofs.messages.v2.RequestPresentationMessageV2
import org.hyperledger.ariesframework.proofs.models.ProofRequest
import org.hyperledger.ariesframework.proofs.models.ProofState
import org.hyperledger.ariesframework.proofs.models.RequestedCredentials
import org.hyperledger.ariesframework.proofs.models.RequestedPredicate
import org.hyperledger.ariesframework.proofs.models.RetrievedCredentials
import org.hyperledger.ariesframework.proofs.repository.ProofExchangeRecord
import org.hyperledger.ariesframework.storage.DidCommMessageRecord

class ProofUtils {
    companion object {
        suspend fun acceptRequest(
            agent: Agent,
            proofRecordId: String,
            selectedCredentialsAttributes: Map<String, String>,
            selectedCredentialsPredicates: Map<String, String>
        ): ProofExchangeRecord {
            val retrievedCredentials = agent.proofs.getRequestedCredentialsForProofRequest(proofRecordId)
            Log.e("ProofUtils","acceptProofOffer - retrievedCredentials.requestedAttributes: ${retrievedCredentials.requestedAttributes}")
            Log.e("ProofUtils","acceptProofOffer - retrievedCredentials.requestedPredicates: ${retrievedCredentials.requestedPredicates}")

            val requestedCredentials = RequestedCredentials()

            retrievedCredentials.requestedAttributes.keys.forEach { attributeName ->
                val attributeArray = retrievedCredentials.requestedAttributes[attributeName]!!

                val validAttributes = attributeArray.filter { attr ->
                    attr.revoked != true && selectedCredentialsAttributes[attributeName]?.equals(attr.credentialId) == true
                }

                if (validAttributes.isEmpty()) {
                    throw Exception("Cannot find valid credentials for attribute '$attributeName'.")
                }
                requestedCredentials.requestedAttributes[attributeName] = validAttributes[0]
            }

            retrievedCredentials.requestedPredicates.keys.forEach { predicateName ->
                val predicateArray = retrievedCredentials.requestedPredicates[predicateName]!!

                val validPredicates = predicateArray.filter { pred ->
                    pred.revoked != true  && selectedCredentialsPredicates[predicateName]?.equals(pred.credentialId) == true
                }

                if (validPredicates.isEmpty()) {
                    throw Exception("Cannot find non-revoked credentials for predicate '$predicateName'.")
                }
                requestedCredentials.requestedPredicates[predicateName] = validPredicates[0]
            }

            return agent.proofs.acceptRequest(proofRecordId, requestedCredentials)
        }

        suspend fun findByState(agent: Agent, proofState: ProofState): MutableList<Map<String, Any?>> {
            val proofsReceived = agent.proofRepository.findByQuery("{\"state\": \"${proofState}\"}")

            val proofOffersList = mutableListOf<Map<String, Any?>>()

            if (proofsReceived.isEmpty()) {
                return proofOffersList
            }

            for (proofExchangeRecord in proofsReceived) {
                proofOffersList.add(JsonConverter.toMap(proofExchangeRecord))
            }

            return proofOffersList
        }

        suspend fun getDetails(
            agent: Agent,
            proofRecordId: String
        ): Triple<MutableList<Map<String, Any?>>, MutableList<Map<String, Any?>>, String> {
            val attributesList = mutableListOf<Map<String, Any?>>()
            val predicatesList = mutableListOf<Map<String, Any?>>()

            val recordMessageType = agent.didCommMessageRepository.getSingleByQuery(
                "{\"associatedRecordId\": \"$proofRecordId\"}"
            )

            val proofRequestJson = getProofRequestJson(agent, proofRecordId, recordMessageType)
            Log.d("ProofUtils", "proofRequestJson: $proofRequestJson")

            val proofRequest = Json.decodeFromString<ProofRequest>(proofRequestJson)
            Log.d("ProofUtils", "proofRequest: $proofRequest")

            val retrievedCredentials = agent.proofService.getRequestedCredentialsForProofRequest(proofRequest)

            Log.d(
                "ProofUtils",
                "retrievedCredentials.requestedAttributes: ${retrievedCredentials.requestedAttributes}"
            )

            Log.d(
                "ProofUtils",
                "retrievedCredentials.requestedPredicates: ${retrievedCredentials.requestedPredicates}"
            )

            retrievedCredentials.requestedAttributes.keys.forEach { schemaName ->
                var errorMsg = ""

                val attributeArray = retrievedCredentials.requestedAttributes[schemaName]!!

                if (attributeArray.isEmpty()) {
                    errorMsg = "Não há nenhuma credencial do tipo '$schemaName'."
                }

                for (attr in attributeArray) {
                    Log.d("MainActivity", "attr in attributeArray: $attr")
                }

                val nonRevoked = attributeArray.filter { attr -> attr.revoked != true }
                if (errorMsg.isEmpty() && nonRevoked.isEmpty()) {
                    errorMsg = "Não há nenhuma credencial não revogada do tipo '$schemaName'."
                }

                attributesList.add(
                    mapOf(
                        "error" to errorMsg,
                        "name" to schemaName,
                        "availableCredentials" to JsonConverter.toRequestedAttributesList(
                            nonRevoked
                        )
                    )
                )
            }

            retrievedCredentials.requestedPredicates.keys.forEach { predicateName ->
                var errorMsg = ""

                val predicateArray = retrievedCredentials.requestedPredicates[predicateName]!!

                if (predicateArray.isEmpty()) {
                    errorMsg = "Não há nenhuma credencial relacionada a '$predicateName'."
                }

                val availableCredentials = predicateArray
                    .filter { pred -> pred.revoked != true }
                    .map { pred -> credentialPredicateValidation(agent, predicateName, pred, proofRequestJson) }

                if (errorMsg.isEmpty() && availableCredentials.isEmpty()) {
                    errorMsg =
                        "Não há nenhuma credencial não revogada relacionada a '$predicateName'."
                }

                predicatesList.add(
                    mapOf(
                        "error" to errorMsg,
                        "name" to predicateName,
                        "availableCredentials" to availableCredentials
                    )
                )
            }

            Log.d("ProofUtils", "attributesList: $attributesList")
            Log.d("ProofUtils", "predicatesList: $predicatesList")

            return Triple(attributesList, predicatesList, proofRequestJson)
        }

        private suspend fun credentialPredicateValidation(
            agent: Agent,
            predicateName: String,
            requestedPredicate: RequestedPredicate,
            proofRequestJson: String
        ): Map<String, Any?> {
            Log.d("ProofUtils", "credentialPredicateValidation for $predicateName")

            var predicateError = ""
            val requestedCredentials = RequestedCredentials()

            requestedCredentials.requestedPredicates[predicateName] = requestedPredicate

            try {
                agent.proofService.createProof(
                    proofRequestJson,
                    requestedCredentials
                )

                Log.d("ProofUtils", "proofService.createProof OK")

            } catch (e: Exception) {
                Log.d("ProofUtils", "proofService.createProof ERROR: $e")

                predicateError = e.toString()
            }

            val resultMap = JsonConverter.toMap(requestedPredicate).toMutableMap()
            resultMap["predicateError"] = predicateError

            return resultMap
        }

        private suspend fun getProofRequestJson(
            agent: Agent,
            proofRecordId: String,
            recordMessageType: DidCommMessageRecord
        ): String {
            if (recordMessageType.message.contains("/2.0/")) {
                val proofRequestMessageJson = agent.didCommMessageRepository.getAgentMessage(
                    proofRecordId,
                    RequestPresentationMessageV2.type,
                )

                val proofRequestMessage =
                    MessageSerializer.decodeFromString(proofRequestMessageJson) as RequestPresentationMessageV2

                return proofRequestMessage.indyProofRequest()
            } else {
                val proofRequestMessageJson = agent.didCommMessageRepository.getAgentMessage(
                    proofRecordId,
                    RequestPresentationMessage.type,
                )

                val proofRequestMessage =
                    MessageSerializer.decodeFromString(proofRequestMessageJson) as RequestPresentationMessage

                return proofRequestMessage.indyProofRequest()
            }
        }
    }
}