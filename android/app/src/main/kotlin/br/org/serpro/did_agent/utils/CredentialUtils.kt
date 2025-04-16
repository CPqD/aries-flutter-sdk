package br.org.serpro.did_agent.utils

import android.util.Log
import org.hyperledger.ariesframework.agent.Agent
import org.hyperledger.ariesframework.anoncreds.storage.CredentialRecord
import org.hyperledger.ariesframework.credentials.models.AcceptOfferOptions
import org.hyperledger.ariesframework.credentials.models.CredentialPreviewAttribute
import org.hyperledger.ariesframework.credentials.models.CredentialRole
import org.hyperledger.ariesframework.credentials.models.CredentialState
import org.hyperledger.ariesframework.credentials.repository.CredentialExchangeRecord
import org.hyperledger.ariesframework.credentials.repository.CredentialRecordBinding
import org.hyperledger.ariesframework.credentials.v1.models.AutoAcceptCredential
import org.hyperledger.ariesframework.history.models.HistoryType
import org.hyperledger.ariesframework.history.repository.HistoryRecord
import org.hyperledger.ariesframework.revocationnotification.model.RevocationNotification

class CredentialUtils {
    companion object {
        suspend fun acceptOffer(agent: Agent, credentialRecordId: String, protocolVersion: String): CredentialExchangeRecord {
            val acceptOfferOption = AcceptOfferOptions(
                credentialRecordId = credentialRecordId,
                autoAcceptCredential = AutoAcceptCredential.Always
            )

            if (protocolVersion == "v2") {
                return agent.credentialsV2.acceptOffer(acceptOfferOption)
            }

            return agent.credentials.acceptOffer(acceptOfferOption)
        }

        suspend fun declineOffer(agent: Agent, credentialRecordId: String, protocolVersion: String): CredentialExchangeRecord {
            val acceptOfferOption = AcceptOfferOptions(
                credentialRecordId = credentialRecordId,
                autoAcceptCredential = AutoAcceptCredential.Never
            )

            if (protocolVersion == "v2") {
                return agent.credentialsV2.declineOffer(acceptOfferOption)
            }

            return agent.credentials.declineOffer(acceptOfferOption)
        }

        suspend fun getAllAsMaps(agent: Agent): List<Map<String, Any?>> {
            val credentials = agent.credentialRepository.getAll()

            Log.d("CredentialUtils", "credentials: ${credentials.toString()}")

//          TODO - remove
            for (credential in credentials) {
                Log.d("CredentialUtils", "credential: ${credential.credentialId} - comment=${credential.revocationNotification?.comment} date=${credential.revocationNotification?.revocationDate}")
            }

            val credentialsList = mutableListOf<Map<String, Any?>>()

            for (credential in credentials) {
                credentialsList.add(JsonConverter.toMap(credential))
            }

            return credentialsList
        }

        suspend fun getDetails(agent: Agent, credentialId: String): Map<String, Any?>? {
            val credential: CredentialRecord

            try {
                credential = agent.credentialRepository.getById(credentialId)
            } catch (e: Exception) {
                return null
            }

            Log.d("CredentialUtils", "credential: $credential")

            return JsonConverter.toMap(credential)
        }

        suspend fun getHistory(agent: Agent, credentialId: String): List<Map<String, Any?>> {
            val historyList = mutableListOf<HistoryRecord>()

            historyList.addAll(
                agent.historyRepository.findByQuery("{\"associatedRecordId\": \"$credentialId\"}")
            )

            historyList.addAll(
                agent.historyRepository.findByQuery(
                    "{\"historyType\": \"${HistoryType.ProofRequestAccepted}\", \"credIdAttr:${credentialId}\": \"true\"}"
                )
            )

            historyList.addAll(
                agent.historyRepository.findByQuery(
                    "{\"historyType\": \"${HistoryType.ProofRequestAccepted}\", \"credIdPred:${credentialId}\": \"true\"}"
                )
            )

            val result = mutableListOf<Map<String, Any?>>()

            for (historyRecord in historyList.sortedBy { it.createdAt }) {
                result.add(JsonConverter.toMap(historyRecord))
            }

            return result
        }

        suspend fun getExchangesByState(agent: Agent, state: CredentialState): List<Map<String, Any?>> {
            val credentialsReceived = agent.credentialExchangeRepository.findByQuery("{\"state\": \"${state}\"}")

            Log.d("CredentialUtils", "credentialsReceived size: ${credentialsReceived.size}")

            val credentialsOffersList = mutableListOf<Map<String, Any?>>()

            for (credentialExchangeRecord in credentialsReceived) {
                credentialsOffersList.add(JsonConverter.toMap(credentialExchangeRecord))
            }

            return credentialsOffersList
        }
    }
}