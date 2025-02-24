package br.org.serpro.did_agent.askar

import br.org.serpro.did_agent.askar.ErrorCodeException

class AskarCrypto  {
    @Throws(ErrorCodeException::class)
    fun boxOpen(receiverKey: AskarLocalKey, senderKey: AskarLocalKey, message: ByteArray, nonce: ByteArray): ByteArray {
        // Implement the logic to open the box
        return ByteArray(0)
    }

    @Throws(ErrorCodeException::class)
    fun boxSeal(receiverKey: AskarLocalKey, message: ByteArray): ByteArray {
        // Implement the logic to seal the box
        return ByteArray(0)
    }

    @Throws(ErrorCodeException::class)
    fun boxSealOpen(receiverKey: AskarLocalKey, ciphertext: ByteArray): ByteArray {
        // Implement the logic to open the sealed box
        return ByteArray(0)
    }

    @Throws(ErrorCodeException::class)
    fun cryptoBox(receiverKey: AskarLocalKey, senderKey: AskarLocalKey, message: ByteArray, nonce: ByteArray): ByteArray {
        // Implement the logic to perform crypto box operation
        return ByteArray(0)
    }

    @Throws(ErrorCodeException::class)
    fun randomNonce(): ByteArray {
        // Implement the logic to generate a random nonce
        return ByteArray(0)
    }
}