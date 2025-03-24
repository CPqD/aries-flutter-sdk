package br.org.serpro.did_agent.utils

import android.util.Log
import kotlinx.serialization.json.Json
import org.hyperledger.ariesframework.agent.Agent
import org.hyperledger.ariesframework.agent.MessageSerializer
import org.hyperledger.ariesframework.proofs.messages.v1.RequestPresentationMessage
import org.hyperledger.ariesframework.proofs.messages.v2.RequestPresentationMessageV2
import org.hyperledger.ariesframework.proofs.models.ProofRequest
import org.hyperledger.ariesframework.proofs.models.ProofState
import org.hyperledger.ariesframework.proofs.models.RequestedCredentials
import org.hyperledger.ariesframework.proofs.repository.ProofExchangeRecord

class ProofUtils {
    companion object {
        suspend fun acceptRequest(agent: Agent, proofRecordId: String, selectedCredentialsAttributes: Map<String, String>, selectedCredentialsPredicates: Map<String, String>): ProofExchangeRecord {
            val retrievedCredentials = agent.proofs.getRequestedCredentialsForProofRequest(proofRecordId)
            Log.e("MainActivity","acceptProofOffer - retrievedCredentials.requestedAttributes: ${retrievedCredentials.requestedAttributes}")
            Log.e("MainActivity","acceptProofOffer - retrievedCredentials.requestedPredicates: ${retrievedCredentials.requestedPredicates}")

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

        suspend fun getDetails(agent: Agent, proofRecordId: String): Triple<MutableList<Map<String, Any?>>, MutableList<Map<String, Any?>>, String> {
            val attributesList = mutableListOf<Map<String, Any?>>()
            val predicatesList = mutableListOf<Map<String, Any?>>()
            val proofRequestJson: String

            val recordMessageType = agent.didCommMessageRepository.getSingleByQuery("{\"associatedRecordId\": \"$proofRecordId\"}")

            if (recordMessageType.message.contains("/2.0/")) {
                val proofRequestMessageJson = agent.didCommMessageRepository.getAgentMessage(
                    proofRecordId,
                    RequestPresentationMessageV2.type,
                )

                val proofRequestMessage =
                    MessageSerializer.decodeFromString(proofRequestMessageJson) as RequestPresentationMessageV2

                proofRequestJson = proofRequestMessage.indyProofRequest()
            } else {
                val proofRequestMessageJson = agent.didCommMessageRepository.getAgentMessage(
                    proofRecordId,
                    RequestPresentationMessage.type,
                )

                val proofRequestMessage =
                    MessageSerializer.decodeFromString(proofRequestMessageJson) as RequestPresentationMessage

                proofRequestJson = proofRequestMessage.indyProofRequest()
            }

            Log.d("MainActivity", "proofRequestJson: $proofRequestJson")

            val proofRequest = Json.decodeFromString<ProofRequest>(proofRequestJson)
            Log.d("MainActivity", "proofRequest: $proofRequest")

            val retrievedCredentials = agent.proofService.getRequestedCredentialsForProofRequest(proofRequest)

            Log.d(
                "MainActivity",
                "retrievedCredentials.requestedAttributes: ${retrievedCredentials.requestedAttributes}"
            )
            Log.d(
                "MainActivity",
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

                val nonRevoked = predicateArray.filter { pred -> pred.revoked != true }
                if (errorMsg.isEmpty() && nonRevoked.isEmpty()) {
                    errorMsg =
                        "Não há nenhuma credencial não revogada relacionada a '$predicateName'."
                }

                predicatesList.add(
                    mapOf(
                        "error" to errorMsg,
                        "name" to predicateName,
                        "availableCredentials" to JsonConverter.toRequestedPredicatesList(
                            nonRevoked
                        )
                    )
                )
            }

            Log.d("MainActivity", "attributesList: $attributesList")
            Log.d("MainActivity", "predicatesList: $predicatesList")

//            val requestedCredentials = agent.proofService.autoSelectCredentialsForProofRequest(retrievedCredentials)
//
//            Log.d("MainActivity", "requestedCredentials: $requestedCredentials")
//
//            val proof = runBlocking {
//                agent.proofService.createProof(
//                    proofRequestJson,
//                    requestedCredentials
//                )
//            }
//            Log.d("MainActivity", "proof: $proof")

            return Triple(attributesList, predicatesList, proofRequestJson)
        }
    }
}