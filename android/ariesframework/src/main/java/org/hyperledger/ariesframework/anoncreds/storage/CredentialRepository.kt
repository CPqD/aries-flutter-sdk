package org.hyperledger.ariesframework.anoncreds.storage

import android.util.Log
import org.hyperledger.ariesframework.agent.Agent
import org.hyperledger.ariesframework.storage.Repository

class CredentialRepository(agent: Agent) : Repository<CredentialRecord>(
    CredentialRecord::class,
    agent,
) {
    suspend fun getByCredentialId(credentialId: String): CredentialRecord {
        Log.e("CredentialRepository","--> getByCredentialId($credentialId)\n\n")

        return getSingleByQuery("{\"credentialId\": \"$credentialId\"}")
    }
}
