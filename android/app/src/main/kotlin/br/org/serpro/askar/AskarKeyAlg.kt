package br.org.serpro.did_agent.askar

enum class AskarKeyAlg(val value: String) {
    AES_A128_GCM("a128gcm"),
    AES_A256_GCM("a256gcm"),
    AES_A128_CBC_HS256("a128cbchs256"),
    AES_A256_CBC_HS512("a256cbchs512"),
    AES_A128_KW("a128kw"),
    AES_A256_KW("a256kw"),
    BLS12381_G1("bls12381g1"),
    BLS12381_G2("bls12381g2"),
    BLS12381_G1_G2("bls12381g1g2"),
    CHACHA20_C20P("c20p"),
    CHACHA20_XC20P("xc20p"),
    ED25519("ed25519"),
    X25519("x25519"),
    EC_SECP256K1("k256"),
    EC_SECP256R1("p256"),
    EC_SECP384R1("p384");

    companion object {
        fun fromString(algorithm: String): AskarKeyAlg {
            return values().firstOrNull { it.value == algorithm }
                ?: throw IllegalArgumentException("Invalid KeyAlgorithm: $algorithm")
        }
    }
}