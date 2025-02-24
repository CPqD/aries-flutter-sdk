package br.org.serpro.did_agent.askar

class AskarEntry(
    private val category: String,
    private val name: String,
    private val tags: Map<String, String>,
    private val value: ByteArray
)  {

    fun category(): String {
        return category
    }

    fun name(): String {
        return name
    }

    fun tags(): Map<String, String> {
        return tags
    }

    fun value(): ByteArray {
        return value
    }
}