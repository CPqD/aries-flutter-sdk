package org.hyperledger.ariesframework.anoncreds.storage

import android.util.Log
import org.hyperledger.ariesframework.agent.Agent
import org.hyperledger.ariesframework.storage.Repository

class CredentialDefinitionRepository(agent: Agent) : Repository<CredentialDefinitionRecord>(
    CredentialDefinitionRecord::class,
    agent,
) {
    suspend fun getByCredDefId(credDefId: String): CredentialDefinitionRecord {
        Log.e("CredentialDefinitionRepository","--> getByCredDefId\n\n")

        return getSingleByQuery("{\"credDefId\": \"$credDefId\"}")
    }
}
