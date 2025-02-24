package br.org.serpro.did_agent.askar

import kotlinx.coroutines.CancellationException
import br.org.serpro.did_agent.askar.ErrorCodeException
import br.org.serpro.did_agent.askar.AskarLocalKey

class AskarSession {

    @Throws(ErrorCodeException::class, CancellationException::class)
    suspend fun close() {
        // Implement the logic to close the session
    }

    @Throws(ErrorCodeException::class, CancellationException::class)
    suspend fun count(category: String, tagFilter: String?): Long {
        // Implement the logic to count entries
        return 0L
    }

    @Throws(ErrorCodeException::class, CancellationException::class)
    suspend fun fetch(category: String, name: String, forUpdate: Boolean): AskarEntry? {
        // Implement the logic to fetch an entry
        return null
    }

    @Throws(ErrorCodeException::class, CancellationException::class)
    suspend fun fetchAll(category: String, tagFilter: String?, limit: Long?, forUpdate: Boolean): List<AskarEntry> {
        // Implement the logic to fetch all entries
        return emptyList()
    }

    @Throws(ErrorCodeException::class, CancellationException::class)
    suspend fun fetchAllKeys(algorithm: String?, thumbprint: String?, tagFilter: String?, limit: Long?, forUpdate: Boolean): List<AskarKeyEntry> {
        // Implement the logic to fetch all keys
        return emptyList()
    }

    @Throws(ErrorCodeException::class, CancellationException::class)
    suspend fun fetchKey(name: String, forUpdate: Boolean): AskarKeyEntry? {
        // Implement the logic to fetch a key
        return null
    }

    @Throws(ErrorCodeException::class, CancellationException::class)
    suspend fun insertKey(name: String, key: AskarLocalKey, metadata: String?, tags: String?, expiryMs: Long?) {
        // Implement the logic to insert a key
    }

    @Throws(ErrorCodeException::class, CancellationException::class)
    suspend fun removeAll(category: String, tagFilter: String?): Long {
        // Implement the logic to remove all entries
        return 0L
    }

    @Throws(ErrorCodeException::class, CancellationException::class)
    suspend fun removeKey(name: String) {
        // Implement the logic to remove a key
    }

    @Throws(ErrorCodeException::class, CancellationException::class)
    suspend fun update(operation: AskarEntryOperation, category: String, name: String, value: ByteArray, tags: String?, expiryMs: Long?) {
        // Implement the logic to update an entry
    }

    @Throws(ErrorCodeException::class, CancellationException::class)
    suspend fun updateKey(name: String, metadata: String?, tags: String?, expiryMs: Long?) {
        // Implement the logic to update a key
    }
}