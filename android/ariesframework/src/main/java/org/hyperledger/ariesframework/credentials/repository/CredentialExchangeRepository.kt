package org.hyperledger.ariesframework.credentials.repository

import android.util.Log
import org.hyperledger.ariesframework.agent.Agent
import org.hyperledger.ariesframework.storage.Repository

class CredentialExchangeRepository(agent: Agent) : Repository<CredentialExchangeRecord>(CredentialExchangeRecord::class, agent) {
    suspend fun findByThreadAndConnectionId(threadId: String, connectionId: String?): CredentialExchangeRecord? {
        Log.e("CredentialExchangeRepository","--> findByThreadAndConnectionId('$threadId', '$connectionId')\n\n")


        return if (connectionId != null) {
            findSingleByQuery("{\"threadId\": \"$threadId\", \"connectionId\": \"$connectionId\"}")
        } else {
            findSingleByQuery("{\"threadId\": \"$threadId\"}")
        }
    }

    suspend fun getByThreadAndConnectionId(threadId: String, connectionId: String?): CredentialExchangeRecord {
        Log.e("CredentialExchangeRepository","--> getByThreadAndConnectionId('$threadId', '$connectionId')\n\n")


        return if (connectionId != null) {
            getSingleByQuery("{\"threadId\": \"$threadId\", \"connectionId\": \"$connectionId\"}")
        } else {
            getSingleByQuery("{\"threadId\": \"$threadId\"}")
        }
    }
}
