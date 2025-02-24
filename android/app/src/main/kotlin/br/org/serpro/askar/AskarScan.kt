package br.org.serpro.did_agent.askar

import kotlinx.coroutines.CancellationException
import br.org.serpro.did_agent.askar.ErrorCodeException

class AskarScan {
    @Throws(ErrorCodeException::class, CancellationException::class)
    suspend fun fetchAll(): List<AskarEntry> {
        // Implement the logic to fetch all entries
        return emptyList()
    }

    @Throws(ErrorCodeException::class, CancellationException::class)
    suspend fun next(): List<AskarEntry>? {
        // Implement the logic to fetch the next set of entries
        return null
    }
}