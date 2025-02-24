package br.org.serpro.did_agent.askar

class EncryptedBuffer(
    private val ciphertext: ByteArray,
    private val tag: ByteArray,
    private val nonce: ByteArray
){

    fun ciphertext(): ByteArray {
        return ciphertext
    }

    fun ciphertextTag(): ByteArray {
        return tag
    }

    fun nonce(): ByteArray {
        return nonce
    }

    fun tag(): ByteArray {
        return tag
    }
}