package org.hyperledger.ariesframework.routing.repository

import android.util.Log
import org.hyperledger.ariesframework.agent.Agent
import org.hyperledger.ariesframework.storage.Repository

class MediationRepository(agent: Agent) : Repository<MediationRecord>(MediationRecord::class, agent) {
    suspend fun getByConnectionId(connectionId: String): MediationRecord {
        Log.e("MediationRepository","--> getByConnectionId($connectionId)\n\n")

        return getSingleByQuery("{\"connectionId\": \"$connectionId\"}")
    }

    suspend fun getDefault(): MediationRecord? {
        Log.e("MediationRepository","--> getDefault\n\n")

        return findSingleByQuery("{}")
    }
}
