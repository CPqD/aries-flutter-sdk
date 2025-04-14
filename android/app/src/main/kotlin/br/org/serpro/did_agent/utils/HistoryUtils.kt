package br.org.serpro.did_agent.utils

import org.hyperledger.ariesframework.agent.Agent
import org.hyperledger.ariesframework.history.repository.HistoryRecord

class HistoryUtils {
    companion object {
        suspend fun getHistoryFromTypes(
            agent: Agent,
            types: List<String>,
            connectionId: String?,
            associatedRecordId: String?,
        ): List<Map<String, Any?>> {
            val historyList = mutableListOf<HistoryRecord>()
            val queryList = mutableListOf<String>()

            if (!connectionId.isNullOrEmpty()) {
                queryList.add("\"connectionId\": \"$connectionId\"")
            }

            if (!associatedRecordId.isNullOrEmpty()) {
                queryList.add("\"associatedRecordId\": \"$associatedRecordId\"")
            }

            if (types.isEmpty()) {
                val query = "{${queryList.joinToString(", ")}}"
                historyList.addAll(agent.historyRepository.findByQuery(query))
            } else {
                for (historyType in types) {
                    val query = "{${queryList.joinToString(", ")}, \"historyType\": \"$historyType\"}"
                    historyList.addAll(agent.historyRepository.findByQuery(query))
                }
            }

            val result = mutableListOf<Map<String, Any?>>()

            for (record in historyList) {
                result.add(JsonConverter.toMap(record))
            }

            return result
        }
    }
}