package br.org.serpro.did_agent.utils

import android.util.Log
import org.hyperledger.ariesframework.agent.Agent

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

        suspend fun getHistoryFromTypes(agent: Agent, types: List<String>, connectionId: String): List<Map<String, Any?>> {
            return HistoryUtils.getHistoryFromTypes(agent, types, connectionId, null)
        }
    }
}