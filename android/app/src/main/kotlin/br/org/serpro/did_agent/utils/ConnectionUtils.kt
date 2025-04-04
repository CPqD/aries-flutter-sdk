package br.org.serpro.did_agent.utils

import android.util.Log
import kotlinx.coroutines.runBlocking
import org.hyperledger.ariesframework.agent.Agent
import org.hyperledger.ariesframework.credentials.models.CredentialState
import org.hyperledger.ariesframework.proofs.models.ProofState

class ConnectionUtils {
    companion object {
        suspend fun getAllAsMaps(agent: Agent, hideMediator: Boolean): List<Map<String, Any?>> {
            val connections = agent.connectionRepository.getAll()

            Log.d("MainActivity", "connections: connections")

            val connectionsList = mutableListOf<Map<String, Any?>>()

            for (connection in connections) {
                if (hideMediator && connection.mediatorId == null) {
                    continue
                }
                connectionsList.add(JsonConverter.toMap(connection))
            }

            return connectionsList
        }

        data class ConnectionHistory(
            val credentialsMap: Collection<Map<String, Any?>>,
            val proofsMap: Collection<Map<String, Any?>>,
            val basicMessagesList: Collection<Map<String, Any?>>
        )

        suspend fun getHistory(agent: Agent, connectionId: String): ConnectionHistory {
            val credentialsMap = emptyMap<String, Map<String, Any?>>().toMutableMap()
            val proofsMap = emptyMap<String, Map<String, Any?>>().toMutableMap()
            val basicMessagesList = mutableListOf<Map<String, Any?>>()

            val credentials = agent.credentialExchangeRepository.findByQuery(
                "{\"connectionId\": \"${connectionId}\"}"
            )

            for (record in credentials) {
                if (credentialsMap.containsKey(record.id) && record.state != CredentialState.OfferSent) {
                    continue
                }
                credentialsMap[record.id] = JsonConverter.toMap(record)
            }

            val proofs = agent.proofRepository.findByQuery("{\"connectionId\": \"${connectionId}\"}")

            for (record in proofs) {
                if (proofsMap.containsKey(record.id) && record.state != ProofState.RequestSent) {
                    continue
                }
                proofsMap[record.id] = JsonConverter.toMap(record)
            }

            val basicMessages = runBlocking { agent.basicMessageRepository.findByConnectionRecordId(connectionId) }

            for (basicMessage in basicMessages) {
                basicMessagesList.add(JsonConverter.toMap(basicMessage))
            }

            Log.d("ConnectionUtils", "credentialsMap: $credentialsMap")
            Log.d("ConnectionUtils", "proofsMap: $proofsMap")
            Log.d("ConnectionUtils", "basicMessagesList: $basicMessagesList")

            return ConnectionHistory(credentialsMap.values, proofsMap.values, basicMessagesList)
        }
    }
}