package br.org.serpro.did_agent.askar

import br.org.serpro.did_agent.askar.ErrorCodeException

class LocalKeyFactory {

    @Throws(ErrorCodeException::class)
    fun fromJwk(jwk: String): AskarLocalKey {
        // Implement the logic to create a key from JWK
        return AskarLocalKey()
    }

    @Throws(ErrorCodeException::class)
    fun fromJwkSlice(jwk: ByteArray): AskarLocalKey {
        // Implement the logic to create a key from JWK slice
        return AskarLocalKey()
    }

    @Throws(ErrorCodeException::class)
    fun fromPublicBytes(alg: AskarKeyAlg, bytes: ByteArray): AskarLocalKey {
        // Implement the logic to create a key from public bytes
        return AskarLocalKey()
    }

    @Throws(ErrorCodeException::class)
    fun fromSecretBytes(alg: AskarKeyAlg, bytes: ByteArray): AskarLocalKey {
        // Implement the logic to create a key from secret bytes
        return AskarLocalKey()
    }

    // @Throws(ErrorCodeException::class)
    // fun fromSeed(alg: AskarKeyAlg, seed: ByteArray, method: SeedMethod?): AskarLocalKey {
    //     // Implement the logic to create a key from seed
    //     return AskarLocalKey()
    // }

    @Throws(ErrorCodeException::class)
    fun generate(alg: AskarKeyAlg, ephemeral: Boolean): AskarLocalKey {
        // Implement the logic to generate a key
        return AskarLocalKey()
    }
}