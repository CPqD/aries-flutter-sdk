package br.org.serpro.did_agent.askar

import br.org.serpro.did_agent.askar.ErrorCodeException
import br.org.serpro.did_agent.askar.AskarLocalKey

class AskarKeyEntry(
    private val algorithm: String?,
    private val isLocal: Boolean,
    private val metadata: String?,
    private val name: String,
    private val tags: Map<String, String>
) {

    fun algorithm(): String? {
        return algorithm
    }

    fun isLocal(): Boolean {
        return isLocal
    }

    @Throws(ErrorCodeException::class)
    fun loadLocalKey(): AskarLocalKey {
        // Implement the logic to load the local key
        return AskarLocalKey()
    }

    fun metadata(): String? {
        return metadata
    }

    fun name(): String {
        return name
    }

    fun tags(): Map<String, String> {
        return tags
    }
}