package br.org.serpro.did_agent.askar

enum class ErrorCode(val code: Int) {
    SUCCESS(0),
    BACKEND(1),
    BUSY(2),
    DUPLICATE(3),
    ENCRYPTION(4),
    INPUT(5),
    NOT_FOUND(6),
    UNEXPECTED(7),
    UNSUPPORTED(8),
    CUSTOM(100);

    companion object {
        fun fromInt(code: Int): ErrorCode {
            return values().firstOrNull { it.code == code }
                ?: throw IllegalArgumentException("Invalid error code: $code")
        }
    }

    fun isSuccess(): Boolean {
        return this == SUCCESS
    }

    fun throwOnError() {
        if (!isSuccess()) {
            throw ErrorCodeException(fromInt(code))
        }
    }
}

class ErrorCodeException(val errorCode: ErrorCode) : Exception("Error code: ${errorCode.code}")