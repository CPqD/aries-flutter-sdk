@file:Suppress("NAME_SHADOWING")

package askar_uniffi

import okio.Buffer
import kotlin.coroutines.cancellation.CancellationException
import kotlin.coroutines.resume
import kotlinx.atomicfu.*
import kotlinx.coroutines.CancellableContinuation
import kotlinx.coroutines.suspendCancellableCoroutine

// TODO remove suppress when https://youtrack.jetbrains.com/issue/KT-29819/New-rules-for-expect-actual-declarations-in-MPP is solved
@Suppress("NO_ACTUAL_FOR_EXPECT")
internal expect class Pointer

internal expect fun kotlin.Long.toPointer(): Pointer

internal expect fun Pointer.toLong(): kotlin.Long

// TODO remove suppress when https://youtrack.jetbrains.com/issue/KT-29819/New-rules-for-expect-actual-declarations-in-MPP is solved
@Suppress("NO_ACTUAL_FOR_EXPECT")
internal expect class UBytePointer

internal expect fun UBytePointer.asSource(len: kotlin.Long): NoCopySource

// TODO remove suppress when https://youtrack.jetbrains.com/issue/KT-29819/New-rules-for-expect-actual-declarations-in-MPP is solved
@Suppress("NO_ACTUAL_FOR_EXPECT")
internal expect class RustBuffer

// TODO remove suppress when https://youtrack.jetbrains.com/issue/KT-29819/New-rules-for-expect-actual-declarations-in-MPP is solved
@Suppress("NO_ACTUAL_FOR_EXPECT")
internal expect class RustBufferByReference

internal expect fun RustBuffer.asSource(): NoCopySource

internal expect val RustBuffer.dataSize: kotlin.Int

internal expect fun RustBuffer.free()

internal expect fun allocRustBuffer(buffer: Buffer): RustBuffer

internal expect fun RustBufferByReference.setValue(value: RustBuffer)

internal expect fun emptyRustBuffer(): RustBuffer

internal interface NoCopySource {
    fun exhausted(): kotlin.Boolean
    fun readByte(): kotlin.Byte
    fun readInt(): kotlin.Int
    fun readLong(): kotlin.Long
    fun readShort(): kotlin.Short
    fun readByteArray(): ByteArray
    fun readByteArray(len: kotlin.Long): ByteArray
}

// This is a helper for safely passing byte references into the rust code.
// It's not actually used at the moment, because there aren't many things that you
// can take a direct pointer to in the JVM, and if we're going to copy something
// then we might as well copy it into a `RustBuffer`. But it's here for API
// completeness.

// TODO remove suppress when https://youtrack.jetbrains.com/issue/KT-29819/New-rules-for-expect-actual-declarations-in-MPP is solved
@Suppress("NO_ACTUAL_FOR_EXPECT")
internal expect class ForeignBytes
// The FfiConverter interface handles converter types to and from the FFI
//
// All implementing objects should be public to support external types.  When a
// type is external we need to import it's FfiConverter.
internal interface FfiConverter<KotlinType, FfiType> {
    // Convert an FFI type to a Kotlin type
    fun lift(value: FfiType): KotlinType

    // Convert an Kotlin type to an FFI type
    fun lower(value: KotlinType): FfiType

    // Read a Kotlin type from a `NoCopySource`
    fun read(buf: NoCopySource): KotlinType

    // Calculate bytes to allocate when creating a `RustBuffer`
    //
    // This must return at least as many bytes as the write() function will
    // write. It can return more bytes than needed, for example when writing
    // Strings we can't know the exact bytes needed until we the UTF-8
    // encoding, so we pessimistically allocate the largest size possible (3
    // bytes per codepoint).  Allocating extra bytes is not really a big deal
    // because the `RustBuffer` is short-lived.
    fun allocationSize(value: KotlinType): Int

    // Write a Kotlin type to a `ByteBuffer`
    fun write(value: KotlinType, buf: Buffer)

    // Lower a value into a `RustBuffer`
    //
    // This method lowers a value into a `RustBuffer` rather than the normal
    // FfiType.  It's used by the callback interface code.  Callback interface
    // returns are always serialized into a `RustBuffer` regardless of their
    // normal FFI type.
    fun lowerIntoRustBuffer(value: KotlinType): RustBuffer {
        val buffer = Buffer().apply { write(value, buffer) }
        return allocRustBuffer(buffer)
    }

    // Lift a value from a `RustBuffer`.
    //
    // This here mostly because of the symmetry with `lowerIntoRustBuffer()`.
    // It's currently only used by the `FfiConverterRustBuffer` class below.
    fun liftFromRustBuffer(rbuf: RustBuffer): KotlinType {
        val byteBuf = rbuf.asSource()
        try {
            val item = read(byteBuf)
            if (!byteBuf.exhausted()) {
                throw RuntimeException("junk remaining in buffer after lifting, something is very wrong!!")
            }
            return item
        } finally {
            rbuf.free()
        }
    }
}

// FfiConverter that uses `RustBuffer` as the FfiType
internal interface FfiConverterRustBuffer<KotlinType> : FfiConverter<KotlinType, RustBuffer> {
    override fun lift(value: RustBuffer) = liftFromRustBuffer(value)
    override fun lower(value: KotlinType) = lowerIntoRustBuffer(value)
}
// A handful of classes and functions to support the generated data structures.
// This would be a good candidate for isolating in its own ffi-support lib.
// Error runtime.
// TODO remove suppress when https://youtrack.jetbrains.com/issue/KT-29819/New-rules-for-expect-actual-declarations-in-MPP is solved
@Suppress("NO_ACTUAL_FOR_EXPECT")
internal expect class RustCallStatus
internal expect val RustCallStatus.statusCode: kotlin.Byte
internal expect val RustCallStatus.errorBuffer: RustBuffer

internal expect fun <T> withRustCallStatus(block: (RustCallStatus) -> T): T

// TODO remove suppress when https://youtrack.jetbrains.com/issue/KT-29819/New-rules-for-expect-actual-declarations-in-MPP is solved
@Suppress("NO_ACTUAL_FOR_EXPECT")
internal expect class RustCallStatusByValue

private const val RUST_CALL_STATUS_SUCCESS: kotlin.Byte = 0
private const val RUST_CALL_STATUS_ERROR: kotlin.Byte = 1
private const val RUST_CALL_STATUS_PANIC: kotlin.Byte = 2

internal fun RustCallStatus.isSuccess(): kotlin.Boolean {
    return statusCode == RUST_CALL_STATUS_SUCCESS
}

internal fun RustCallStatus.isError(): kotlin.Boolean {
    return statusCode == RUST_CALL_STATUS_ERROR
}

internal fun RustCallStatus.isPanic(): kotlin.Boolean {
    return statusCode == RUST_CALL_STATUS_PANIC
}

class InternalException(message: kotlin.String) : Exception(message)

// Each top-level error class has a companion object that can lift the error from the call status's rust buffer
internal interface CallStatusErrorHandler<E> {
    fun lift(errorBuffer: RustBuffer): E;
}

// Helpers for calling Rust
// In practice we usually need to be synchronized to call this safely, so it doesn't
// synchronize itself

// Call a rust function that returns a Result<>.  Pass in the Error class companion that corresponds to the Err
internal inline fun <U, E : Exception> rustCallWithError(
    errorHandler: CallStatusErrorHandler<E>,
    crossinline callback: (RustCallStatus) -> U,
): U =
    withRustCallStatus { status: RustCallStatus ->
        val return_value = callback(status)
        checkCallStatus(errorHandler, status)
        return_value
    }

// Check RustCallStatus and throw an error if the call wasn't successful
internal fun <E : Exception> checkCallStatus(errorHandler: CallStatusErrorHandler<E>, status: RustCallStatus) {
    if (status.isSuccess()) {
        return
    } else if (status.isError()) {
        throw errorHandler.lift(status.errorBuffer)
    } else if (status.isPanic()) {
        // when the rust code sees a panic, it tries to construct a rustbuffer
        // with the message.  but if that code panics, then it just sends back
        // an empty buffer.
        if (status.errorBuffer.dataSize > 0) {
            // TODO avoid additional copy
            throw InternalException(FfiConverterString.lift(status.errorBuffer))
        } else {
            throw InternalException("Rust panic")
        }
    } else {
        throw InternalException("Unknown rust call status: $status.code")
    }
}

// CallStatusErrorHandler implementation for times when we don't expect a CALL_ERROR
internal object NullCallStatusErrorHandler : CallStatusErrorHandler<InternalException> {
    override fun lift(errorBuffer: RustBuffer): InternalException {
        errorBuffer.free()
        return InternalException("Unexpected CALL_ERROR")
    }
}

// Call a rust function that returns a plain value
internal inline fun <U> rustCall(crossinline callback: (RustCallStatus) -> U): U {
    return rustCallWithError(NullCallStatusErrorHandler, callback);
}

// Map handles to objects
//
// This is used when the Rust code expects an opaque pointer to represent some foreign object.
// Normally we would pass a pointer to the object, but JNA doesn't support getting a pointer from an
// object reference , nor does it support leaking a reference to Rust.
//
// Instead, this class maps ULong values to objects so that we can pass a pointer-sized type to
// Rust when it needs an opaque pointer.
//
// TODO: refactor callbacks to use this class
internal expect class UniFfiHandleMap<T : Any>() {

    val size: kotlin.Int

    fun insert(obj: T): kotlin.ULong

    fun get(handle: kotlin.ULong): T?

    fun remove(handle: kotlin.ULong): T?
}

// Contains loading, initialization code,
// and the FFI Function declarations.
internal expect object UniFFILib {
    fun uniffi_askar_uniffi_fn_free_askarcrypto(`ptr`: Pointer,_uniffi_out_err: RustCallStatus, ): Unit
    fun uniffi_askar_uniffi_fn_constructor_askarcrypto_new(_uniffi_out_err: RustCallStatus, ): Pointer
    fun uniffi_askar_uniffi_fn_method_askarcrypto_box_open(`ptr`: Pointer,`receiverKey`: Pointer,`senderKey`: Pointer,`message`: RustBuffer,`nonce`: RustBuffer,_uniffi_out_err: RustCallStatus, ): RustBuffer
    fun uniffi_askar_uniffi_fn_method_askarcrypto_box_seal(`ptr`: Pointer,`receiverKey`: Pointer,`message`: RustBuffer,_uniffi_out_err: RustCallStatus, ): RustBuffer
    fun uniffi_askar_uniffi_fn_method_askarcrypto_box_seal_open(`ptr`: Pointer,`receiverKey`: Pointer,`ciphertext`: RustBuffer,_uniffi_out_err: RustCallStatus, ): RustBuffer
    fun uniffi_askar_uniffi_fn_method_askarcrypto_crypto_box(`ptr`: Pointer,`receiverKey`: Pointer,`senderKey`: Pointer,`message`: RustBuffer,`nonce`: RustBuffer,_uniffi_out_err: RustCallStatus, ): RustBuffer
    fun uniffi_askar_uniffi_fn_method_askarcrypto_random_nonce(`ptr`: Pointer,_uniffi_out_err: RustCallStatus, ): RustBuffer
    fun uniffi_askar_uniffi_fn_free_askarecdh1pu(`ptr`: Pointer,_uniffi_out_err: RustCallStatus, ): Unit
    fun uniffi_askar_uniffi_fn_constructor_askarecdh1pu_new(`algId`: RustBuffer,`apu`: RustBuffer,`apv`: RustBuffer,_uniffi_out_err: RustCallStatus, ): Pointer
    fun uniffi_askar_uniffi_fn_method_askarecdh1pu_decrypt_direct(`ptr`: Pointer,`encAlg`: RustBuffer,`ephemeralKey`: Pointer,`senderKey`: Pointer,`receiverKey`: Pointer,`ciphertext`: RustBuffer,`tag`: RustBuffer,`nonce`: RustBuffer,`aad`: RustBuffer,_uniffi_out_err: RustCallStatus, ): RustBuffer
    fun uniffi_askar_uniffi_fn_method_askarecdh1pu_derive_key(`ptr`: Pointer,`encAlg`: RustBuffer,`ephemeralKey`: Pointer,`senderKey`: Pointer,`receiverKey`: Pointer,`ccTag`: RustBuffer,`receive`: Byte,_uniffi_out_err: RustCallStatus, ): Pointer
    fun uniffi_askar_uniffi_fn_method_askarecdh1pu_encrypt_direct(`ptr`: Pointer,`encAlg`: RustBuffer,`ephemeralKey`: Pointer,`senderKey`: Pointer,`receiverKey`: Pointer,`message`: RustBuffer,`nonce`: RustBuffer,`aad`: RustBuffer,_uniffi_out_err: RustCallStatus, ): Pointer
    fun uniffi_askar_uniffi_fn_method_askarecdh1pu_receiver_unwrap_key(`ptr`: Pointer,`wrapAlg`: RustBuffer,`encAlg`: RustBuffer,`ephemeralKey`: Pointer,`senderKey`: Pointer,`receiverKey`: Pointer,`ciphertext`: RustBuffer,`ccTag`: RustBuffer,`nonce`: RustBuffer,`tag`: RustBuffer,_uniffi_out_err: RustCallStatus, ): Pointer
    fun uniffi_askar_uniffi_fn_method_askarecdh1pu_sender_wrap_key(`ptr`: Pointer,`wrapAlg`: RustBuffer,`ephemeralKey`: Pointer,`senderKey`: Pointer,`receiverKey`: Pointer,`cek`: Pointer,`ccTag`: RustBuffer,_uniffi_out_err: RustCallStatus, ): Pointer
    fun uniffi_askar_uniffi_fn_free_askarecdhes(`ptr`: Pointer,_uniffi_out_err: RustCallStatus, ): Unit
    fun uniffi_askar_uniffi_fn_constructor_askarecdhes_new(`algId`: RustBuffer,`apu`: RustBuffer,`apv`: RustBuffer,_uniffi_out_err: RustCallStatus, ): Pointer
    fun uniffi_askar_uniffi_fn_method_askarecdhes_decrypt_direct(`ptr`: Pointer,`encAlg`: RustBuffer,`ephemeralKey`: Pointer,`receiverKey`: Pointer,`ciphertext`: RustBuffer,`tag`: RustBuffer,`nonce`: RustBuffer,`aad`: RustBuffer,_uniffi_out_err: RustCallStatus, ): RustBuffer
    fun uniffi_askar_uniffi_fn_method_askarecdhes_derive_key(`ptr`: Pointer,`encAlg`: RustBuffer,`ephemeralKey`: Pointer,`receiverKey`: Pointer,`receive`: Byte,_uniffi_out_err: RustCallStatus, ): Pointer
    fun uniffi_askar_uniffi_fn_method_askarecdhes_encrypt_direct(`ptr`: Pointer,`encAlg`: RustBuffer,`ephemeralKey`: Pointer,`receiverKey`: Pointer,`message`: RustBuffer,`nonce`: RustBuffer,`aad`: RustBuffer,_uniffi_out_err: RustCallStatus, ): Pointer
    fun uniffi_askar_uniffi_fn_method_askarecdhes_receiver_unwrap_key(`ptr`: Pointer,`wrapAlg`: RustBuffer,`encAlg`: RustBuffer,`ephemeralKey`: Pointer,`receiverKey`: Pointer,`ciphertext`: RustBuffer,`nonce`: RustBuffer,`tag`: RustBuffer,_uniffi_out_err: RustCallStatus, ): Pointer
    fun uniffi_askar_uniffi_fn_method_askarecdhes_sender_wrap_key(`ptr`: Pointer,`wrapAlg`: RustBuffer,`ephemeralKey`: Pointer,`receiverKey`: Pointer,`cek`: Pointer,_uniffi_out_err: RustCallStatus, ): Pointer
    fun uniffi_askar_uniffi_fn_free_askarentry(`ptr`: Pointer,_uniffi_out_err: RustCallStatus, ): Unit
    fun uniffi_askar_uniffi_fn_method_askarentry_category(`ptr`: Pointer,_uniffi_out_err: RustCallStatus, ): RustBuffer
    fun uniffi_askar_uniffi_fn_method_askarentry_name(`ptr`: Pointer,_uniffi_out_err: RustCallStatus, ): RustBuffer
    fun uniffi_askar_uniffi_fn_method_askarentry_tags(`ptr`: Pointer,_uniffi_out_err: RustCallStatus, ): RustBuffer
    fun uniffi_askar_uniffi_fn_method_askarentry_value(`ptr`: Pointer,_uniffi_out_err: RustCallStatus, ): RustBuffer
    fun uniffi_askar_uniffi_fn_free_askarkeyentry(`ptr`: Pointer,_uniffi_out_err: RustCallStatus, ): Unit
    fun uniffi_askar_uniffi_fn_method_askarkeyentry_algorithm(`ptr`: Pointer,_uniffi_out_err: RustCallStatus, ): RustBuffer
    fun uniffi_askar_uniffi_fn_method_askarkeyentry_is_local(`ptr`: Pointer,_uniffi_out_err: RustCallStatus, ): Byte
    fun uniffi_askar_uniffi_fn_method_askarkeyentry_load_local_key(`ptr`: Pointer,_uniffi_out_err: RustCallStatus, ): Pointer
    fun uniffi_askar_uniffi_fn_method_askarkeyentry_metadata(`ptr`: Pointer,_uniffi_out_err: RustCallStatus, ): RustBuffer
    fun uniffi_askar_uniffi_fn_method_askarkeyentry_name(`ptr`: Pointer,_uniffi_out_err: RustCallStatus, ): RustBuffer
    fun uniffi_askar_uniffi_fn_method_askarkeyentry_tags(`ptr`: Pointer,_uniffi_out_err: RustCallStatus, ): RustBuffer
    fun uniffi_askar_uniffi_fn_free_askarlocalkey(`ptr`: Pointer,_uniffi_out_err: RustCallStatus, ): Unit
    fun uniffi_askar_uniffi_fn_method_askarlocalkey_aead_decrypt(`ptr`: Pointer,`ciphertext`: RustBuffer,`tag`: RustBuffer,`nonce`: RustBuffer,`aad`: RustBuffer,_uniffi_out_err: RustCallStatus, ): RustBuffer
    fun uniffi_askar_uniffi_fn_method_askarlocalkey_aead_encrypt(`ptr`: Pointer,`message`: RustBuffer,`nonce`: RustBuffer,`aad`: RustBuffer,_uniffi_out_err: RustCallStatus, ): Pointer
    fun uniffi_askar_uniffi_fn_method_askarlocalkey_aead_padding(`ptr`: Pointer,`msgLen`: Int,_uniffi_out_err: RustCallStatus, ): Int
    fun uniffi_askar_uniffi_fn_method_askarlocalkey_aead_params(`ptr`: Pointer,_uniffi_out_err: RustCallStatus, ): RustBuffer
    fun uniffi_askar_uniffi_fn_method_askarlocalkey_aead_random_nonce(`ptr`: Pointer,_uniffi_out_err: RustCallStatus, ): RustBuffer
    fun uniffi_askar_uniffi_fn_method_askarlocalkey_algorithm(`ptr`: Pointer,_uniffi_out_err: RustCallStatus, ): RustBuffer
    fun uniffi_askar_uniffi_fn_method_askarlocalkey_convert_key(`ptr`: Pointer,`alg`: RustBuffer,_uniffi_out_err: RustCallStatus, ): Pointer
    fun uniffi_askar_uniffi_fn_method_askarlocalkey_sign_message(`ptr`: Pointer,`message`: RustBuffer,`sigType`: RustBuffer,_uniffi_out_err: RustCallStatus, ): RustBuffer
    fun uniffi_askar_uniffi_fn_method_askarlocalkey_to_jwk_public(`ptr`: Pointer,`alg`: RustBuffer,_uniffi_out_err: RustCallStatus, ): RustBuffer
    fun uniffi_askar_uniffi_fn_method_askarlocalkey_to_jwk_secret(`ptr`: Pointer,_uniffi_out_err: RustCallStatus, ): RustBuffer
    fun uniffi_askar_uniffi_fn_method_askarlocalkey_to_jwk_thumbprint(`ptr`: Pointer,`alg`: RustBuffer,_uniffi_out_err: RustCallStatus, ): RustBuffer
    fun uniffi_askar_uniffi_fn_method_askarlocalkey_to_jwk_thumbprints(`ptr`: Pointer,_uniffi_out_err: RustCallStatus, ): RustBuffer
    fun uniffi_askar_uniffi_fn_method_askarlocalkey_to_key_exchange(`ptr`: Pointer,`alg`: RustBuffer,`pk`: Pointer,_uniffi_out_err: RustCallStatus, ): Pointer
    fun uniffi_askar_uniffi_fn_method_askarlocalkey_to_public_bytes(`ptr`: Pointer,_uniffi_out_err: RustCallStatus, ): RustBuffer
    fun uniffi_askar_uniffi_fn_method_askarlocalkey_to_secret_bytes(`ptr`: Pointer,_uniffi_out_err: RustCallStatus, ): RustBuffer
    fun uniffi_askar_uniffi_fn_method_askarlocalkey_unwrap_key(`ptr`: Pointer,`alg`: RustBuffer,`ciphertext`: RustBuffer,`tag`: RustBuffer,`nonce`: RustBuffer,_uniffi_out_err: RustCallStatus, ): Pointer
    fun uniffi_askar_uniffi_fn_method_askarlocalkey_verify_signature(`ptr`: Pointer,`message`: RustBuffer,`signature`: RustBuffer,`sigType`: RustBuffer,_uniffi_out_err: RustCallStatus, ): Byte
    fun uniffi_askar_uniffi_fn_method_askarlocalkey_wrap_key(`ptr`: Pointer,`key`: Pointer,`nonce`: RustBuffer,_uniffi_out_err: RustCallStatus, ): Pointer
    fun uniffi_askar_uniffi_fn_free_askarscan(`ptr`: Pointer,_uniffi_out_err: RustCallStatus, ): Unit
    fun uniffi_askar_uniffi_fn_method_askarscan_fetch_all(`ptr`: Pointer,): Pointer
    fun uniffi_askar_uniffi_fn_method_askarscan_next(`ptr`: Pointer,): Pointer
    fun uniffi_askar_uniffi_fn_free_askarsession(`ptr`: Pointer,_uniffi_out_err: RustCallStatus, ): Unit
    fun uniffi_askar_uniffi_fn_method_askarsession_close(`ptr`: Pointer,): Pointer
    fun uniffi_askar_uniffi_fn_method_askarsession_count(`ptr`: Pointer,`category`: RustBuffer,`tagFilter`: RustBuffer,): Pointer
    fun uniffi_askar_uniffi_fn_method_askarsession_fetch(`ptr`: Pointer,`category`: RustBuffer,`name`: RustBuffer,`forUpdate`: Byte,): Pointer
    fun uniffi_askar_uniffi_fn_method_askarsession_fetch_all(`ptr`: Pointer,`category`: RustBuffer,`tagFilter`: RustBuffer,`limit`: RustBuffer,`forUpdate`: Byte,): Pointer
    fun uniffi_askar_uniffi_fn_method_askarsession_fetch_all_keys(`ptr`: Pointer,`algorithm`: RustBuffer,`thumbprint`: RustBuffer,`tagFilter`: RustBuffer,`limit`: RustBuffer,`forUpdate`: Byte,): Pointer
    fun uniffi_askar_uniffi_fn_method_askarsession_fetch_key(`ptr`: Pointer,`name`: RustBuffer,`forUpdate`: Byte,): Pointer
    fun uniffi_askar_uniffi_fn_method_askarsession_insert_key(`ptr`: Pointer,`name`: RustBuffer,`key`: Pointer,`metadata`: RustBuffer,`tags`: RustBuffer,`expiryMs`: RustBuffer,): Pointer
    fun uniffi_askar_uniffi_fn_method_askarsession_remove_all(`ptr`: Pointer,`category`: RustBuffer,`tagFilter`: RustBuffer,): Pointer
    fun uniffi_askar_uniffi_fn_method_askarsession_remove_key(`ptr`: Pointer,`name`: RustBuffer,): Pointer
    fun uniffi_askar_uniffi_fn_method_askarsession_update(`ptr`: Pointer,`operation`: RustBuffer,`category`: RustBuffer,`name`: RustBuffer,`value`: RustBuffer,`tags`: RustBuffer,`expiryMs`: RustBuffer,): Pointer
    fun uniffi_askar_uniffi_fn_method_askarsession_update_key(`ptr`: Pointer,`name`: RustBuffer,`metadata`: RustBuffer,`tags`: RustBuffer,`expiryMs`: RustBuffer,): Pointer
    fun uniffi_askar_uniffi_fn_free_askarstore(`ptr`: Pointer,_uniffi_out_err: RustCallStatus, ): Unit
    fun uniffi_askar_uniffi_fn_method_askarstore_close(`ptr`: Pointer,): Pointer
    fun uniffi_askar_uniffi_fn_method_askarstore_create_profile(`ptr`: Pointer,`profile`: RustBuffer,): Pointer
    fun uniffi_askar_uniffi_fn_method_askarstore_get_profile_name(`ptr`: Pointer,): Pointer
    fun uniffi_askar_uniffi_fn_method_askarstore_rekey(`ptr`: Pointer,`keyMethod`: RustBuffer,`passKey`: RustBuffer,): Pointer
    fun uniffi_askar_uniffi_fn_method_askarstore_remove_profile(`ptr`: Pointer,`profile`: RustBuffer,): Pointer
    fun uniffi_askar_uniffi_fn_method_askarstore_scan(`ptr`: Pointer,`profile`: RustBuffer,`category`: RustBuffer,`tagFilter`: RustBuffer,`offset`: RustBuffer,`limit`: RustBuffer,): Pointer
    fun uniffi_askar_uniffi_fn_method_askarstore_session(`ptr`: Pointer,`profile`: RustBuffer,): Pointer
    fun uniffi_askar_uniffi_fn_free_askarstoremanager(`ptr`: Pointer,_uniffi_out_err: RustCallStatus, ): Unit
    fun uniffi_askar_uniffi_fn_constructor_askarstoremanager_new(_uniffi_out_err: RustCallStatus, ): Pointer
    fun uniffi_askar_uniffi_fn_method_askarstoremanager_generate_raw_store_key(`ptr`: Pointer,`seed`: RustBuffer,_uniffi_out_err: RustCallStatus, ): RustBuffer
    fun uniffi_askar_uniffi_fn_method_askarstoremanager_open(`ptr`: Pointer,`specUri`: RustBuffer,`keyMethod`: RustBuffer,`passKey`: RustBuffer,`profile`: RustBuffer,): Pointer
    fun uniffi_askar_uniffi_fn_method_askarstoremanager_provision(`ptr`: Pointer,`specUri`: RustBuffer,`keyMethod`: RustBuffer,`passKey`: RustBuffer,`profile`: RustBuffer,`recreate`: Byte,): Pointer
    fun uniffi_askar_uniffi_fn_method_askarstoremanager_remove(`ptr`: Pointer,`specUri`: RustBuffer,): Pointer
    fun uniffi_askar_uniffi_fn_free_encryptedbuffer(`ptr`: Pointer,_uniffi_out_err: RustCallStatus, ): Unit
    fun uniffi_askar_uniffi_fn_method_encryptedbuffer_ciphertext(`ptr`: Pointer,_uniffi_out_err: RustCallStatus, ): RustBuffer
    fun uniffi_askar_uniffi_fn_method_encryptedbuffer_ciphertext_tag(`ptr`: Pointer,_uniffi_out_err: RustCallStatus, ): RustBuffer
    fun uniffi_askar_uniffi_fn_method_encryptedbuffer_nonce(`ptr`: Pointer,_uniffi_out_err: RustCallStatus, ): RustBuffer
    fun uniffi_askar_uniffi_fn_method_encryptedbuffer_tag(`ptr`: Pointer,_uniffi_out_err: RustCallStatus, ): RustBuffer
    fun uniffi_askar_uniffi_fn_free_localkeyfactory(`ptr`: Pointer,_uniffi_out_err: RustCallStatus, ): Unit
    fun uniffi_askar_uniffi_fn_constructor_localkeyfactory_new(_uniffi_out_err: RustCallStatus, ): Pointer
    fun uniffi_askar_uniffi_fn_method_localkeyfactory_from_jwk(`ptr`: Pointer,`jwk`: RustBuffer,_uniffi_out_err: RustCallStatus, ): Pointer
    fun uniffi_askar_uniffi_fn_method_localkeyfactory_from_jwk_slice(`ptr`: Pointer,`jwk`: RustBuffer,_uniffi_out_err: RustCallStatus, ): Pointer
    fun uniffi_askar_uniffi_fn_method_localkeyfactory_from_public_bytes(`ptr`: Pointer,`alg`: RustBuffer,`bytes`: RustBuffer,_uniffi_out_err: RustCallStatus, ): Pointer
    fun uniffi_askar_uniffi_fn_method_localkeyfactory_from_secret_bytes(`ptr`: Pointer,`alg`: RustBuffer,`bytes`: RustBuffer,_uniffi_out_err: RustCallStatus, ): Pointer
    fun uniffi_askar_uniffi_fn_method_localkeyfactory_from_seed(`ptr`: Pointer,`alg`: RustBuffer,`seed`: RustBuffer,`method`: RustBuffer,_uniffi_out_err: RustCallStatus, ): Pointer
    fun uniffi_askar_uniffi_fn_method_localkeyfactory_generate(`ptr`: Pointer,`alg`: RustBuffer,`ephemeral`: Byte,_uniffi_out_err: RustCallStatus, ): Pointer
    fun uniffi_askar_uniffi_fn_func_set_default_logger(_uniffi_out_err: RustCallStatus, ): Unit
    fun ffi_askar_uniffi_rustbuffer_alloc(`size`: Int,_uniffi_out_err: RustCallStatus, ): RustBuffer
    fun ffi_askar_uniffi_rustbuffer_from_bytes(`bytes`: ForeignBytes,_uniffi_out_err: RustCallStatus, ): RustBuffer
    fun ffi_askar_uniffi_rustbuffer_free(`buf`: RustBuffer,_uniffi_out_err: RustCallStatus, ): Unit
    fun ffi_askar_uniffi_rustbuffer_reserve(`buf`: RustBuffer,`additional`: Int,_uniffi_out_err: RustCallStatus, ): RustBuffer
    fun ffi_askar_uniffi_rust_future_continuation_callback_set(`callback`: UniFfiRustFutureContinuationCallbackType,): Unit
    fun ffi_askar_uniffi_rust_future_poll_u8(`handle`: Pointer,`uniffiCallback`: ULong,): Unit
    fun ffi_askar_uniffi_rust_future_cancel_u8(`handle`: Pointer,): Unit
    fun ffi_askar_uniffi_rust_future_free_u8(`handle`: Pointer,): Unit
    fun ffi_askar_uniffi_rust_future_complete_u8(`handle`: Pointer,_uniffi_out_err: RustCallStatus, ): UByte
    fun ffi_askar_uniffi_rust_future_poll_i8(`handle`: Pointer,`uniffiCallback`: ULong,): Unit
    fun ffi_askar_uniffi_rust_future_cancel_i8(`handle`: Pointer,): Unit
    fun ffi_askar_uniffi_rust_future_free_i8(`handle`: Pointer,): Unit
    fun ffi_askar_uniffi_rust_future_complete_i8(`handle`: Pointer,_uniffi_out_err: RustCallStatus, ): Byte
    fun ffi_askar_uniffi_rust_future_poll_u16(`handle`: Pointer,`uniffiCallback`: ULong,): Unit
    fun ffi_askar_uniffi_rust_future_cancel_u16(`handle`: Pointer,): Unit
    fun ffi_askar_uniffi_rust_future_free_u16(`handle`: Pointer,): Unit
    fun ffi_askar_uniffi_rust_future_complete_u16(`handle`: Pointer,_uniffi_out_err: RustCallStatus, ): UShort
    fun ffi_askar_uniffi_rust_future_poll_i16(`handle`: Pointer,`uniffiCallback`: ULong,): Unit
    fun ffi_askar_uniffi_rust_future_cancel_i16(`handle`: Pointer,): Unit
    fun ffi_askar_uniffi_rust_future_free_i16(`handle`: Pointer,): Unit
    fun ffi_askar_uniffi_rust_future_complete_i16(`handle`: Pointer,_uniffi_out_err: RustCallStatus, ): Short
    fun ffi_askar_uniffi_rust_future_poll_u32(`handle`: Pointer,`uniffiCallback`: ULong,): Unit
    fun ffi_askar_uniffi_rust_future_cancel_u32(`handle`: Pointer,): Unit
    fun ffi_askar_uniffi_rust_future_free_u32(`handle`: Pointer,): Unit
    fun ffi_askar_uniffi_rust_future_complete_u32(`handle`: Pointer,_uniffi_out_err: RustCallStatus, ): UInt
    fun ffi_askar_uniffi_rust_future_poll_i32(`handle`: Pointer,`uniffiCallback`: ULong,): Unit
    fun ffi_askar_uniffi_rust_future_cancel_i32(`handle`: Pointer,): Unit
    fun ffi_askar_uniffi_rust_future_free_i32(`handle`: Pointer,): Unit
    fun ffi_askar_uniffi_rust_future_complete_i32(`handle`: Pointer,_uniffi_out_err: RustCallStatus, ): Int
    fun ffi_askar_uniffi_rust_future_poll_u64(`handle`: Pointer,`uniffiCallback`: ULong,): Unit
    fun ffi_askar_uniffi_rust_future_cancel_u64(`handle`: Pointer,): Unit
    fun ffi_askar_uniffi_rust_future_free_u64(`handle`: Pointer,): Unit
    fun ffi_askar_uniffi_rust_future_complete_u64(`handle`: Pointer,_uniffi_out_err: RustCallStatus, ): ULong
    fun ffi_askar_uniffi_rust_future_poll_i64(`handle`: Pointer,`uniffiCallback`: ULong,): Unit
    fun ffi_askar_uniffi_rust_future_cancel_i64(`handle`: Pointer,): Unit
    fun ffi_askar_uniffi_rust_future_free_i64(`handle`: Pointer,): Unit
    fun ffi_askar_uniffi_rust_future_complete_i64(`handle`: Pointer,_uniffi_out_err: RustCallStatus, ): Long
    fun ffi_askar_uniffi_rust_future_poll_f32(`handle`: Pointer,`uniffiCallback`: ULong,): Unit
    fun ffi_askar_uniffi_rust_future_cancel_f32(`handle`: Pointer,): Unit
    fun ffi_askar_uniffi_rust_future_free_f32(`handle`: Pointer,): Unit
    fun ffi_askar_uniffi_rust_future_complete_f32(`handle`: Pointer,_uniffi_out_err: RustCallStatus, ): Float
    fun ffi_askar_uniffi_rust_future_poll_f64(`handle`: Pointer,`uniffiCallback`: ULong,): Unit
    fun ffi_askar_uniffi_rust_future_cancel_f64(`handle`: Pointer,): Unit
    fun ffi_askar_uniffi_rust_future_free_f64(`handle`: Pointer,): Unit
    fun ffi_askar_uniffi_rust_future_complete_f64(`handle`: Pointer,_uniffi_out_err: RustCallStatus, ): Double
    fun ffi_askar_uniffi_rust_future_poll_pointer(`handle`: Pointer,`uniffiCallback`: ULong,): Unit
    fun ffi_askar_uniffi_rust_future_cancel_pointer(`handle`: Pointer,): Unit
    fun ffi_askar_uniffi_rust_future_free_pointer(`handle`: Pointer,): Unit
    fun ffi_askar_uniffi_rust_future_complete_pointer(`handle`: Pointer,_uniffi_out_err: RustCallStatus, ): Pointer
    fun ffi_askar_uniffi_rust_future_poll_rust_buffer(`handle`: Pointer,`uniffiCallback`: ULong,): Unit
    fun ffi_askar_uniffi_rust_future_cancel_rust_buffer(`handle`: Pointer,): Unit
    fun ffi_askar_uniffi_rust_future_free_rust_buffer(`handle`: Pointer,): Unit
    fun ffi_askar_uniffi_rust_future_complete_rust_buffer(`handle`: Pointer,_uniffi_out_err: RustCallStatus, ): RustBuffer
    fun ffi_askar_uniffi_rust_future_poll_void(`handle`: Pointer,`uniffiCallback`: ULong,): Unit
    fun ffi_askar_uniffi_rust_future_cancel_void(`handle`: Pointer,): Unit
    fun ffi_askar_uniffi_rust_future_free_void(`handle`: Pointer,): Unit
    fun ffi_askar_uniffi_rust_future_complete_void(`handle`: Pointer,_uniffi_out_err: RustCallStatus, ): Unit
    fun uniffi_askar_uniffi_checksum_func_set_default_logger(): UShort
    fun uniffi_askar_uniffi_checksum_method_askarcrypto_box_open(): UShort
    fun uniffi_askar_uniffi_checksum_method_askarcrypto_box_seal(): UShort
    fun uniffi_askar_uniffi_checksum_method_askarcrypto_box_seal_open(): UShort
    fun uniffi_askar_uniffi_checksum_method_askarcrypto_crypto_box(): UShort
    fun uniffi_askar_uniffi_checksum_method_askarcrypto_random_nonce(): UShort
    fun uniffi_askar_uniffi_checksum_method_askarecdh1pu_decrypt_direct(): UShort
    fun uniffi_askar_uniffi_checksum_method_askarecdh1pu_derive_key(): UShort
    fun uniffi_askar_uniffi_checksum_method_askarecdh1pu_encrypt_direct(): UShort
    fun uniffi_askar_uniffi_checksum_method_askarecdh1pu_receiver_unwrap_key(): UShort
    fun uniffi_askar_uniffi_checksum_method_askarecdh1pu_sender_wrap_key(): UShort
    fun uniffi_askar_uniffi_checksum_method_askarecdhes_decrypt_direct(): UShort
    fun uniffi_askar_uniffi_checksum_method_askarecdhes_derive_key(): UShort
    fun uniffi_askar_uniffi_checksum_method_askarecdhes_encrypt_direct(): UShort
    fun uniffi_askar_uniffi_checksum_method_askarecdhes_receiver_unwrap_key(): UShort
    fun uniffi_askar_uniffi_checksum_method_askarecdhes_sender_wrap_key(): UShort
    fun uniffi_askar_uniffi_checksum_method_askarentry_category(): UShort
    fun uniffi_askar_uniffi_checksum_method_askarentry_name(): UShort
    fun uniffi_askar_uniffi_checksum_method_askarentry_tags(): UShort
    fun uniffi_askar_uniffi_checksum_method_askarentry_value(): UShort
    fun uniffi_askar_uniffi_checksum_method_askarkeyentry_algorithm(): UShort
    fun uniffi_askar_uniffi_checksum_method_askarkeyentry_is_local(): UShort
    fun uniffi_askar_uniffi_checksum_method_askarkeyentry_load_local_key(): UShort
    fun uniffi_askar_uniffi_checksum_method_askarkeyentry_metadata(): UShort
    fun uniffi_askar_uniffi_checksum_method_askarkeyentry_name(): UShort
    fun uniffi_askar_uniffi_checksum_method_askarkeyentry_tags(): UShort
    fun uniffi_askar_uniffi_checksum_method_askarlocalkey_aead_decrypt(): UShort
    fun uniffi_askar_uniffi_checksum_method_askarlocalkey_aead_encrypt(): UShort
    fun uniffi_askar_uniffi_checksum_method_askarlocalkey_aead_padding(): UShort
    fun uniffi_askar_uniffi_checksum_method_askarlocalkey_aead_params(): UShort
    fun uniffi_askar_uniffi_checksum_method_askarlocalkey_aead_random_nonce(): UShort
    fun uniffi_askar_uniffi_checksum_method_askarlocalkey_algorithm(): UShort
    fun uniffi_askar_uniffi_checksum_method_askarlocalkey_convert_key(): UShort
    fun uniffi_askar_uniffi_checksum_method_askarlocalkey_sign_message(): UShort
    fun uniffi_askar_uniffi_checksum_method_askarlocalkey_to_jwk_public(): UShort
    fun uniffi_askar_uniffi_checksum_method_askarlocalkey_to_jwk_secret(): UShort
    fun uniffi_askar_uniffi_checksum_method_askarlocalkey_to_jwk_thumbprint(): UShort
    fun uniffi_askar_uniffi_checksum_method_askarlocalkey_to_jwk_thumbprints(): UShort
    fun uniffi_askar_uniffi_checksum_method_askarlocalkey_to_key_exchange(): UShort
    fun uniffi_askar_uniffi_checksum_method_askarlocalkey_to_public_bytes(): UShort
    fun uniffi_askar_uniffi_checksum_method_askarlocalkey_to_secret_bytes(): UShort
    fun uniffi_askar_uniffi_checksum_method_askarlocalkey_unwrap_key(): UShort
    fun uniffi_askar_uniffi_checksum_method_askarlocalkey_verify_signature(): UShort
    fun uniffi_askar_uniffi_checksum_method_askarlocalkey_wrap_key(): UShort
    fun uniffi_askar_uniffi_checksum_method_askarscan_fetch_all(): UShort
    fun uniffi_askar_uniffi_checksum_method_askarscan_next(): UShort
    fun uniffi_askar_uniffi_checksum_method_askarsession_close(): UShort
    fun uniffi_askar_uniffi_checksum_method_askarsession_count(): UShort
    fun uniffi_askar_uniffi_checksum_method_askarsession_fetch(): UShort
    fun uniffi_askar_uniffi_checksum_method_askarsession_fetch_all(): UShort
    fun uniffi_askar_uniffi_checksum_method_askarsession_fetch_all_keys(): UShort
    fun uniffi_askar_uniffi_checksum_method_askarsession_fetch_key(): UShort
    fun uniffi_askar_uniffi_checksum_method_askarsession_insert_key(): UShort
    fun uniffi_askar_uniffi_checksum_method_askarsession_remove_all(): UShort
    fun uniffi_askar_uniffi_checksum_method_askarsession_remove_key(): UShort
    fun uniffi_askar_uniffi_checksum_method_askarsession_update(): UShort
    fun uniffi_askar_uniffi_checksum_method_askarsession_update_key(): UShort
    fun uniffi_askar_uniffi_checksum_method_askarstore_close(): UShort
    fun uniffi_askar_uniffi_checksum_method_askarstore_create_profile(): UShort
    fun uniffi_askar_uniffi_checksum_method_askarstore_get_profile_name(): UShort
    fun uniffi_askar_uniffi_checksum_method_askarstore_rekey(): UShort
    fun uniffi_askar_uniffi_checksum_method_askarstore_remove_profile(): UShort
    fun uniffi_askar_uniffi_checksum_method_askarstore_scan(): UShort
    fun uniffi_askar_uniffi_checksum_method_askarstore_session(): UShort
    fun uniffi_askar_uniffi_checksum_method_askarstoremanager_generate_raw_store_key(): UShort
    fun uniffi_askar_uniffi_checksum_method_askarstoremanager_open(): UShort
    fun uniffi_askar_uniffi_checksum_method_askarstoremanager_provision(): UShort
    fun uniffi_askar_uniffi_checksum_method_askarstoremanager_remove(): UShort
    fun uniffi_askar_uniffi_checksum_method_encryptedbuffer_ciphertext(): UShort
    fun uniffi_askar_uniffi_checksum_method_encryptedbuffer_ciphertext_tag(): UShort
    fun uniffi_askar_uniffi_checksum_method_encryptedbuffer_nonce(): UShort
    fun uniffi_askar_uniffi_checksum_method_encryptedbuffer_tag(): UShort
    fun uniffi_askar_uniffi_checksum_method_localkeyfactory_from_jwk(): UShort
    fun uniffi_askar_uniffi_checksum_method_localkeyfactory_from_jwk_slice(): UShort
    fun uniffi_askar_uniffi_checksum_method_localkeyfactory_from_public_bytes(): UShort
    fun uniffi_askar_uniffi_checksum_method_localkeyfactory_from_secret_bytes(): UShort
    fun uniffi_askar_uniffi_checksum_method_localkeyfactory_from_seed(): UShort
    fun uniffi_askar_uniffi_checksum_method_localkeyfactory_generate(): UShort
    fun uniffi_askar_uniffi_checksum_constructor_askarcrypto_new(): UShort
    fun uniffi_askar_uniffi_checksum_constructor_askarecdh1pu_new(): UShort
    fun uniffi_askar_uniffi_checksum_constructor_askarecdhes_new(): UShort
    fun uniffi_askar_uniffi_checksum_constructor_askarstoremanager_new(): UShort
    fun uniffi_askar_uniffi_checksum_constructor_localkeyfactory_new(): UShort
    fun ffi_askar_uniffi_uniffi_contract_version(): UInt
    
}

// Async support
// Async return type handlers

private const val UNIFFI_RUST_FUTURE_POLL_READY = 0.toShort()
private const val UNIFFI_RUST_FUTURE_POLL_MAYBE_READY = 1.toShort()

private val uniffiContinuationHandleMap = UniFfiHandleMap<CancellableContinuation<kotlin.Short>>()

internal fun resumeContinuation(continuationHandle: kotlin.ULong, pollResult: kotlin.Short) {
    uniffiContinuationHandleMap.remove(continuationHandle)?.resume(pollResult)
}

@Suppress("NO_ACTUAL_FOR_EXPECT")
internal expect class UniFfiRustFutureContinuationCallbackType

internal expect fun createUniFfiRustFutureContinuationCallback(): UniFfiRustFutureContinuationCallbackType

// FFI type for Rust future continuations
internal val uniffiRustFutureContinuationCallback = createUniFfiRustFutureContinuationCallback()

internal fun registerUniffiRustFutureContinuationCallback(lib: UniFFILib) {
    lib.ffi_askar_uniffi_rust_future_continuation_callback_set(uniffiRustFutureContinuationCallback)
}

internal suspend fun<T, F, E: Exception> uniffiRustCallAsync(
    rustFuture: Pointer,
    pollFunc: (Pointer, kotlin.ULong) -> Unit,
    completeFunc: (Pointer, RustCallStatus) -> F,
    freeFunc: (Pointer) -> Unit,
    liftFunc: (F) -> T,
    errorHandler: CallStatusErrorHandler<E>
): T {
    try {
        do {
            val pollResult = suspendCancellableCoroutine<kotlin.Short> { continuation ->
                pollFunc(
                    rustFuture,
                    uniffiContinuationHandleMap.insert(continuation)
                )
            }
        } while (pollResult != UNIFFI_RUST_FUTURE_POLL_READY);

        return liftFunc(
            rustCallWithError(errorHandler) { status -> completeFunc(rustFuture, status) }
        )
    } finally {
        freeFunc(rustFuture)
    }
}

// Public interface members begin here.


internal object FfiConverterInt : FfiConverter<kotlin.Int, kotlin.Int> {
    override fun lift(value: kotlin.Int): kotlin.Int {
        return value
    }

    override fun read(buf: NoCopySource): kotlin.Int {
        return buf.readInt()
    }

    override fun lower(value: kotlin.Int): kotlin.Int {
        return value
    }

    override fun allocationSize(value: kotlin.Int) = 4

    override fun write(value: kotlin.Int, buf: Buffer) {
        buf.writeInt(value)
    }
}

internal object FfiConverterLong : FfiConverter<kotlin.Long, kotlin.Long> {
    override fun lift(value: kotlin.Long): kotlin.Long {
        return value
    }

    override fun read(buf: NoCopySource): kotlin.Long {
        return buf.readLong()
    }

    override fun lower(value: kotlin.Long): kotlin.Long {
        return value
    }

    override fun allocationSize(value: kotlin.Long) = 8

    override fun write(value: kotlin.Long, buf: Buffer) {
        buf.writeLong(value)
    }
}

internal object FfiConverterBoolean : FfiConverter<kotlin.Boolean, kotlin.Byte> {
    override fun lift(value: kotlin.Byte): kotlin.Boolean {
        return value.toInt() != 0
    }

    override fun read(buf: NoCopySource): kotlin.Boolean {
        return lift(buf.readByte())
    }

    override fun lower(value: kotlin.Boolean): kotlin.Byte {
        return if (value) 1.toByte() else 0.toByte()
    }

    override fun allocationSize(value: kotlin.Boolean) = 1

    override fun write(value: kotlin.Boolean, buf: Buffer) {
        buf.writeByte(lower(value).toInt())
    }
}

internal object FfiConverterString : FfiConverter<kotlin.String, RustBuffer> {
    // Note: we don't inherit from FfiConverterRustBuffer, because we use a
    // special encoding when lowering/lifting.  We can use `RustBuffer.len` to
    // store our length and avoid writing it out to the buffer.
    override fun lift(value: RustBuffer): kotlin.String {
        try {
            val byteArr = value.asSource().readByteArray(value.dataSize.toLong())
            return byteArr.decodeToString()
        } finally {
            value.free()
        }
    }

    override fun read(buf: NoCopySource): kotlin.String {
        val len = buf.readInt()
        val byteArr = buf.readByteArray(len.toLong())
        return byteArr.decodeToString()
    }

    override fun lower(value: kotlin.String): RustBuffer {
        val buffer = Buffer().write(value.encodeToByteArray())
        return allocRustBuffer(buffer)
    }

    // We aren't sure exactly how many bytes our string will be once it's UTF-8
    // encoded.  Allocate 3 bytes per UTF-16 code unit which will always be
    // enough.
    override fun allocationSize(value: kotlin.String): kotlin.Int {
        val sizeForLength = 4
        val sizeForString = value.length * 3
        return sizeForLength + sizeForString
    }

    override fun write(value: kotlin.String, buf: Buffer) {
        val byteArr = value.encodeToByteArray()
        buf.writeInt(byteArr.size)
        buf.write(byteArr)
    }
}

internal object FfiConverterByteArray: FfiConverterRustBuffer<kotlin.ByteArray> {
    override fun read(buf: NoCopySource): kotlin.ByteArray {
        val len = buf.readInt()
        return buf.readByteArray(len.toLong())
    }
    override fun allocationSize(value: kotlin.ByteArray): Int {
        return 4 + value.size
    }
    override fun write(value: kotlin.ByteArray, buf: Buffer) {
        buf.writeInt(value.size)
        buf.write(value)
    }
}




// Interface implemented by anything that can contain an object reference.
//
// Such types expose a `destroy()` method that must be called to cleanly
// dispose of the contained objects. Failure to call this method may result
// in memory leaks.
//
// The easiest way to ensure this method is called is to use the `.use`
// helper method to execute a block and destroy the object at the end.
interface Disposable {
    fun destroy()

    companion object {
        fun destroy(vararg args: Any?) {
            args.filterIsInstance<Disposable>()
                .forEach(Disposable::destroy)
        }
    }
}

inline fun <T : Disposable?, R> T.use(block: (T) -> R) =
    try {
        block(this)
    } finally {
        try {
            // N.B. our implementation is on the nullable type `Disposable?`.
            this?.destroy()
        } catch (_: Throwable) {
            // swallow
        }
    }

// The base class for all UniFFI Object types.
//
// This class provides core operations for working with the Rust `Arc<T>` pointer to
// the live Rust struct on the other side of the FFI.
//
// There's some subtlety here, because we have to be careful not to operate on a Rust
// struct after it has been dropped, and because we must expose a public API for freeing
// the Kotlin wrapper object in lieu of reliable finalizers. The core requirements are:
//
//   * Each `FFIObject` instance holds an opaque pointer to the underlying Rust struct.
//     Method calls need to read this pointer from the object's state and pass it in to
//     the Rust FFI.
//
//   * When an `FFIObject` is no longer needed, its pointer should be passed to a
//     special destructor function provided by the Rust FFI, which will drop the
//     underlying Rust struct.
//
//   * Given an `FFIObject` instance, calling code is expected to call the special
//     `destroy` method in order to free it after use, either by calling it explicitly
//     or by using a higher-level helper like the `use` method. Failing to do so will
//     leak the underlying Rust struct.
//
//   * We can't assume that calling code will do the right thing, and must be prepared
//     to handle Kotlin method calls executing concurrently with or even after a call to
//     `destroy`, and to handle multiple (possibly concurrent!) calls to `destroy`.
//
//   * We must never allow Rust code to operate on the underlying Rust struct after
//     the destructor has been called, and must never call the destructor more than once.
//     Doing so may trigger memory unsafety.
//
// If we try to implement this with mutual exclusion on access to the pointer, there is the
// possibility of a race between a method call and a concurrent call to `destroy`:
//
//    * Thread A starts a method call, reads the value of the pointer, but is interrupted
//      before it can pass the pointer over the FFI to Rust.
//    * Thread B calls `destroy` and frees the underlying Rust struct.
//    * Thread A resumes, passing the already-read pointer value to Rust and triggering
//      a use-after-free.
//
// One possible solution would be to use a `ReadWriteLock`, with each method call taking
// a read lock (and thus allowed to run concurrently) and the special `destroy` method
// taking a write lock (and thus blocking on live method calls). However, we aim not to
// generate methods with any hidden blocking semantics, and a `destroy` method that might
// block if called incorrectly seems to meet that bar.
//
// So, we achieve our goals by giving each `FFIObject` an associated `AtomicLong` counter to track
// the number of in-flight method calls, and an `AtomicBoolean` flag to indicate whether `destroy`
// has been called. These are updated according to the following rules:
//
//    * The initial value of the counter is 1, indicating a live object with no in-flight calls.
//      The initial value for the flag is false.
//
//    * At the start of each method call, we atomically check the counter.
//      If it is 0 then the underlying Rust struct has already been destroyed and the call is aborted.
//      If it is nonzero them we atomically increment it by 1 and proceed with the method call.
//
//    * At the end of each method call, we atomically decrement and check the counter.
//      If it has reached zero then we destroy the underlying Rust struct.
//
//    * When `destroy` is called, we atomically flip the flag from false to true.
//      If the flag was already true we silently fail.
//      Otherwise we atomically decrement and check the counter.
//      If it has reached zero then we destroy the underlying Rust struct.
//
// Astute readers may observe that this all sounds very similar to the way that Rust's `Arc<T>` works,
// and indeed it is, with the addition of a flag to guard against multiple calls to `destroy`.
//
// The overall effect is that the underlying Rust struct is destroyed only when `destroy` has been
// called *and* all in-flight method calls have completed, avoiding violating any of the expectations
// of the underlying Rust code.
//
// In the future we may be able to replace some of this with automatic finalization logic, such as using
// the new "Cleaner" functionaility in Java 9. The above scheme has been designed to work even if `destroy` is
// invoked by garbage-collection machinery rather than by calling code (which by the way, it's apparently also
// possible for the JVM to finalize an object while there is an in-flight call to one of its methods [1],
// so there would still be some complexity here).
//
// Sigh...all of this for want of a robust finalization mechanism.
//
// [1] https://stackoverflow.com/questions/24376768/can-java-finalize-an-object-when-it-is-still-in-scope/24380219
//
abstract class FFIObject internal constructor(
    internal val pointer: Pointer
) : Disposable {

    private val wasDestroyed: kotlinx.atomicfu.AtomicBoolean = atomic(false)
    private val callCounter: kotlinx.atomicfu.AtomicLong = atomic(1L)

    open protected fun freeRustArcPtr() {
        // To be overridden in subclasses.
    }

    override fun destroy() {
        // Only allow a single call to this method.
        // TODO: maybe we should log a warning if called more than once?
        if (this.wasDestroyed.compareAndSet(expect = false, update = true)) {
            // This decrement always matches the initial count of 1 given at creation time.
            if (this.callCounter.decrementAndGet() == 0L) {
                this.freeRustArcPtr()
            }
        }
    }

    internal inline fun <R> callWithPointer(block: (ptr: Pointer) -> R): R {
        // Check and increment the call counter, to keep the object alive.
        // This needs a compare-and-set retry loop in case of concurrent updates.
        do {
            val c = this.callCounter.value
            if (c == 0L) {
                throw IllegalStateException("${this::class.simpleName} object has already been destroyed")
            }
            if (c == kotlin.Long.MAX_VALUE) {
                throw IllegalStateException("${this::class.simpleName} call counter would overflow")
            }
        } while (!this.callCounter.compareAndSet(expect = c, update = c + 1L))
        // Now we can safely do the method call without the pointer being freed concurrently.
                try {
            return block(this.pointer)
        } finally {
            // This decrement always matches the increment we performed above.
            if (this.callCounter.decrementAndGet() == 0L) {
                this.freeRustArcPtr()
            }
        }
    }
}

public interface AskarCryptoInterface {
    @Throws(ErrorCode::class)
    fun `boxOpen`(`receiverKey`: AskarLocalKey, `senderKey`: AskarLocalKey, `message`: kotlin.ByteArray, `nonce`: kotlin.ByteArray): kotlin.ByteArray

    @Throws(ErrorCode::class)
    fun `boxSeal`(`receiverKey`: AskarLocalKey, `message`: kotlin.ByteArray): kotlin.ByteArray

    @Throws(ErrorCode::class)
    fun `boxSealOpen`(`receiverKey`: AskarLocalKey, `ciphertext`: kotlin.ByteArray): kotlin.ByteArray

    @Throws(ErrorCode::class)
    fun `cryptoBox`(`receiverKey`: AskarLocalKey, `senderKey`: AskarLocalKey, `message`: kotlin.ByteArray, `nonce`: kotlin.ByteArray): kotlin.ByteArray

    @Throws(ErrorCode::class)
    fun `randomNonce`(): kotlin.ByteArray

    
    companion object
}

class AskarCrypto internal constructor(
    pointer: Pointer
) : FFIObject(pointer), AskarCryptoInterface {
    constructor() :
        this(
    rustCall { _status: RustCallStatus ->
    UniFFILib.uniffi_askar_uniffi_fn_constructor_askarcrypto_new(_status)
})

    /**
     * Disconnect the object from the underlying Rust object.
     *
     * It can be called more than once, but once called, interacting with the object
     * causes an `IllegalStateException`.
     *
     * Clients **must** call this method once done with the object, or cause a memory leak.
     */
    override protected fun freeRustArcPtr() {
        rustCall { status: RustCallStatus ->
            UniFFILib.uniffi_askar_uniffi_fn_free_askarcrypto(this.pointer, status)
        }
    }

    
    @Throws(ErrorCode::class)override fun `boxOpen`(`receiverKey`: AskarLocalKey, `senderKey`: AskarLocalKey, `message`: kotlin.ByteArray, `nonce`: kotlin.ByteArray): kotlin.ByteArray =
        callWithPointer {
    rustCallWithError(ErrorCode) { _status: RustCallStatus ->
    UniFFILib.uniffi_askar_uniffi_fn_method_askarcrypto_box_open(it, FfiConverterTypeAskarLocalKey.lower(`receiverKey`),FfiConverterTypeAskarLocalKey.lower(`senderKey`),FfiConverterByteArray.lower(`message`),FfiConverterByteArray.lower(`nonce`), _status)
}
        }.let {
            FfiConverterByteArray.lift(it)
        }
    
    
    @Throws(ErrorCode::class)override fun `boxSeal`(`receiverKey`: AskarLocalKey, `message`: kotlin.ByteArray): kotlin.ByteArray =
        callWithPointer {
    rustCallWithError(ErrorCode) { _status: RustCallStatus ->
    UniFFILib.uniffi_askar_uniffi_fn_method_askarcrypto_box_seal(it, FfiConverterTypeAskarLocalKey.lower(`receiverKey`),FfiConverterByteArray.lower(`message`), _status)
}
        }.let {
            FfiConverterByteArray.lift(it)
        }
    
    
    @Throws(ErrorCode::class)override fun `boxSealOpen`(`receiverKey`: AskarLocalKey, `ciphertext`: kotlin.ByteArray): kotlin.ByteArray =
        callWithPointer {
    rustCallWithError(ErrorCode) { _status: RustCallStatus ->
    UniFFILib.uniffi_askar_uniffi_fn_method_askarcrypto_box_seal_open(it, FfiConverterTypeAskarLocalKey.lower(`receiverKey`),FfiConverterByteArray.lower(`ciphertext`), _status)
}
        }.let {
            FfiConverterByteArray.lift(it)
        }
    
    
    @Throws(ErrorCode::class)override fun `cryptoBox`(`receiverKey`: AskarLocalKey, `senderKey`: AskarLocalKey, `message`: kotlin.ByteArray, `nonce`: kotlin.ByteArray): kotlin.ByteArray =
        callWithPointer {
    rustCallWithError(ErrorCode) { _status: RustCallStatus ->
    UniFFILib.uniffi_askar_uniffi_fn_method_askarcrypto_crypto_box(it, FfiConverterTypeAskarLocalKey.lower(`receiverKey`),FfiConverterTypeAskarLocalKey.lower(`senderKey`),FfiConverterByteArray.lower(`message`),FfiConverterByteArray.lower(`nonce`), _status)
}
        }.let {
            FfiConverterByteArray.lift(it)
        }
    
    
    @Throws(ErrorCode::class)override fun `randomNonce`(): kotlin.ByteArray =
        callWithPointer {
    rustCallWithError(ErrorCode) { _status: RustCallStatus ->
    UniFFILib.uniffi_askar_uniffi_fn_method_askarcrypto_random_nonce(it,  _status)
}
        }.let {
            FfiConverterByteArray.lift(it)
        }
    
    

    
    companion object
    
}

internal object FfiConverterTypeAskarCrypto: FfiConverter<AskarCrypto, Pointer> {
    override fun lower(value: AskarCrypto): Pointer = value.callWithPointer { it }

    override fun lift(value: Pointer): AskarCrypto {
        return AskarCrypto(value)
    }

    override fun read(buf: NoCopySource): AskarCrypto {
        // The Rust code always writes pointers as 8 bytes, and will
        // fail to compile if they don't fit.
        return lift(buf.readLong().toPointer())
    }

    override fun allocationSize(value: AskarCrypto) = 8

    override fun write(value: AskarCrypto, buf: Buffer) {
        // The Rust code always expects pointers written as 8 bytes,
        // and will fail to compile if they don't fit.
        buf.writeLong(lower(value).toLong())
    }
}




public interface AskarEcdh1PuInterface {
    @Throws(ErrorCode::class)
    fun `decryptDirect`(`encAlg`: AskarKeyAlg, `ephemeralKey`: AskarLocalKey, `senderKey`: AskarLocalKey, `receiverKey`: AskarLocalKey, `ciphertext`: kotlin.ByteArray, `tag`: kotlin.ByteArray?, `nonce`: kotlin.ByteArray, `aad`: kotlin.ByteArray?): kotlin.ByteArray

    @Throws(ErrorCode::class)
    fun `deriveKey`(`encAlg`: AskarKeyAlg, `ephemeralKey`: AskarLocalKey, `senderKey`: AskarLocalKey, `receiverKey`: AskarLocalKey, `ccTag`: kotlin.ByteArray, `receive`: kotlin.Boolean): AskarLocalKey

    @Throws(ErrorCode::class)
    fun `encryptDirect`(`encAlg`: AskarKeyAlg, `ephemeralKey`: AskarLocalKey, `senderKey`: AskarLocalKey, `receiverKey`: AskarLocalKey, `message`: kotlin.ByteArray, `nonce`: kotlin.ByteArray?, `aad`: kotlin.ByteArray?): EncryptedBuffer

    @Throws(ErrorCode::class)
    fun `receiverUnwrapKey`(`wrapAlg`: AskarKeyAlg, `encAlg`: AskarKeyAlg, `ephemeralKey`: AskarLocalKey, `senderKey`: AskarLocalKey, `receiverKey`: AskarLocalKey, `ciphertext`: kotlin.ByteArray, `ccTag`: kotlin.ByteArray, `nonce`: kotlin.ByteArray?, `tag`: kotlin.ByteArray?): AskarLocalKey

    @Throws(ErrorCode::class)
    fun `senderWrapKey`(`wrapAlg`: AskarKeyAlg, `ephemeralKey`: AskarLocalKey, `senderKey`: AskarLocalKey, `receiverKey`: AskarLocalKey, `cek`: AskarLocalKey, `ccTag`: kotlin.ByteArray): EncryptedBuffer

    
    companion object
}

class AskarEcdh1Pu internal constructor(
    pointer: Pointer
) : FFIObject(pointer), AskarEcdh1PuInterface {
    constructor(`algId`: kotlin.String, `apu`: kotlin.String, `apv`: kotlin.String) :
        this(
    rustCall { _status: RustCallStatus ->
    UniFFILib.uniffi_askar_uniffi_fn_constructor_askarecdh1pu_new(FfiConverterString.lower(`algId`),FfiConverterString.lower(`apu`),FfiConverterString.lower(`apv`),_status)
})

    /**
     * Disconnect the object from the underlying Rust object.
     *
     * It can be called more than once, but once called, interacting with the object
     * causes an `IllegalStateException`.
     *
     * Clients **must** call this method once done with the object, or cause a memory leak.
     */
    override protected fun freeRustArcPtr() {
        rustCall { status: RustCallStatus ->
            UniFFILib.uniffi_askar_uniffi_fn_free_askarecdh1pu(this.pointer, status)
        }
    }

    
    @Throws(ErrorCode::class)override fun `decryptDirect`(`encAlg`: AskarKeyAlg, `ephemeralKey`: AskarLocalKey, `senderKey`: AskarLocalKey, `receiverKey`: AskarLocalKey, `ciphertext`: kotlin.ByteArray, `tag`: kotlin.ByteArray?, `nonce`: kotlin.ByteArray, `aad`: kotlin.ByteArray?): kotlin.ByteArray =
        callWithPointer {
    rustCallWithError(ErrorCode) { _status: RustCallStatus ->
    UniFFILib.uniffi_askar_uniffi_fn_method_askarecdh1pu_decrypt_direct(it, FfiConverterTypeAskarKeyAlg.lower(`encAlg`),FfiConverterTypeAskarLocalKey.lower(`ephemeralKey`),FfiConverterTypeAskarLocalKey.lower(`senderKey`),FfiConverterTypeAskarLocalKey.lower(`receiverKey`),FfiConverterByteArray.lower(`ciphertext`),FfiConverterOptionalByteArray.lower(`tag`),FfiConverterByteArray.lower(`nonce`),FfiConverterOptionalByteArray.lower(`aad`), _status)
}
        }.let {
            FfiConverterByteArray.lift(it)
        }
    
    
    @Throws(ErrorCode::class)override fun `deriveKey`(`encAlg`: AskarKeyAlg, `ephemeralKey`: AskarLocalKey, `senderKey`: AskarLocalKey, `receiverKey`: AskarLocalKey, `ccTag`: kotlin.ByteArray, `receive`: kotlin.Boolean): AskarLocalKey =
        callWithPointer {
    rustCallWithError(ErrorCode) { _status: RustCallStatus ->
    UniFFILib.uniffi_askar_uniffi_fn_method_askarecdh1pu_derive_key(it, FfiConverterTypeAskarKeyAlg.lower(`encAlg`),FfiConverterTypeAskarLocalKey.lower(`ephemeralKey`),FfiConverterTypeAskarLocalKey.lower(`senderKey`),FfiConverterTypeAskarLocalKey.lower(`receiverKey`),FfiConverterByteArray.lower(`ccTag`),FfiConverterBoolean.lower(`receive`), _status)
}
        }.let {
            FfiConverterTypeAskarLocalKey.lift(it)
        }
    
    
    @Throws(ErrorCode::class)override fun `encryptDirect`(`encAlg`: AskarKeyAlg, `ephemeralKey`: AskarLocalKey, `senderKey`: AskarLocalKey, `receiverKey`: AskarLocalKey, `message`: kotlin.ByteArray, `nonce`: kotlin.ByteArray?, `aad`: kotlin.ByteArray?): EncryptedBuffer =
        callWithPointer {
    rustCallWithError(ErrorCode) { _status: RustCallStatus ->
    UniFFILib.uniffi_askar_uniffi_fn_method_askarecdh1pu_encrypt_direct(it, FfiConverterTypeAskarKeyAlg.lower(`encAlg`),FfiConverterTypeAskarLocalKey.lower(`ephemeralKey`),FfiConverterTypeAskarLocalKey.lower(`senderKey`),FfiConverterTypeAskarLocalKey.lower(`receiverKey`),FfiConverterByteArray.lower(`message`),FfiConverterOptionalByteArray.lower(`nonce`),FfiConverterOptionalByteArray.lower(`aad`), _status)
}
        }.let {
            FfiConverterTypeEncryptedBuffer.lift(it)
        }
    
    
    @Throws(ErrorCode::class)override fun `receiverUnwrapKey`(`wrapAlg`: AskarKeyAlg, `encAlg`: AskarKeyAlg, `ephemeralKey`: AskarLocalKey, `senderKey`: AskarLocalKey, `receiverKey`: AskarLocalKey, `ciphertext`: kotlin.ByteArray, `ccTag`: kotlin.ByteArray, `nonce`: kotlin.ByteArray?, `tag`: kotlin.ByteArray?): AskarLocalKey =
        callWithPointer {
    rustCallWithError(ErrorCode) { _status: RustCallStatus ->
    UniFFILib.uniffi_askar_uniffi_fn_method_askarecdh1pu_receiver_unwrap_key(it, FfiConverterTypeAskarKeyAlg.lower(`wrapAlg`),FfiConverterTypeAskarKeyAlg.lower(`encAlg`),FfiConverterTypeAskarLocalKey.lower(`ephemeralKey`),FfiConverterTypeAskarLocalKey.lower(`senderKey`),FfiConverterTypeAskarLocalKey.lower(`receiverKey`),FfiConverterByteArray.lower(`ciphertext`),FfiConverterByteArray.lower(`ccTag`),FfiConverterOptionalByteArray.lower(`nonce`),FfiConverterOptionalByteArray.lower(`tag`), _status)
}
        }.let {
            FfiConverterTypeAskarLocalKey.lift(it)
        }
    
    
    @Throws(ErrorCode::class)override fun `senderWrapKey`(`wrapAlg`: AskarKeyAlg, `ephemeralKey`: AskarLocalKey, `senderKey`: AskarLocalKey, `receiverKey`: AskarLocalKey, `cek`: AskarLocalKey, `ccTag`: kotlin.ByteArray): EncryptedBuffer =
        callWithPointer {
    rustCallWithError(ErrorCode) { _status: RustCallStatus ->
    UniFFILib.uniffi_askar_uniffi_fn_method_askarecdh1pu_sender_wrap_key(it, FfiConverterTypeAskarKeyAlg.lower(`wrapAlg`),FfiConverterTypeAskarLocalKey.lower(`ephemeralKey`),FfiConverterTypeAskarLocalKey.lower(`senderKey`),FfiConverterTypeAskarLocalKey.lower(`receiverKey`),FfiConverterTypeAskarLocalKey.lower(`cek`),FfiConverterByteArray.lower(`ccTag`), _status)
}
        }.let {
            FfiConverterTypeEncryptedBuffer.lift(it)
        }
    
    

    
    companion object
    
}

internal object FfiConverterTypeAskarEcdh1PU: FfiConverter<AskarEcdh1Pu, Pointer> {
    override fun lower(value: AskarEcdh1Pu): Pointer = value.callWithPointer { it }

    override fun lift(value: Pointer): AskarEcdh1Pu {
        return AskarEcdh1Pu(value)
    }

    override fun read(buf: NoCopySource): AskarEcdh1Pu {
        // The Rust code always writes pointers as 8 bytes, and will
        // fail to compile if they don't fit.
        return lift(buf.readLong().toPointer())
    }

    override fun allocationSize(value: AskarEcdh1Pu) = 8

    override fun write(value: AskarEcdh1Pu, buf: Buffer) {
        // The Rust code always expects pointers written as 8 bytes,
        // and will fail to compile if they don't fit.
        buf.writeLong(lower(value).toLong())
    }
}




public interface AskarEcdhEsInterface {
    @Throws(ErrorCode::class)
    fun `decryptDirect`(`encAlg`: AskarKeyAlg, `ephemeralKey`: AskarLocalKey, `receiverKey`: AskarLocalKey, `ciphertext`: kotlin.ByteArray, `tag`: kotlin.ByteArray?, `nonce`: kotlin.ByteArray, `aad`: kotlin.ByteArray?): kotlin.ByteArray

    @Throws(ErrorCode::class)
    fun `deriveKey`(`encAlg`: AskarKeyAlg, `ephemeralKey`: AskarLocalKey, `receiverKey`: AskarLocalKey, `receive`: kotlin.Boolean): AskarLocalKey

    @Throws(ErrorCode::class)
    fun `encryptDirect`(`encAlg`: AskarKeyAlg, `ephemeralKey`: AskarLocalKey, `receiverKey`: AskarLocalKey, `message`: kotlin.ByteArray, `nonce`: kotlin.ByteArray?, `aad`: kotlin.ByteArray?): EncryptedBuffer

    @Throws(ErrorCode::class)
    fun `receiverUnwrapKey`(`wrapAlg`: AskarKeyAlg, `encAlg`: AskarKeyAlg, `ephemeralKey`: AskarLocalKey, `receiverKey`: AskarLocalKey, `ciphertext`: kotlin.ByteArray, `nonce`: kotlin.ByteArray?, `tag`: kotlin.ByteArray?): AskarLocalKey

    @Throws(ErrorCode::class)
    fun `senderWrapKey`(`wrapAlg`: AskarKeyAlg, `ephemeralKey`: AskarLocalKey, `receiverKey`: AskarLocalKey, `cek`: AskarLocalKey): EncryptedBuffer

    
    companion object
}

class AskarEcdhEs internal constructor(
    pointer: Pointer
) : FFIObject(pointer), AskarEcdhEsInterface {
    constructor(`algId`: kotlin.String, `apu`: kotlin.String, `apv`: kotlin.String) :
        this(
    rustCall { _status: RustCallStatus ->
    UniFFILib.uniffi_askar_uniffi_fn_constructor_askarecdhes_new(FfiConverterString.lower(`algId`),FfiConverterString.lower(`apu`),FfiConverterString.lower(`apv`),_status)
})

    /**
     * Disconnect the object from the underlying Rust object.
     *
     * It can be called more than once, but once called, interacting with the object
     * causes an `IllegalStateException`.
     *
     * Clients **must** call this method once done with the object, or cause a memory leak.
     */
    override protected fun freeRustArcPtr() {
        rustCall { status: RustCallStatus ->
            UniFFILib.uniffi_askar_uniffi_fn_free_askarecdhes(this.pointer, status)
        }
    }

    
    @Throws(ErrorCode::class)override fun `decryptDirect`(`encAlg`: AskarKeyAlg, `ephemeralKey`: AskarLocalKey, `receiverKey`: AskarLocalKey, `ciphertext`: kotlin.ByteArray, `tag`: kotlin.ByteArray?, `nonce`: kotlin.ByteArray, `aad`: kotlin.ByteArray?): kotlin.ByteArray =
        callWithPointer {
    rustCallWithError(ErrorCode) { _status: RustCallStatus ->
    UniFFILib.uniffi_askar_uniffi_fn_method_askarecdhes_decrypt_direct(it, FfiConverterTypeAskarKeyAlg.lower(`encAlg`),FfiConverterTypeAskarLocalKey.lower(`ephemeralKey`),FfiConverterTypeAskarLocalKey.lower(`receiverKey`),FfiConverterByteArray.lower(`ciphertext`),FfiConverterOptionalByteArray.lower(`tag`),FfiConverterByteArray.lower(`nonce`),FfiConverterOptionalByteArray.lower(`aad`), _status)
}
        }.let {
            FfiConverterByteArray.lift(it)
        }
    
    
    @Throws(ErrorCode::class)override fun `deriveKey`(`encAlg`: AskarKeyAlg, `ephemeralKey`: AskarLocalKey, `receiverKey`: AskarLocalKey, `receive`: kotlin.Boolean): AskarLocalKey =
        callWithPointer {
    rustCallWithError(ErrorCode) { _status: RustCallStatus ->
    UniFFILib.uniffi_askar_uniffi_fn_method_askarecdhes_derive_key(it, FfiConverterTypeAskarKeyAlg.lower(`encAlg`),FfiConverterTypeAskarLocalKey.lower(`ephemeralKey`),FfiConverterTypeAskarLocalKey.lower(`receiverKey`),FfiConverterBoolean.lower(`receive`), _status)
}
        }.let {
            FfiConverterTypeAskarLocalKey.lift(it)
        }
    
    
    @Throws(ErrorCode::class)override fun `encryptDirect`(`encAlg`: AskarKeyAlg, `ephemeralKey`: AskarLocalKey, `receiverKey`: AskarLocalKey, `message`: kotlin.ByteArray, `nonce`: kotlin.ByteArray?, `aad`: kotlin.ByteArray?): EncryptedBuffer =
        callWithPointer {
    rustCallWithError(ErrorCode) { _status: RustCallStatus ->
    UniFFILib.uniffi_askar_uniffi_fn_method_askarecdhes_encrypt_direct(it, FfiConverterTypeAskarKeyAlg.lower(`encAlg`),FfiConverterTypeAskarLocalKey.lower(`ephemeralKey`),FfiConverterTypeAskarLocalKey.lower(`receiverKey`),FfiConverterByteArray.lower(`message`),FfiConverterOptionalByteArray.lower(`nonce`),FfiConverterOptionalByteArray.lower(`aad`), _status)
}
        }.let {
            FfiConverterTypeEncryptedBuffer.lift(it)
        }
    
    
    @Throws(ErrorCode::class)override fun `receiverUnwrapKey`(`wrapAlg`: AskarKeyAlg, `encAlg`: AskarKeyAlg, `ephemeralKey`: AskarLocalKey, `receiverKey`: AskarLocalKey, `ciphertext`: kotlin.ByteArray, `nonce`: kotlin.ByteArray?, `tag`: kotlin.ByteArray?): AskarLocalKey =
        callWithPointer {
    rustCallWithError(ErrorCode) { _status: RustCallStatus ->
    UniFFILib.uniffi_askar_uniffi_fn_method_askarecdhes_receiver_unwrap_key(it, FfiConverterTypeAskarKeyAlg.lower(`wrapAlg`),FfiConverterTypeAskarKeyAlg.lower(`encAlg`),FfiConverterTypeAskarLocalKey.lower(`ephemeralKey`),FfiConverterTypeAskarLocalKey.lower(`receiverKey`),FfiConverterByteArray.lower(`ciphertext`),FfiConverterOptionalByteArray.lower(`nonce`),FfiConverterOptionalByteArray.lower(`tag`), _status)
}
        }.let {
            FfiConverterTypeAskarLocalKey.lift(it)
        }
    
    
    @Throws(ErrorCode::class)override fun `senderWrapKey`(`wrapAlg`: AskarKeyAlg, `ephemeralKey`: AskarLocalKey, `receiverKey`: AskarLocalKey, `cek`: AskarLocalKey): EncryptedBuffer =
        callWithPointer {
    rustCallWithError(ErrorCode) { _status: RustCallStatus ->
    UniFFILib.uniffi_askar_uniffi_fn_method_askarecdhes_sender_wrap_key(it, FfiConverterTypeAskarKeyAlg.lower(`wrapAlg`),FfiConverterTypeAskarLocalKey.lower(`ephemeralKey`),FfiConverterTypeAskarLocalKey.lower(`receiverKey`),FfiConverterTypeAskarLocalKey.lower(`cek`), _status)
}
        }.let {
            FfiConverterTypeEncryptedBuffer.lift(it)
        }
    
    

    
    companion object
    
}

internal object FfiConverterTypeAskarEcdhEs: FfiConverter<AskarEcdhEs, Pointer> {
    override fun lower(value: AskarEcdhEs): Pointer = value.callWithPointer { it }

    override fun lift(value: Pointer): AskarEcdhEs {
        return AskarEcdhEs(value)
    }

    override fun read(buf: NoCopySource): AskarEcdhEs {
        // The Rust code always writes pointers as 8 bytes, and will
        // fail to compile if they don't fit.
        return lift(buf.readLong().toPointer())
    }

    override fun allocationSize(value: AskarEcdhEs) = 8

    override fun write(value: AskarEcdhEs, buf: Buffer) {
        // The Rust code always expects pointers written as 8 bytes,
        // and will fail to compile if they don't fit.
        buf.writeLong(lower(value).toLong())
    }
}




public interface AskarEntryInterface {
    
    fun `category`(): kotlin.String

    
    fun `name`(): kotlin.String

    
    fun `tags`(): Map<kotlin.String, kotlin.String>

    
    fun `value`(): kotlin.ByteArray

    
    companion object
}

class AskarEntry internal constructor(
    pointer: Pointer
) : FFIObject(pointer), AskarEntryInterface {

    /**
     * Disconnect the object from the underlying Rust object.
     *
     * It can be called more than once, but once called, interacting with the object
     * causes an `IllegalStateException`.
     *
     * Clients **must** call this method once done with the object, or cause a memory leak.
     */
    override protected fun freeRustArcPtr() {
        rustCall { status: RustCallStatus ->
            UniFFILib.uniffi_askar_uniffi_fn_free_askarentry(this.pointer, status)
        }
    }

    override fun `category`(): kotlin.String =
        callWithPointer {
    rustCall { _status: RustCallStatus ->
    UniFFILib.uniffi_askar_uniffi_fn_method_askarentry_category(it,  _status)
}
        }.let {
            FfiConverterString.lift(it)
        }
    
    override fun `name`(): kotlin.String =
        callWithPointer {
    rustCall { _status: RustCallStatus ->
    UniFFILib.uniffi_askar_uniffi_fn_method_askarentry_name(it,  _status)
}
        }.let {
            FfiConverterString.lift(it)
        }
    
    override fun `tags`(): Map<kotlin.String, kotlin.String> =
        callWithPointer {
    rustCall { _status: RustCallStatus ->
    UniFFILib.uniffi_askar_uniffi_fn_method_askarentry_tags(it,  _status)
}
        }.let {
            FfiConverterMapStringString.lift(it)
        }
    
    override fun `value`(): kotlin.ByteArray =
        callWithPointer {
    rustCall { _status: RustCallStatus ->
    UniFFILib.uniffi_askar_uniffi_fn_method_askarentry_value(it,  _status)
}
        }.let {
            FfiConverterByteArray.lift(it)
        }
    
    

    
    companion object
    
}

internal object FfiConverterTypeAskarEntry: FfiConverter<AskarEntry, Pointer> {
    override fun lower(value: AskarEntry): Pointer = value.callWithPointer { it }

    override fun lift(value: Pointer): AskarEntry {
        return AskarEntry(value)
    }

    override fun read(buf: NoCopySource): AskarEntry {
        // The Rust code always writes pointers as 8 bytes, and will
        // fail to compile if they don't fit.
        return lift(buf.readLong().toPointer())
    }

    override fun allocationSize(value: AskarEntry) = 8

    override fun write(value: AskarEntry, buf: Buffer) {
        // The Rust code always expects pointers written as 8 bytes,
        // and will fail to compile if they don't fit.
        buf.writeLong(lower(value).toLong())
    }
}




public interface AskarKeyEntryInterface {
    
    fun `algorithm`(): kotlin.String?

    
    fun `isLocal`(): kotlin.Boolean

    @Throws(ErrorCode::class)
    fun `loadLocalKey`(): AskarLocalKey

    
    fun `metadata`(): kotlin.String?

    
    fun `name`(): kotlin.String

    
    fun `tags`(): Map<kotlin.String, kotlin.String>

    
    companion object
}

class AskarKeyEntry internal constructor(
    pointer: Pointer
) : FFIObject(pointer), AskarKeyEntryInterface {

    /**
     * Disconnect the object from the underlying Rust object.
     *
     * It can be called more than once, but once called, interacting with the object
     * causes an `IllegalStateException`.
     *
     * Clients **must** call this method once done with the object, or cause a memory leak.
     */
    override protected fun freeRustArcPtr() {
        rustCall { status: RustCallStatus ->
            UniFFILib.uniffi_askar_uniffi_fn_free_askarkeyentry(this.pointer, status)
        }
    }

    override fun `algorithm`(): kotlin.String? =
        callWithPointer {
    rustCall { _status: RustCallStatus ->
    UniFFILib.uniffi_askar_uniffi_fn_method_askarkeyentry_algorithm(it,  _status)
}
        }.let {
            FfiConverterOptionalString.lift(it)
        }
    
    override fun `isLocal`(): kotlin.Boolean =
        callWithPointer {
    rustCall { _status: RustCallStatus ->
    UniFFILib.uniffi_askar_uniffi_fn_method_askarkeyentry_is_local(it,  _status)
}
        }.let {
            FfiConverterBoolean.lift(it)
        }
    
    
    @Throws(ErrorCode::class)override fun `loadLocalKey`(): AskarLocalKey =
        callWithPointer {
    rustCallWithError(ErrorCode) { _status: RustCallStatus ->
    UniFFILib.uniffi_askar_uniffi_fn_method_askarkeyentry_load_local_key(it,  _status)
}
        }.let {
            FfiConverterTypeAskarLocalKey.lift(it)
        }
    
    override fun `metadata`(): kotlin.String? =
        callWithPointer {
    rustCall { _status: RustCallStatus ->
    UniFFILib.uniffi_askar_uniffi_fn_method_askarkeyentry_metadata(it,  _status)
}
        }.let {
            FfiConverterOptionalString.lift(it)
        }
    
    override fun `name`(): kotlin.String =
        callWithPointer {
    rustCall { _status: RustCallStatus ->
    UniFFILib.uniffi_askar_uniffi_fn_method_askarkeyentry_name(it,  _status)
}
        }.let {
            FfiConverterString.lift(it)
        }
    
    override fun `tags`(): Map<kotlin.String, kotlin.String> =
        callWithPointer {
    rustCall { _status: RustCallStatus ->
    UniFFILib.uniffi_askar_uniffi_fn_method_askarkeyentry_tags(it,  _status)
}
        }.let {
            FfiConverterMapStringString.lift(it)
        }
    
    

    
    companion object
    
}

internal object FfiConverterTypeAskarKeyEntry: FfiConverter<AskarKeyEntry, Pointer> {
    override fun lower(value: AskarKeyEntry): Pointer = value.callWithPointer { it }

    override fun lift(value: Pointer): AskarKeyEntry {
        return AskarKeyEntry(value)
    }

    override fun read(buf: NoCopySource): AskarKeyEntry {
        // The Rust code always writes pointers as 8 bytes, and will
        // fail to compile if they don't fit.
        return lift(buf.readLong().toPointer())
    }

    override fun allocationSize(value: AskarKeyEntry) = 8

    override fun write(value: AskarKeyEntry, buf: Buffer) {
        // The Rust code always expects pointers written as 8 bytes,
        // and will fail to compile if they don't fit.
        buf.writeLong(lower(value).toLong())
    }
}




public interface AskarLocalKeyInterface {
    @Throws(ErrorCode::class)
    fun `aeadDecrypt`(`ciphertext`: kotlin.ByteArray, `tag`: kotlin.ByteArray?, `nonce`: kotlin.ByteArray, `aad`: kotlin.ByteArray?): kotlin.ByteArray

    @Throws(ErrorCode::class)
    fun `aeadEncrypt`(`message`: kotlin.ByteArray, `nonce`: kotlin.ByteArray?, `aad`: kotlin.ByteArray?): EncryptedBuffer

    
    fun `aeadPadding`(`msgLen`: kotlin.Int): kotlin.Int

    @Throws(ErrorCode::class)
    fun `aeadParams`(): AeadParams

    @Throws(ErrorCode::class)
    fun `aeadRandomNonce`(): kotlin.ByteArray

    
    fun `algorithm`(): AskarKeyAlg

    @Throws(ErrorCode::class)
    fun `convertKey`(`alg`: AskarKeyAlg): AskarLocalKey

    @Throws(ErrorCode::class)
    fun `signMessage`(`message`: kotlin.ByteArray, `sigType`: kotlin.String?): kotlin.ByteArray

    @Throws(ErrorCode::class)
    fun `toJwkPublic`(`alg`: AskarKeyAlg?): kotlin.String

    @Throws(ErrorCode::class)
    fun `toJwkSecret`(): kotlin.ByteArray

    @Throws(ErrorCode::class)
    fun `toJwkThumbprint`(`alg`: AskarKeyAlg?): kotlin.String

    @Throws(ErrorCode::class)
    fun `toJwkThumbprints`(): List<kotlin.String>

    @Throws(ErrorCode::class)
    fun `toKeyExchange`(`alg`: AskarKeyAlg, `pk`: AskarLocalKey): AskarLocalKey

    @Throws(ErrorCode::class)
    fun `toPublicBytes`(): kotlin.ByteArray

    @Throws(ErrorCode::class)
    fun `toSecretBytes`(): kotlin.ByteArray

    @Throws(ErrorCode::class)
    fun `unwrapKey`(`alg`: AskarKeyAlg, `ciphertext`: kotlin.ByteArray, `tag`: kotlin.ByteArray?, `nonce`: kotlin.ByteArray?): AskarLocalKey

    @Throws(ErrorCode::class)
    fun `verifySignature`(`message`: kotlin.ByteArray, `signature`: kotlin.ByteArray, `sigType`: kotlin.String?): kotlin.Boolean

    @Throws(ErrorCode::class)
    fun `wrapKey`(`key`: AskarLocalKey, `nonce`: kotlin.ByteArray?): EncryptedBuffer

    
    companion object
}

class AskarLocalKey internal constructor(
    pointer: Pointer
) : FFIObject(pointer), AskarLocalKeyInterface {

    /**
     * Disconnect the object from the underlying Rust object.
     *
     * It can be called more than once, but once called, interacting with the object
     * causes an `IllegalStateException`.
     *
     * Clients **must** call this method once done with the object, or cause a memory leak.
     */
    override protected fun freeRustArcPtr() {
        rustCall { status: RustCallStatus ->
            UniFFILib.uniffi_askar_uniffi_fn_free_askarlocalkey(this.pointer, status)
        }
    }

    
    @Throws(ErrorCode::class)override fun `aeadDecrypt`(`ciphertext`: kotlin.ByteArray, `tag`: kotlin.ByteArray?, `nonce`: kotlin.ByteArray, `aad`: kotlin.ByteArray?): kotlin.ByteArray =
        callWithPointer {
    rustCallWithError(ErrorCode) { _status: RustCallStatus ->
    UniFFILib.uniffi_askar_uniffi_fn_method_askarlocalkey_aead_decrypt(it, FfiConverterByteArray.lower(`ciphertext`),FfiConverterOptionalByteArray.lower(`tag`),FfiConverterByteArray.lower(`nonce`),FfiConverterOptionalByteArray.lower(`aad`), _status)
}
        }.let {
            FfiConverterByteArray.lift(it)
        }
    
    
    @Throws(ErrorCode::class)override fun `aeadEncrypt`(`message`: kotlin.ByteArray, `nonce`: kotlin.ByteArray?, `aad`: kotlin.ByteArray?): EncryptedBuffer =
        callWithPointer {
    rustCallWithError(ErrorCode) { _status: RustCallStatus ->
    UniFFILib.uniffi_askar_uniffi_fn_method_askarlocalkey_aead_encrypt(it, FfiConverterByteArray.lower(`message`),FfiConverterOptionalByteArray.lower(`nonce`),FfiConverterOptionalByteArray.lower(`aad`), _status)
}
        }.let {
            FfiConverterTypeEncryptedBuffer.lift(it)
        }
    
    override fun `aeadPadding`(`msgLen`: kotlin.Int): kotlin.Int =
        callWithPointer {
    rustCall { _status: RustCallStatus ->
    UniFFILib.uniffi_askar_uniffi_fn_method_askarlocalkey_aead_padding(it, FfiConverterInt.lower(`msgLen`), _status)
}
        }.let {
            FfiConverterInt.lift(it)
        }
    
    
    @Throws(ErrorCode::class)override fun `aeadParams`(): AeadParams =
        callWithPointer {
    rustCallWithError(ErrorCode) { _status: RustCallStatus ->
    UniFFILib.uniffi_askar_uniffi_fn_method_askarlocalkey_aead_params(it,  _status)
}
        }.let {
            FfiConverterTypeAeadParams.lift(it)
        }
    
    
    @Throws(ErrorCode::class)override fun `aeadRandomNonce`(): kotlin.ByteArray =
        callWithPointer {
    rustCallWithError(ErrorCode) { _status: RustCallStatus ->
    UniFFILib.uniffi_askar_uniffi_fn_method_askarlocalkey_aead_random_nonce(it,  _status)
}
        }.let {
            FfiConverterByteArray.lift(it)
        }
    
    override fun `algorithm`(): AskarKeyAlg =
        callWithPointer {
    rustCall { _status: RustCallStatus ->
    UniFFILib.uniffi_askar_uniffi_fn_method_askarlocalkey_algorithm(it,  _status)
}
        }.let {
            FfiConverterTypeAskarKeyAlg.lift(it)
        }
    
    
    @Throws(ErrorCode::class)override fun `convertKey`(`alg`: AskarKeyAlg): AskarLocalKey =
        callWithPointer {
    rustCallWithError(ErrorCode) { _status: RustCallStatus ->
    UniFFILib.uniffi_askar_uniffi_fn_method_askarlocalkey_convert_key(it, FfiConverterTypeAskarKeyAlg.lower(`alg`), _status)
}
        }.let {
            FfiConverterTypeAskarLocalKey.lift(it)
        }
    
    
    @Throws(ErrorCode::class)override fun `signMessage`(`message`: kotlin.ByteArray, `sigType`: kotlin.String?): kotlin.ByteArray =
        callWithPointer {
    rustCallWithError(ErrorCode) { _status: RustCallStatus ->
    UniFFILib.uniffi_askar_uniffi_fn_method_askarlocalkey_sign_message(it, FfiConverterByteArray.lower(`message`),FfiConverterOptionalString.lower(`sigType`), _status)
}
        }.let {
            FfiConverterByteArray.lift(it)
        }
    
    
    @Throws(ErrorCode::class)override fun `toJwkPublic`(`alg`: AskarKeyAlg?): kotlin.String =
        callWithPointer {
    rustCallWithError(ErrorCode) { _status: RustCallStatus ->
    UniFFILib.uniffi_askar_uniffi_fn_method_askarlocalkey_to_jwk_public(it, FfiConverterOptionalTypeAskarKeyAlg.lower(`alg`), _status)
}
        }.let {
            FfiConverterString.lift(it)
        }
    
    
    @Throws(ErrorCode::class)override fun `toJwkSecret`(): kotlin.ByteArray =
        callWithPointer {
    rustCallWithError(ErrorCode) { _status: RustCallStatus ->
    UniFFILib.uniffi_askar_uniffi_fn_method_askarlocalkey_to_jwk_secret(it,  _status)
}
        }.let {
            FfiConverterByteArray.lift(it)
        }
    
    
    @Throws(ErrorCode::class)override fun `toJwkThumbprint`(`alg`: AskarKeyAlg?): kotlin.String =
        callWithPointer {
    rustCallWithError(ErrorCode) { _status: RustCallStatus ->
    UniFFILib.uniffi_askar_uniffi_fn_method_askarlocalkey_to_jwk_thumbprint(it, FfiConverterOptionalTypeAskarKeyAlg.lower(`alg`), _status)
}
        }.let {
            FfiConverterString.lift(it)
        }
    
    
    @Throws(ErrorCode::class)override fun `toJwkThumbprints`(): List<kotlin.String> =
        callWithPointer {
    rustCallWithError(ErrorCode) { _status: RustCallStatus ->
    UniFFILib.uniffi_askar_uniffi_fn_method_askarlocalkey_to_jwk_thumbprints(it,  _status)
}
        }.let {
            FfiConverterSequenceString.lift(it)
        }
    
    
    @Throws(ErrorCode::class)override fun `toKeyExchange`(`alg`: AskarKeyAlg, `pk`: AskarLocalKey): AskarLocalKey =
        callWithPointer {
    rustCallWithError(ErrorCode) { _status: RustCallStatus ->
    UniFFILib.uniffi_askar_uniffi_fn_method_askarlocalkey_to_key_exchange(it, FfiConverterTypeAskarKeyAlg.lower(`alg`),FfiConverterTypeAskarLocalKey.lower(`pk`), _status)
}
        }.let {
            FfiConverterTypeAskarLocalKey.lift(it)
        }
    
    
    @Throws(ErrorCode::class)override fun `toPublicBytes`(): kotlin.ByteArray =
        callWithPointer {
    rustCallWithError(ErrorCode) { _status: RustCallStatus ->
    UniFFILib.uniffi_askar_uniffi_fn_method_askarlocalkey_to_public_bytes(it,  _status)
}
        }.let {
            FfiConverterByteArray.lift(it)
        }
    
    
    @Throws(ErrorCode::class)override fun `toSecretBytes`(): kotlin.ByteArray =
        callWithPointer {
    rustCallWithError(ErrorCode) { _status: RustCallStatus ->
    UniFFILib.uniffi_askar_uniffi_fn_method_askarlocalkey_to_secret_bytes(it,  _status)
}
        }.let {
            FfiConverterByteArray.lift(it)
        }
    
    
    @Throws(ErrorCode::class)override fun `unwrapKey`(`alg`: AskarKeyAlg, `ciphertext`: kotlin.ByteArray, `tag`: kotlin.ByteArray?, `nonce`: kotlin.ByteArray?): AskarLocalKey =
        callWithPointer {
    rustCallWithError(ErrorCode) { _status: RustCallStatus ->
    UniFFILib.uniffi_askar_uniffi_fn_method_askarlocalkey_unwrap_key(it, FfiConverterTypeAskarKeyAlg.lower(`alg`),FfiConverterByteArray.lower(`ciphertext`),FfiConverterOptionalByteArray.lower(`tag`),FfiConverterOptionalByteArray.lower(`nonce`), _status)
}
        }.let {
            FfiConverterTypeAskarLocalKey.lift(it)
        }
    
    
    @Throws(ErrorCode::class)override fun `verifySignature`(`message`: kotlin.ByteArray, `signature`: kotlin.ByteArray, `sigType`: kotlin.String?): kotlin.Boolean =
        callWithPointer {
    rustCallWithError(ErrorCode) { _status: RustCallStatus ->
    UniFFILib.uniffi_askar_uniffi_fn_method_askarlocalkey_verify_signature(it, FfiConverterByteArray.lower(`message`),FfiConverterByteArray.lower(`signature`),FfiConverterOptionalString.lower(`sigType`), _status)
}
        }.let {
            FfiConverterBoolean.lift(it)
        }
    
    
    @Throws(ErrorCode::class)override fun `wrapKey`(`key`: AskarLocalKey, `nonce`: kotlin.ByteArray?): EncryptedBuffer =
        callWithPointer {
    rustCallWithError(ErrorCode) { _status: RustCallStatus ->
    UniFFILib.uniffi_askar_uniffi_fn_method_askarlocalkey_wrap_key(it, FfiConverterTypeAskarLocalKey.lower(`key`),FfiConverterOptionalByteArray.lower(`nonce`), _status)
}
        }.let {
            FfiConverterTypeEncryptedBuffer.lift(it)
        }
    
    

    
    companion object
    
}

internal object FfiConverterTypeAskarLocalKey: FfiConverter<AskarLocalKey, Pointer> {
    override fun lower(value: AskarLocalKey): Pointer = value.callWithPointer { it }

    override fun lift(value: Pointer): AskarLocalKey {
        return AskarLocalKey(value)
    }

    override fun read(buf: NoCopySource): AskarLocalKey {
        // The Rust code always writes pointers as 8 bytes, and will
        // fail to compile if they don't fit.
        return lift(buf.readLong().toPointer())
    }

    override fun allocationSize(value: AskarLocalKey) = 8

    override fun write(value: AskarLocalKey, buf: Buffer) {
        // The Rust code always expects pointers written as 8 bytes,
        // and will fail to compile if they don't fit.
        buf.writeLong(lower(value).toLong())
    }
}




public interface AskarScanInterface {
    @Throws(ErrorCode::class, CancellationException::class)
    suspend fun `fetchAll`(): List<AskarEntry>

    @Throws(ErrorCode::class, CancellationException::class)
    suspend fun `next`(): List<AskarEntry>?

    
    companion object
}

class AskarScan internal constructor(
    pointer: Pointer
) : FFIObject(pointer), AskarScanInterface {

    /**
     * Disconnect the object from the underlying Rust object.
     *
     * It can be called more than once, but once called, interacting with the object
     * causes an `IllegalStateException`.
     *
     * Clients **must** call this method once done with the object, or cause a memory leak.
     */
    override protected fun freeRustArcPtr() {
        rustCall { status: RustCallStatus ->
            UniFFILib.uniffi_askar_uniffi_fn_free_askarscan(this.pointer, status)
        }
    }

    
    @Throws(ErrorCode::class, CancellationException::class)
    @Suppress("ASSIGNED_BUT_NEVER_ACCESSED_VARIABLE")
    override suspend fun `fetchAll`() : List<AskarEntry> {
        return uniffiRustCallAsync(
            callWithPointer { thisPtr ->
                UniFFILib.uniffi_askar_uniffi_fn_method_askarscan_fetch_all(
                    thisPtr,
                    
                )
            },
            { future, continuation -> UniFFILib.ffi_askar_uniffi_rust_future_poll_rust_buffer(future, continuation) },
            { future, continuation -> UniFFILib.ffi_askar_uniffi_rust_future_complete_rust_buffer(future, continuation) },
            { future -> UniFFILib.ffi_askar_uniffi_rust_future_free_rust_buffer(future) },
            // lift function
            { FfiConverterSequenceTypeAskarEntry.lift(it) },
            // Error FFI converter
            ErrorCode.ErrorHandler,
        )
    }
    
    @Throws(ErrorCode::class, CancellationException::class)
    @Suppress("ASSIGNED_BUT_NEVER_ACCESSED_VARIABLE")
    override suspend fun `next`() : List<AskarEntry>? {
        return uniffiRustCallAsync(
            callWithPointer { thisPtr ->
                UniFFILib.uniffi_askar_uniffi_fn_method_askarscan_next(
                    thisPtr,
                    
                )
            },
            { future, continuation -> UniFFILib.ffi_askar_uniffi_rust_future_poll_rust_buffer(future, continuation) },
            { future, continuation -> UniFFILib.ffi_askar_uniffi_rust_future_complete_rust_buffer(future, continuation) },
            { future -> UniFFILib.ffi_askar_uniffi_rust_future_free_rust_buffer(future) },
            // lift function
            { FfiConverterOptionalSequenceTypeAskarEntry.lift(it) },
            // Error FFI converter
            ErrorCode.ErrorHandler,
        )
    }
    

    
    companion object
    
}

internal object FfiConverterTypeAskarScan: FfiConverter<AskarScan, Pointer> {
    override fun lower(value: AskarScan): Pointer = value.callWithPointer { it }

    override fun lift(value: Pointer): AskarScan {
        return AskarScan(value)
    }

    override fun read(buf: NoCopySource): AskarScan {
        // The Rust code always writes pointers as 8 bytes, and will
        // fail to compile if they don't fit.
        return lift(buf.readLong().toPointer())
    }

    override fun allocationSize(value: AskarScan) = 8

    override fun write(value: AskarScan, buf: Buffer) {
        // The Rust code always expects pointers written as 8 bytes,
        // and will fail to compile if they don't fit.
        buf.writeLong(lower(value).toLong())
    }
}




public interface AskarSessionInterface {
    @Throws(ErrorCode::class, CancellationException::class)
    suspend fun `close`()

    @Throws(ErrorCode::class, CancellationException::class)
    suspend fun `count`(`category`: kotlin.String, `tagFilter`: kotlin.String?): kotlin.Long

    @Throws(ErrorCode::class, CancellationException::class)
    suspend fun `fetch`(`category`: kotlin.String, `name`: kotlin.String, `forUpdate`: kotlin.Boolean): AskarEntry?

    @Throws(ErrorCode::class, CancellationException::class)
    suspend fun `fetchAll`(`category`: kotlin.String, `tagFilter`: kotlin.String?, `limit`: kotlin.Long?, `forUpdate`: kotlin.Boolean): List<AskarEntry>

    @Throws(ErrorCode::class, CancellationException::class)
    suspend fun `fetchAllKeys`(`algorithm`: kotlin.String?, `thumbprint`: kotlin.String?, `tagFilter`: kotlin.String?, `limit`: kotlin.Long?, `forUpdate`: kotlin.Boolean): List<AskarKeyEntry>

    @Throws(ErrorCode::class, CancellationException::class)
    suspend fun `fetchKey`(`name`: kotlin.String, `forUpdate`: kotlin.Boolean): AskarKeyEntry?

    @Throws(ErrorCode::class, CancellationException::class)
    suspend fun `insertKey`(`name`: kotlin.String, `key`: AskarLocalKey, `metadata`: kotlin.String?, `tags`: kotlin.String?, `expiryMs`: kotlin.Long?)

    @Throws(ErrorCode::class, CancellationException::class)
    suspend fun `removeAll`(`category`: kotlin.String, `tagFilter`: kotlin.String?): kotlin.Long

    @Throws(ErrorCode::class, CancellationException::class)
    suspend fun `removeKey`(`name`: kotlin.String)

    @Throws(ErrorCode::class, CancellationException::class)
    suspend fun `update`(`operation`: AskarEntryOperation, `category`: kotlin.String, `name`: kotlin.String, `value`: kotlin.ByteArray, `tags`: kotlin.String?, `expiryMs`: kotlin.Long?)

    @Throws(ErrorCode::class, CancellationException::class)
    suspend fun `updateKey`(`name`: kotlin.String, `metadata`: kotlin.String?, `tags`: kotlin.String?, `expiryMs`: kotlin.Long?)

    
    companion object
}

class AskarSession internal constructor(
    pointer: Pointer
) : FFIObject(pointer), AskarSessionInterface {

    /**
     * Disconnect the object from the underlying Rust object.
     *
     * It can be called more than once, but once called, interacting with the object
     * causes an `IllegalStateException`.
     *
     * Clients **must** call this method once done with the object, or cause a memory leak.
     */
    override protected fun freeRustArcPtr() {
        rustCall { status: RustCallStatus ->
            UniFFILib.uniffi_askar_uniffi_fn_free_askarsession(this.pointer, status)
        }
    }

    
    @Throws(ErrorCode::class, CancellationException::class)
    @Suppress("ASSIGNED_BUT_NEVER_ACCESSED_VARIABLE")
    override suspend fun `close`() {
        return uniffiRustCallAsync(
            callWithPointer { thisPtr ->
                UniFFILib.uniffi_askar_uniffi_fn_method_askarsession_close(
                    thisPtr,
                    
                )
            },
            { future, continuation -> UniFFILib.ffi_askar_uniffi_rust_future_poll_void(future, continuation) },
            { future, continuation -> UniFFILib.ffi_askar_uniffi_rust_future_complete_void(future, continuation) },
            { future -> UniFFILib.ffi_askar_uniffi_rust_future_free_void(future) },
            // lift function
            { Unit },
            
            // Error FFI converter
            ErrorCode.ErrorHandler,
        )
    }
    
    @Throws(ErrorCode::class, CancellationException::class)
    @Suppress("ASSIGNED_BUT_NEVER_ACCESSED_VARIABLE")
    override suspend fun `count`(`category`: kotlin.String, `tagFilter`: kotlin.String?) : kotlin.Long {
        return uniffiRustCallAsync(
            callWithPointer { thisPtr ->
                UniFFILib.uniffi_askar_uniffi_fn_method_askarsession_count(
                    thisPtr,
                    FfiConverterString.lower(`category`),FfiConverterOptionalString.lower(`tagFilter`),
                )
            },
            { future, continuation -> UniFFILib.ffi_askar_uniffi_rust_future_poll_i64(future, continuation) },
            { future, continuation -> UniFFILib.ffi_askar_uniffi_rust_future_complete_i64(future, continuation) },
            { future -> UniFFILib.ffi_askar_uniffi_rust_future_free_i64(future) },
            // lift function
            { FfiConverterLong.lift(it) },
            // Error FFI converter
            ErrorCode.ErrorHandler,
        )
    }
    
    @Throws(ErrorCode::class, CancellationException::class)
    @Suppress("ASSIGNED_BUT_NEVER_ACCESSED_VARIABLE")
    override suspend fun `fetch`(`category`: kotlin.String, `name`: kotlin.String, `forUpdate`: kotlin.Boolean) : AskarEntry? {
        return uniffiRustCallAsync(
            callWithPointer { thisPtr ->
                UniFFILib.uniffi_askar_uniffi_fn_method_askarsession_fetch(
                    thisPtr,
                    FfiConverterString.lower(`category`),FfiConverterString.lower(`name`),FfiConverterBoolean.lower(`forUpdate`),
                )
            },
            { future, continuation -> UniFFILib.ffi_askar_uniffi_rust_future_poll_rust_buffer(future, continuation) },
            { future, continuation -> UniFFILib.ffi_askar_uniffi_rust_future_complete_rust_buffer(future, continuation) },
            { future -> UniFFILib.ffi_askar_uniffi_rust_future_free_rust_buffer(future) },
            // lift function
            { FfiConverterOptionalTypeAskarEntry.lift(it) },
            // Error FFI converter
            ErrorCode.ErrorHandler,
        )
    }
    
    @Throws(ErrorCode::class, CancellationException::class)
    @Suppress("ASSIGNED_BUT_NEVER_ACCESSED_VARIABLE")
    override suspend fun `fetchAll`(`category`: kotlin.String, `tagFilter`: kotlin.String?, `limit`: kotlin.Long?, `forUpdate`: kotlin.Boolean) : List<AskarEntry> {
        return uniffiRustCallAsync(
            callWithPointer { thisPtr ->
                UniFFILib.uniffi_askar_uniffi_fn_method_askarsession_fetch_all(
                    thisPtr,
                    FfiConverterString.lower(`category`),FfiConverterOptionalString.lower(`tagFilter`),FfiConverterOptionalLong.lower(`limit`),FfiConverterBoolean.lower(`forUpdate`),
                )
            },
            { future, continuation -> UniFFILib.ffi_askar_uniffi_rust_future_poll_rust_buffer(future, continuation) },
            { future, continuation -> UniFFILib.ffi_askar_uniffi_rust_future_complete_rust_buffer(future, continuation) },
            { future -> UniFFILib.ffi_askar_uniffi_rust_future_free_rust_buffer(future) },
            // lift function
            { FfiConverterSequenceTypeAskarEntry.lift(it) },
            // Error FFI converter
            ErrorCode.ErrorHandler,
        )
    }
    
    @Throws(ErrorCode::class, CancellationException::class)
    @Suppress("ASSIGNED_BUT_NEVER_ACCESSED_VARIABLE")
    override suspend fun `fetchAllKeys`(`algorithm`: kotlin.String?, `thumbprint`: kotlin.String?, `tagFilter`: kotlin.String?, `limit`: kotlin.Long?, `forUpdate`: kotlin.Boolean) : List<AskarKeyEntry> {
        return uniffiRustCallAsync(
            callWithPointer { thisPtr ->
                UniFFILib.uniffi_askar_uniffi_fn_method_askarsession_fetch_all_keys(
                    thisPtr,
                    FfiConverterOptionalString.lower(`algorithm`),FfiConverterOptionalString.lower(`thumbprint`),FfiConverterOptionalString.lower(`tagFilter`),FfiConverterOptionalLong.lower(`limit`),FfiConverterBoolean.lower(`forUpdate`),
                )
            },
            { future, continuation -> UniFFILib.ffi_askar_uniffi_rust_future_poll_rust_buffer(future, continuation) },
            { future, continuation -> UniFFILib.ffi_askar_uniffi_rust_future_complete_rust_buffer(future, continuation) },
            { future -> UniFFILib.ffi_askar_uniffi_rust_future_free_rust_buffer(future) },
            // lift function
            { FfiConverterSequenceTypeAskarKeyEntry.lift(it) },
            // Error FFI converter
            ErrorCode.ErrorHandler,
        )
    }
    
    @Throws(ErrorCode::class, CancellationException::class)
    @Suppress("ASSIGNED_BUT_NEVER_ACCESSED_VARIABLE")
    override suspend fun `fetchKey`(`name`: kotlin.String, `forUpdate`: kotlin.Boolean) : AskarKeyEntry? {
        return uniffiRustCallAsync(
            callWithPointer { thisPtr ->
                UniFFILib.uniffi_askar_uniffi_fn_method_askarsession_fetch_key(
                    thisPtr,
                    FfiConverterString.lower(`name`),FfiConverterBoolean.lower(`forUpdate`),
                )
            },
            { future, continuation -> UniFFILib.ffi_askar_uniffi_rust_future_poll_rust_buffer(future, continuation) },
            { future, continuation -> UniFFILib.ffi_askar_uniffi_rust_future_complete_rust_buffer(future, continuation) },
            { future -> UniFFILib.ffi_askar_uniffi_rust_future_free_rust_buffer(future) },
            // lift function
            { FfiConverterOptionalTypeAskarKeyEntry.lift(it) },
            // Error FFI converter
            ErrorCode.ErrorHandler,
        )
    }
    
    @Throws(ErrorCode::class, CancellationException::class)
    @Suppress("ASSIGNED_BUT_NEVER_ACCESSED_VARIABLE")
    override suspend fun `insertKey`(`name`: kotlin.String, `key`: AskarLocalKey, `metadata`: kotlin.String?, `tags`: kotlin.String?, `expiryMs`: kotlin.Long?) {
        return uniffiRustCallAsync(
            callWithPointer { thisPtr ->
                UniFFILib.uniffi_askar_uniffi_fn_method_askarsession_insert_key(
                    thisPtr,
                    FfiConverterString.lower(`name`),FfiConverterTypeAskarLocalKey.lower(`key`),FfiConverterOptionalString.lower(`metadata`),FfiConverterOptionalString.lower(`tags`),FfiConverterOptionalLong.lower(`expiryMs`),
                )
            },
            { future, continuation -> UniFFILib.ffi_askar_uniffi_rust_future_poll_void(future, continuation) },
            { future, continuation -> UniFFILib.ffi_askar_uniffi_rust_future_complete_void(future, continuation) },
            { future -> UniFFILib.ffi_askar_uniffi_rust_future_free_void(future) },
            // lift function
            { Unit },
            
            // Error FFI converter
            ErrorCode.ErrorHandler,
        )
    }
    
    @Throws(ErrorCode::class, CancellationException::class)
    @Suppress("ASSIGNED_BUT_NEVER_ACCESSED_VARIABLE")
    override suspend fun `removeAll`(`category`: kotlin.String, `tagFilter`: kotlin.String?) : kotlin.Long {
        return uniffiRustCallAsync(
            callWithPointer { thisPtr ->
                UniFFILib.uniffi_askar_uniffi_fn_method_askarsession_remove_all(
                    thisPtr,
                    FfiConverterString.lower(`category`),FfiConverterOptionalString.lower(`tagFilter`),
                )
            },
            { future, continuation -> UniFFILib.ffi_askar_uniffi_rust_future_poll_i64(future, continuation) },
            { future, continuation -> UniFFILib.ffi_askar_uniffi_rust_future_complete_i64(future, continuation) },
            { future -> UniFFILib.ffi_askar_uniffi_rust_future_free_i64(future) },
            // lift function
            { FfiConverterLong.lift(it) },
            // Error FFI converter
            ErrorCode.ErrorHandler,
        )
    }
    
    @Throws(ErrorCode::class, CancellationException::class)
    @Suppress("ASSIGNED_BUT_NEVER_ACCESSED_VARIABLE")
    override suspend fun `removeKey`(`name`: kotlin.String) {
        return uniffiRustCallAsync(
            callWithPointer { thisPtr ->
                UniFFILib.uniffi_askar_uniffi_fn_method_askarsession_remove_key(
                    thisPtr,
                    FfiConverterString.lower(`name`),
                )
            },
            { future, continuation -> UniFFILib.ffi_askar_uniffi_rust_future_poll_void(future, continuation) },
            { future, continuation -> UniFFILib.ffi_askar_uniffi_rust_future_complete_void(future, continuation) },
            { future -> UniFFILib.ffi_askar_uniffi_rust_future_free_void(future) },
            // lift function
            { Unit },
            
            // Error FFI converter
            ErrorCode.ErrorHandler,
        )
    }
    
    @Throws(ErrorCode::class, CancellationException::class)
    @Suppress("ASSIGNED_BUT_NEVER_ACCESSED_VARIABLE")
    override suspend fun `update`(`operation`: AskarEntryOperation, `category`: kotlin.String, `name`: kotlin.String, `value`: kotlin.ByteArray, `tags`: kotlin.String?, `expiryMs`: kotlin.Long?) {
        return uniffiRustCallAsync(
            callWithPointer { thisPtr ->
                UniFFILib.uniffi_askar_uniffi_fn_method_askarsession_update(
                    thisPtr,
                    FfiConverterTypeAskarEntryOperation.lower(`operation`),FfiConverterString.lower(`category`),FfiConverterString.lower(`name`),FfiConverterByteArray.lower(`value`),FfiConverterOptionalString.lower(`tags`),FfiConverterOptionalLong.lower(`expiryMs`),
                )
            },
            { future, continuation -> UniFFILib.ffi_askar_uniffi_rust_future_poll_void(future, continuation) },
            { future, continuation -> UniFFILib.ffi_askar_uniffi_rust_future_complete_void(future, continuation) },
            { future -> UniFFILib.ffi_askar_uniffi_rust_future_free_void(future) },
            // lift function
            { Unit },
            
            // Error FFI converter
            ErrorCode.ErrorHandler,
        )
    }
    
    @Throws(ErrorCode::class, CancellationException::class)
    @Suppress("ASSIGNED_BUT_NEVER_ACCESSED_VARIABLE")
    override suspend fun `updateKey`(`name`: kotlin.String, `metadata`: kotlin.String?, `tags`: kotlin.String?, `expiryMs`: kotlin.Long?) {
        return uniffiRustCallAsync(
            callWithPointer { thisPtr ->
                UniFFILib.uniffi_askar_uniffi_fn_method_askarsession_update_key(
                    thisPtr,
                    FfiConverterString.lower(`name`),FfiConverterOptionalString.lower(`metadata`),FfiConverterOptionalString.lower(`tags`),FfiConverterOptionalLong.lower(`expiryMs`),
                )
            },
            { future, continuation -> UniFFILib.ffi_askar_uniffi_rust_future_poll_void(future, continuation) },
            { future, continuation -> UniFFILib.ffi_askar_uniffi_rust_future_complete_void(future, continuation) },
            { future -> UniFFILib.ffi_askar_uniffi_rust_future_free_void(future) },
            // lift function
            { Unit },
            
            // Error FFI converter
            ErrorCode.ErrorHandler,
        )
    }
    

    
    companion object
    
}

internal object FfiConverterTypeAskarSession: FfiConverter<AskarSession, Pointer> {
    override fun lower(value: AskarSession): Pointer = value.callWithPointer { it }

    override fun lift(value: Pointer): AskarSession {
        return AskarSession(value)
    }

    override fun read(buf: NoCopySource): AskarSession {
        // The Rust code always writes pointers as 8 bytes, and will
        // fail to compile if they don't fit.
        return lift(buf.readLong().toPointer())
    }

    override fun allocationSize(value: AskarSession) = 8

    override fun write(value: AskarSession, buf: Buffer) {
        // The Rust code always expects pointers written as 8 bytes,
        // and will fail to compile if they don't fit.
        buf.writeLong(lower(value).toLong())
    }
}




public interface AskarStoreInterface {
    @Throws(ErrorCode::class, CancellationException::class)
    suspend fun `close`()

    @Throws(ErrorCode::class, CancellationException::class)
    suspend fun `createProfile`(`profile`: kotlin.String?): kotlin.String

    @Throws(ErrorCode::class, CancellationException::class)
    suspend fun `getProfileName`(): kotlin.String

    @Throws(ErrorCode::class, CancellationException::class)
    suspend fun `rekey`(`keyMethod`: kotlin.String?, `passKey`: kotlin.String?)

    @Throws(ErrorCode::class, CancellationException::class)
    suspend fun `removeProfile`(`profile`: kotlin.String): kotlin.Boolean

    @Throws(ErrorCode::class, CancellationException::class)
    suspend fun `scan`(`profile`: kotlin.String?, `category`: kotlin.String, `tagFilter`: kotlin.String?, `offset`: kotlin.Long?, `limit`: kotlin.Long?): AskarScan

    @Throws(ErrorCode::class, CancellationException::class)
    suspend fun `session`(`profile`: kotlin.String?): AskarSession

    
    companion object
}

class AskarStore internal constructor(
    pointer: Pointer
) : FFIObject(pointer), AskarStoreInterface {

    /**
     * Disconnect the object from the underlying Rust object.
     *
     * It can be called more than once, but once called, interacting with the object
     * causes an `IllegalStateException`.
     *
     * Clients **must** call this method once done with the object, or cause a memory leak.
     */
    override protected fun freeRustArcPtr() {
        rustCall { status: RustCallStatus ->
            UniFFILib.uniffi_askar_uniffi_fn_free_askarstore(this.pointer, status)
        }
    }

    
    @Throws(ErrorCode::class, CancellationException::class)
    @Suppress("ASSIGNED_BUT_NEVER_ACCESSED_VARIABLE")
    override suspend fun `close`() {
        return uniffiRustCallAsync(
            callWithPointer { thisPtr ->
                UniFFILib.uniffi_askar_uniffi_fn_method_askarstore_close(
                    thisPtr,
                    
                )
            },
            { future, continuation -> UniFFILib.ffi_askar_uniffi_rust_future_poll_void(future, continuation) },
            { future, continuation -> UniFFILib.ffi_askar_uniffi_rust_future_complete_void(future, continuation) },
            { future -> UniFFILib.ffi_askar_uniffi_rust_future_free_void(future) },
            // lift function
            { Unit },
            
            // Error FFI converter
            ErrorCode.ErrorHandler,
        )
    }
    
    @Throws(ErrorCode::class, CancellationException::class)
    @Suppress("ASSIGNED_BUT_NEVER_ACCESSED_VARIABLE")
    override suspend fun `createProfile`(`profile`: kotlin.String?) : kotlin.String {
        return uniffiRustCallAsync(
            callWithPointer { thisPtr ->
                UniFFILib.uniffi_askar_uniffi_fn_method_askarstore_create_profile(
                    thisPtr,
                    FfiConverterOptionalString.lower(`profile`),
                )
            },
            { future, continuation -> UniFFILib.ffi_askar_uniffi_rust_future_poll_rust_buffer(future, continuation) },
            { future, continuation -> UniFFILib.ffi_askar_uniffi_rust_future_complete_rust_buffer(future, continuation) },
            { future -> UniFFILib.ffi_askar_uniffi_rust_future_free_rust_buffer(future) },
            // lift function
            { FfiConverterString.lift(it) },
            // Error FFI converter
            ErrorCode.ErrorHandler,
        )
    }
    
    @Throws(ErrorCode::class, CancellationException::class)
    @Suppress("ASSIGNED_BUT_NEVER_ACCESSED_VARIABLE")
    override suspend fun `getProfileName`() : kotlin.String {
        return uniffiRustCallAsync(
            callWithPointer { thisPtr ->
                UniFFILib.uniffi_askar_uniffi_fn_method_askarstore_get_profile_name(
                    thisPtr,
                    
                )
            },
            { future, continuation -> UniFFILib.ffi_askar_uniffi_rust_future_poll_rust_buffer(future, continuation) },
            { future, continuation -> UniFFILib.ffi_askar_uniffi_rust_future_complete_rust_buffer(future, continuation) },
            { future -> UniFFILib.ffi_askar_uniffi_rust_future_free_rust_buffer(future) },
            // lift function
            { FfiConverterString.lift(it) },
            // Error FFI converter
            ErrorCode.ErrorHandler,
        )
    }
    
    @Throws(ErrorCode::class, CancellationException::class)
    @Suppress("ASSIGNED_BUT_NEVER_ACCESSED_VARIABLE")
    override suspend fun `rekey`(`keyMethod`: kotlin.String?, `passKey`: kotlin.String?) {
        return uniffiRustCallAsync(
            callWithPointer { thisPtr ->
                UniFFILib.uniffi_askar_uniffi_fn_method_askarstore_rekey(
                    thisPtr,
                    FfiConverterOptionalString.lower(`keyMethod`),FfiConverterOptionalString.lower(`passKey`),
                )
            },
            { future, continuation -> UniFFILib.ffi_askar_uniffi_rust_future_poll_void(future, continuation) },
            { future, continuation -> UniFFILib.ffi_askar_uniffi_rust_future_complete_void(future, continuation) },
            { future -> UniFFILib.ffi_askar_uniffi_rust_future_free_void(future) },
            // lift function
            { Unit },
            
            // Error FFI converter
            ErrorCode.ErrorHandler,
        )
    }
    
    @Throws(ErrorCode::class, CancellationException::class)
    @Suppress("ASSIGNED_BUT_NEVER_ACCESSED_VARIABLE")
    override suspend fun `removeProfile`(`profile`: kotlin.String) : kotlin.Boolean {
        return uniffiRustCallAsync(
            callWithPointer { thisPtr ->
                UniFFILib.uniffi_askar_uniffi_fn_method_askarstore_remove_profile(
                    thisPtr,
                    FfiConverterString.lower(`profile`),
                )
            },
            { future, continuation -> UniFFILib.ffi_askar_uniffi_rust_future_poll_i8(future, continuation) },
            { future, continuation -> UniFFILib.ffi_askar_uniffi_rust_future_complete_i8(future, continuation) },
            { future -> UniFFILib.ffi_askar_uniffi_rust_future_free_i8(future) },
            // lift function
            { FfiConverterBoolean.lift(it) },
            // Error FFI converter
            ErrorCode.ErrorHandler,
        )
    }
    
    @Throws(ErrorCode::class, CancellationException::class)
    @Suppress("ASSIGNED_BUT_NEVER_ACCESSED_VARIABLE")
    override suspend fun `scan`(`profile`: kotlin.String?, `category`: kotlin.String, `tagFilter`: kotlin.String?, `offset`: kotlin.Long?, `limit`: kotlin.Long?) : AskarScan {
        return uniffiRustCallAsync(
            callWithPointer { thisPtr ->
                UniFFILib.uniffi_askar_uniffi_fn_method_askarstore_scan(
                    thisPtr,
                    FfiConverterOptionalString.lower(`profile`),FfiConverterString.lower(`category`),FfiConverterOptionalString.lower(`tagFilter`),FfiConverterOptionalLong.lower(`offset`),FfiConverterOptionalLong.lower(`limit`),
                )
            },
            { future, continuation -> UniFFILib.ffi_askar_uniffi_rust_future_poll_pointer(future, continuation) },
            { future, continuation -> UniFFILib.ffi_askar_uniffi_rust_future_complete_pointer(future, continuation) },
            { future -> UniFFILib.ffi_askar_uniffi_rust_future_free_pointer(future) },
            // lift function
            { FfiConverterTypeAskarScan.lift(it) },
            // Error FFI converter
            ErrorCode.ErrorHandler,
        )
    }
    
    @Throws(ErrorCode::class, CancellationException::class)
    @Suppress("ASSIGNED_BUT_NEVER_ACCESSED_VARIABLE")
    override suspend fun `session`(`profile`: kotlin.String?) : AskarSession {
        return uniffiRustCallAsync(
            callWithPointer { thisPtr ->
                UniFFILib.uniffi_askar_uniffi_fn_method_askarstore_session(
                    thisPtr,
                    FfiConverterOptionalString.lower(`profile`),
                )
            },
            { future, continuation -> UniFFILib.ffi_askar_uniffi_rust_future_poll_pointer(future, continuation) },
            { future, continuation -> UniFFILib.ffi_askar_uniffi_rust_future_complete_pointer(future, continuation) },
            { future -> UniFFILib.ffi_askar_uniffi_rust_future_free_pointer(future) },
            // lift function
            { FfiConverterTypeAskarSession.lift(it) },
            // Error FFI converter
            ErrorCode.ErrorHandler,
        )
    }
    

    
    companion object
    
}

internal object FfiConverterTypeAskarStore: FfiConverter<AskarStore, Pointer> {
    override fun lower(value: AskarStore): Pointer = value.callWithPointer { it }

    override fun lift(value: Pointer): AskarStore {
        return AskarStore(value)
    }

    override fun read(buf: NoCopySource): AskarStore {
        // The Rust code always writes pointers as 8 bytes, and will
        // fail to compile if they don't fit.
        return lift(buf.readLong().toPointer())
    }

    override fun allocationSize(value: AskarStore) = 8

    override fun write(value: AskarStore, buf: Buffer) {
        // The Rust code always expects pointers written as 8 bytes,
        // and will fail to compile if they don't fit.
        buf.writeLong(lower(value).toLong())
    }
}




public interface AskarStoreManagerInterface {
    @Throws(ErrorCode::class)
    fun `generateRawStoreKey`(`seed`: kotlin.String?): kotlin.String

    @Throws(ErrorCode::class, CancellationException::class)
    suspend fun `open`(`specUri`: kotlin.String, `keyMethod`: kotlin.String?, `passKey`: kotlin.String?, `profile`: kotlin.String?): AskarStore

    @Throws(ErrorCode::class, CancellationException::class)
    suspend fun `provision`(`specUri`: kotlin.String, `keyMethod`: kotlin.String?, `passKey`: kotlin.String?, `profile`: kotlin.String?, `recreate`: kotlin.Boolean): AskarStore

    @Throws(ErrorCode::class, CancellationException::class)
    suspend fun `remove`(`specUri`: kotlin.String): kotlin.Boolean

    
    companion object
}

class AskarStoreManager internal constructor(
    pointer: Pointer
) : FFIObject(pointer), AskarStoreManagerInterface {
    constructor() :
        this(
    rustCall { _status: RustCallStatus ->
    UniFFILib.uniffi_askar_uniffi_fn_constructor_askarstoremanager_new(_status)
})

    /**
     * Disconnect the object from the underlying Rust object.
     *
     * It can be called more than once, but once called, interacting with the object
     * causes an `IllegalStateException`.
     *
     * Clients **must** call this method once done with the object, or cause a memory leak.
     */
    override protected fun freeRustArcPtr() {
        rustCall { status: RustCallStatus ->
            UniFFILib.uniffi_askar_uniffi_fn_free_askarstoremanager(this.pointer, status)
        }
    }

    
    @Throws(ErrorCode::class)override fun `generateRawStoreKey`(`seed`: kotlin.String?): kotlin.String =
        callWithPointer {
    rustCallWithError(ErrorCode) { _status: RustCallStatus ->
    UniFFILib.uniffi_askar_uniffi_fn_method_askarstoremanager_generate_raw_store_key(it, FfiConverterOptionalString.lower(`seed`), _status)
}
        }.let {
            FfiConverterString.lift(it)
        }
    
    
    @Throws(ErrorCode::class, CancellationException::class)
    @Suppress("ASSIGNED_BUT_NEVER_ACCESSED_VARIABLE")
    override suspend fun `open`(`specUri`: kotlin.String, `keyMethod`: kotlin.String?, `passKey`: kotlin.String?, `profile`: kotlin.String?) : AskarStore {
        return uniffiRustCallAsync(
            callWithPointer { thisPtr ->
                UniFFILib.uniffi_askar_uniffi_fn_method_askarstoremanager_open(
                    thisPtr,
                    FfiConverterString.lower(`specUri`),FfiConverterOptionalString.lower(`keyMethod`),FfiConverterOptionalString.lower(`passKey`),FfiConverterOptionalString.lower(`profile`),
                )
            },
            { future, continuation -> UniFFILib.ffi_askar_uniffi_rust_future_poll_pointer(future, continuation) },
            { future, continuation -> UniFFILib.ffi_askar_uniffi_rust_future_complete_pointer(future, continuation) },
            { future -> UniFFILib.ffi_askar_uniffi_rust_future_free_pointer(future) },
            // lift function
            { FfiConverterTypeAskarStore.lift(it) },
            // Error FFI converter
            ErrorCode.ErrorHandler,
        )
    }
    
    @Throws(ErrorCode::class, CancellationException::class)
    @Suppress("ASSIGNED_BUT_NEVER_ACCESSED_VARIABLE")
    override suspend fun `provision`(`specUri`: kotlin.String, `keyMethod`: kotlin.String?, `passKey`: kotlin.String?, `profile`: kotlin.String?, `recreate`: kotlin.Boolean) : AskarStore {
        return uniffiRustCallAsync(
            callWithPointer { thisPtr ->
                UniFFILib.uniffi_askar_uniffi_fn_method_askarstoremanager_provision(
                    thisPtr,
                    FfiConverterString.lower(`specUri`),FfiConverterOptionalString.lower(`keyMethod`),FfiConverterOptionalString.lower(`passKey`),FfiConverterOptionalString.lower(`profile`),FfiConverterBoolean.lower(`recreate`),
                )
            },
            { future, continuation -> UniFFILib.ffi_askar_uniffi_rust_future_poll_pointer(future, continuation) },
            { future, continuation -> UniFFILib.ffi_askar_uniffi_rust_future_complete_pointer(future, continuation) },
            { future -> UniFFILib.ffi_askar_uniffi_rust_future_free_pointer(future) },
            // lift function
            { FfiConverterTypeAskarStore.lift(it) },
            // Error FFI converter
            ErrorCode.ErrorHandler,
        )
    }
    
    @Throws(ErrorCode::class, CancellationException::class)
    @Suppress("ASSIGNED_BUT_NEVER_ACCESSED_VARIABLE")
    override suspend fun `remove`(`specUri`: kotlin.String) : kotlin.Boolean {
        return uniffiRustCallAsync(
            callWithPointer { thisPtr ->
                UniFFILib.uniffi_askar_uniffi_fn_method_askarstoremanager_remove(
                    thisPtr,
                    FfiConverterString.lower(`specUri`),
                )
            },
            { future, continuation -> UniFFILib.ffi_askar_uniffi_rust_future_poll_i8(future, continuation) },
            { future, continuation -> UniFFILib.ffi_askar_uniffi_rust_future_complete_i8(future, continuation) },
            { future -> UniFFILib.ffi_askar_uniffi_rust_future_free_i8(future) },
            // lift function
            { FfiConverterBoolean.lift(it) },
            // Error FFI converter
            ErrorCode.ErrorHandler,
        )
    }
    

    
    companion object
    
}

internal object FfiConverterTypeAskarStoreManager: FfiConverter<AskarStoreManager, Pointer> {
    override fun lower(value: AskarStoreManager): Pointer = value.callWithPointer { it }

    override fun lift(value: Pointer): AskarStoreManager {
        return AskarStoreManager(value)
    }

    override fun read(buf: NoCopySource): AskarStoreManager {
        // The Rust code always writes pointers as 8 bytes, and will
        // fail to compile if they don't fit.
        return lift(buf.readLong().toPointer())
    }

    override fun allocationSize(value: AskarStoreManager) = 8

    override fun write(value: AskarStoreManager, buf: Buffer) {
        // The Rust code always expects pointers written as 8 bytes,
        // and will fail to compile if they don't fit.
        buf.writeLong(lower(value).toLong())
    }
}




public interface EncryptedBufferInterface {
    
    fun `ciphertext`(): kotlin.ByteArray

    
    fun `ciphertextTag`(): kotlin.ByteArray

    
    fun `nonce`(): kotlin.ByteArray

    
    fun `tag`(): kotlin.ByteArray

    
    companion object
}

class EncryptedBuffer internal constructor(
    pointer: Pointer
) : FFIObject(pointer), EncryptedBufferInterface {

    /**
     * Disconnect the object from the underlying Rust object.
     *
     * It can be called more than once, but once called, interacting with the object
     * causes an `IllegalStateException`.
     *
     * Clients **must** call this method once done with the object, or cause a memory leak.
     */
    override protected fun freeRustArcPtr() {
        rustCall { status: RustCallStatus ->
            UniFFILib.uniffi_askar_uniffi_fn_free_encryptedbuffer(this.pointer, status)
        }
    }

    override fun `ciphertext`(): kotlin.ByteArray =
        callWithPointer {
    rustCall { _status: RustCallStatus ->
    UniFFILib.uniffi_askar_uniffi_fn_method_encryptedbuffer_ciphertext(it,  _status)
}
        }.let {
            FfiConverterByteArray.lift(it)
        }
    
    override fun `ciphertextTag`(): kotlin.ByteArray =
        callWithPointer {
    rustCall { _status: RustCallStatus ->
    UniFFILib.uniffi_askar_uniffi_fn_method_encryptedbuffer_ciphertext_tag(it,  _status)
}
        }.let {
            FfiConverterByteArray.lift(it)
        }
    
    override fun `nonce`(): kotlin.ByteArray =
        callWithPointer {
    rustCall { _status: RustCallStatus ->
    UniFFILib.uniffi_askar_uniffi_fn_method_encryptedbuffer_nonce(it,  _status)
}
        }.let {
            FfiConverterByteArray.lift(it)
        }
    
    override fun `tag`(): kotlin.ByteArray =
        callWithPointer {
    rustCall { _status: RustCallStatus ->
    UniFFILib.uniffi_askar_uniffi_fn_method_encryptedbuffer_tag(it,  _status)
}
        }.let {
            FfiConverterByteArray.lift(it)
        }
    
    

    
    companion object
    
}

internal object FfiConverterTypeEncryptedBuffer: FfiConverter<EncryptedBuffer, Pointer> {
    override fun lower(value: EncryptedBuffer): Pointer = value.callWithPointer { it }

    override fun lift(value: Pointer): EncryptedBuffer {
        return EncryptedBuffer(value)
    }

    override fun read(buf: NoCopySource): EncryptedBuffer {
        // The Rust code always writes pointers as 8 bytes, and will
        // fail to compile if they don't fit.
        return lift(buf.readLong().toPointer())
    }

    override fun allocationSize(value: EncryptedBuffer) = 8

    override fun write(value: EncryptedBuffer, buf: Buffer) {
        // The Rust code always expects pointers written as 8 bytes,
        // and will fail to compile if they don't fit.
        buf.writeLong(lower(value).toLong())
    }
}




public interface LocalKeyFactoryInterface {
    @Throws(ErrorCode::class)
    fun `fromJwk`(`jwk`: kotlin.String): AskarLocalKey

    @Throws(ErrorCode::class)
    fun `fromJwkSlice`(`jwk`: kotlin.ByteArray): AskarLocalKey

    @Throws(ErrorCode::class)
    fun `fromPublicBytes`(`alg`: AskarKeyAlg, `bytes`: kotlin.ByteArray): AskarLocalKey

    @Throws(ErrorCode::class)
    fun `fromSecretBytes`(`alg`: AskarKeyAlg, `bytes`: kotlin.ByteArray): AskarLocalKey

    @Throws(ErrorCode::class)
    fun `fromSeed`(`alg`: AskarKeyAlg, `seed`: kotlin.ByteArray, `method`: SeedMethod?): AskarLocalKey

    @Throws(ErrorCode::class)
    fun `generate`(`alg`: AskarKeyAlg, `ephemeral`: kotlin.Boolean): AskarLocalKey

    
    companion object
}

class LocalKeyFactory internal constructor(
    pointer: Pointer
) : FFIObject(pointer), LocalKeyFactoryInterface {
    constructor() :
        this(
    rustCall { _status: RustCallStatus ->
    UniFFILib.uniffi_askar_uniffi_fn_constructor_localkeyfactory_new(_status)
})

    /**
     * Disconnect the object from the underlying Rust object.
     *
     * It can be called more than once, but once called, interacting with the object
     * causes an `IllegalStateException`.
     *
     * Clients **must** call this method once done with the object, or cause a memory leak.
     */
    override protected fun freeRustArcPtr() {
        rustCall { status: RustCallStatus ->
            UniFFILib.uniffi_askar_uniffi_fn_free_localkeyfactory(this.pointer, status)
        }
    }

    
    @Throws(ErrorCode::class)override fun `fromJwk`(`jwk`: kotlin.String): AskarLocalKey =
        callWithPointer {
    rustCallWithError(ErrorCode) { _status: RustCallStatus ->
    UniFFILib.uniffi_askar_uniffi_fn_method_localkeyfactory_from_jwk(it, FfiConverterString.lower(`jwk`), _status)
}
        }.let {
            FfiConverterTypeAskarLocalKey.lift(it)
        }
    
    
    @Throws(ErrorCode::class)override fun `fromJwkSlice`(`jwk`: kotlin.ByteArray): AskarLocalKey =
        callWithPointer {
    rustCallWithError(ErrorCode) { _status: RustCallStatus ->
    UniFFILib.uniffi_askar_uniffi_fn_method_localkeyfactory_from_jwk_slice(it, FfiConverterByteArray.lower(`jwk`), _status)
}
        }.let {
            FfiConverterTypeAskarLocalKey.lift(it)
        }
    
    
    @Throws(ErrorCode::class)override fun `fromPublicBytes`(`alg`: AskarKeyAlg, `bytes`: kotlin.ByteArray): AskarLocalKey =
        callWithPointer {
    rustCallWithError(ErrorCode) { _status: RustCallStatus ->
    UniFFILib.uniffi_askar_uniffi_fn_method_localkeyfactory_from_public_bytes(it, FfiConverterTypeAskarKeyAlg.lower(`alg`),FfiConverterByteArray.lower(`bytes`), _status)
}
        }.let {
            FfiConverterTypeAskarLocalKey.lift(it)
        }
    
    
    @Throws(ErrorCode::class)override fun `fromSecretBytes`(`alg`: AskarKeyAlg, `bytes`: kotlin.ByteArray): AskarLocalKey =
        callWithPointer {
    rustCallWithError(ErrorCode) { _status: RustCallStatus ->
    UniFFILib.uniffi_askar_uniffi_fn_method_localkeyfactory_from_secret_bytes(it, FfiConverterTypeAskarKeyAlg.lower(`alg`),FfiConverterByteArray.lower(`bytes`), _status)
}
        }.let {
            FfiConverterTypeAskarLocalKey.lift(it)
        }
    
    
    @Throws(ErrorCode::class)override fun `fromSeed`(`alg`: AskarKeyAlg, `seed`: kotlin.ByteArray, `method`: SeedMethod?): AskarLocalKey =
        callWithPointer {
    rustCallWithError(ErrorCode) { _status: RustCallStatus ->
    UniFFILib.uniffi_askar_uniffi_fn_method_localkeyfactory_from_seed(it, FfiConverterTypeAskarKeyAlg.lower(`alg`),FfiConverterByteArray.lower(`seed`),FfiConverterOptionalTypeSeedMethod.lower(`method`), _status)
}
        }.let {
            FfiConverterTypeAskarLocalKey.lift(it)
        }
    
    
    @Throws(ErrorCode::class)override fun `generate`(`alg`: AskarKeyAlg, `ephemeral`: kotlin.Boolean): AskarLocalKey =
        callWithPointer {
    rustCallWithError(ErrorCode) { _status: RustCallStatus ->
    UniFFILib.uniffi_askar_uniffi_fn_method_localkeyfactory_generate(it, FfiConverterTypeAskarKeyAlg.lower(`alg`),FfiConverterBoolean.lower(`ephemeral`), _status)
}
        }.let {
            FfiConverterTypeAskarLocalKey.lift(it)
        }
    
    

    
    companion object
    
}

internal object FfiConverterTypeLocalKeyFactory: FfiConverter<LocalKeyFactory, Pointer> {
    override fun lower(value: LocalKeyFactory): Pointer = value.callWithPointer { it }

    override fun lift(value: Pointer): LocalKeyFactory {
        return LocalKeyFactory(value)
    }

    override fun read(buf: NoCopySource): LocalKeyFactory {
        // The Rust code always writes pointers as 8 bytes, and will
        // fail to compile if they don't fit.
        return lift(buf.readLong().toPointer())
    }

    override fun allocationSize(value: LocalKeyFactory) = 8

    override fun write(value: LocalKeyFactory, buf: Buffer) {
        // The Rust code always expects pointers written as 8 bytes,
        // and will fail to compile if they don't fit.
        buf.writeLong(lower(value).toLong())
    }
}




public data class AeadParams (
    var `nonceLength`: kotlin.Int, 
    var `tagLength`: kotlin.Int
) {
    
    companion object
}

internal object FfiConverterTypeAeadParams: FfiConverterRustBuffer<AeadParams> {
    override fun read(buf: NoCopySource): AeadParams {
        return AeadParams(
            FfiConverterInt.read(buf),
            FfiConverterInt.read(buf),
        )
    }

    override fun allocationSize(value: AeadParams) = (
            FfiConverterInt.allocationSize(value.`nonceLength`) +
            FfiConverterInt.allocationSize(value.`tagLength`)
    )

    override fun write(value: AeadParams, buf: Buffer) {
            FfiConverterInt.write(value.`nonceLength`, buf)
            FfiConverterInt.write(value.`tagLength`, buf)
    }
}




enum class AskarEntryOperation {
    INSERT,REPLACE,REMOVE;
    companion object
}

internal object FfiConverterTypeAskarEntryOperation: FfiConverterRustBuffer<AskarEntryOperation> {
    override fun read(buf: NoCopySource) = try {
        AskarEntryOperation.values()[buf.readInt() - 1]
    } catch (e: IndexOutOfBoundsException) {
        throw RuntimeException("invalid enum value, something is very wrong!!", e)
    }

    override fun allocationSize(value: AskarEntryOperation) = 4

    override fun write(value: AskarEntryOperation, buf: Buffer) {
        buf.writeInt(value.ordinal + 1)
    }
}






enum class AskarKeyAlg {
    A128_GCM,A256_GCM,A128_CBC_HS256,A256_CBC_HS512,A128_KW,A256_KW,BLS12_381G1,BLS12_381G2,BLS12_381G1G2,C20P,XC20P,ED25519,X25519,K256,P256,P384;
    companion object
}

internal object FfiConverterTypeAskarKeyAlg: FfiConverterRustBuffer<AskarKeyAlg> {
    override fun read(buf: NoCopySource) = try {
        AskarKeyAlg.values()[buf.readInt() - 1]
    } catch (e: IndexOutOfBoundsException) {
        throw RuntimeException("invalid enum value, something is very wrong!!", e)
    }

    override fun allocationSize(value: AskarKeyAlg) = 4

    override fun write(value: AskarKeyAlg, buf: Buffer) {
        buf.writeInt(value.ordinal + 1)
    }
}







sealed class ErrorCode: Exception() {
    
class Backend(override val message: kotlin.String): ErrorCode()
    
class Busy(override val message: kotlin.String): ErrorCode()
    
class Duplicate(override val message: kotlin.String): ErrorCode()
    
class Encryption(override val message: kotlin.String): ErrorCode()
    
class Input(override val message: kotlin.String): ErrorCode()
    
class NotFound(override val message: kotlin.String): ErrorCode()
    
class Unexpected(override val message: kotlin.String): ErrorCode()
    
class Unsupported(override val message: kotlin.String): ErrorCode()
    
class Custom(override val message: kotlin.String): ErrorCode()
    

    internal companion object ErrorHandler : CallStatusErrorHandler<ErrorCode> {
        override fun lift(errorBuffer: RustBuffer): ErrorCode = FfiConverterTypeErrorCode.lift(errorBuffer)
    }

    
}

internal object FfiConverterTypeErrorCode : FfiConverterRustBuffer<ErrorCode> {
    override fun read(buf: NoCopySource): ErrorCode {
        

        return when(buf.readInt()) {
            1 -> ErrorCode.Backend(
                FfiConverterString.read(buf),
                )
            2 -> ErrorCode.Busy(
                FfiConverterString.read(buf),
                )
            3 -> ErrorCode.Duplicate(
                FfiConverterString.read(buf),
                )
            4 -> ErrorCode.Encryption(
                FfiConverterString.read(buf),
                )
            5 -> ErrorCode.Input(
                FfiConverterString.read(buf),
                )
            6 -> ErrorCode.NotFound(
                FfiConverterString.read(buf),
                )
            7 -> ErrorCode.Unexpected(
                FfiConverterString.read(buf),
                )
            8 -> ErrorCode.Unsupported(
                FfiConverterString.read(buf),
                )
            9 -> ErrorCode.Custom(
                FfiConverterString.read(buf),
                )
            else -> throw RuntimeException("invalid error enum value, something is very wrong!!")
        }
    }

    override fun allocationSize(value: ErrorCode): kotlin.Int {
        return when(value) {
            is ErrorCode.Backend -> (
                // Add the size for the Int that specifies the variant plus the size needed for all fields
                4
                + FfiConverterString.allocationSize(value.`message`)
            )
            is ErrorCode.Busy -> (
                // Add the size for the Int that specifies the variant plus the size needed for all fields
                4
                + FfiConverterString.allocationSize(value.`message`)
            )
            is ErrorCode.Duplicate -> (
                // Add the size for the Int that specifies the variant plus the size needed for all fields
                4
                + FfiConverterString.allocationSize(value.`message`)
            )
            is ErrorCode.Encryption -> (
                // Add the size for the Int that specifies the variant plus the size needed for all fields
                4
                + FfiConverterString.allocationSize(value.`message`)
            )
            is ErrorCode.Input -> (
                // Add the size for the Int that specifies the variant plus the size needed for all fields
                4
                + FfiConverterString.allocationSize(value.`message`)
            )
            is ErrorCode.NotFound -> (
                // Add the size for the Int that specifies the variant plus the size needed for all fields
                4
                + FfiConverterString.allocationSize(value.`message`)
            )
            is ErrorCode.Unexpected -> (
                // Add the size for the Int that specifies the variant plus the size needed for all fields
                4
                + FfiConverterString.allocationSize(value.`message`)
            )
            is ErrorCode.Unsupported -> (
                // Add the size for the Int that specifies the variant plus the size needed for all fields
                4
                + FfiConverterString.allocationSize(value.`message`)
            )
            is ErrorCode.Custom -> (
                // Add the size for the Int that specifies the variant plus the size needed for all fields
                4
                + FfiConverterString.allocationSize(value.`message`)
            )
        }
    }

    override fun write(value: ErrorCode, buf: Buffer) {
        when(value) {
            is ErrorCode.Backend -> {
                buf.writeInt(1)
                FfiConverterString.write(value.`message`, buf)
                Unit
            }
            is ErrorCode.Busy -> {
                buf.writeInt(2)
                FfiConverterString.write(value.`message`, buf)
                Unit
            }
            is ErrorCode.Duplicate -> {
                buf.writeInt(3)
                FfiConverterString.write(value.`message`, buf)
                Unit
            }
            is ErrorCode.Encryption -> {
                buf.writeInt(4)
                FfiConverterString.write(value.`message`, buf)
                Unit
            }
            is ErrorCode.Input -> {
                buf.writeInt(5)
                FfiConverterString.write(value.`message`, buf)
                Unit
            }
            is ErrorCode.NotFound -> {
                buf.writeInt(6)
                FfiConverterString.write(value.`message`, buf)
                Unit
            }
            is ErrorCode.Unexpected -> {
                buf.writeInt(7)
                FfiConverterString.write(value.`message`, buf)
                Unit
            }
            is ErrorCode.Unsupported -> {
                buf.writeInt(8)
                FfiConverterString.write(value.`message`, buf)
                Unit
            }
            is ErrorCode.Custom -> {
                buf.writeInt(9)
                FfiConverterString.write(value.`message`, buf)
                Unit
            }
        }
    }

}




enum class SeedMethod {
    BLS_KEY_GEN;
    companion object
}

internal object FfiConverterTypeSeedMethod: FfiConverterRustBuffer<SeedMethod> {
    override fun read(buf: NoCopySource) = try {
        SeedMethod.values()[buf.readInt() - 1]
    } catch (e: IndexOutOfBoundsException) {
        throw RuntimeException("invalid enum value, something is very wrong!!", e)
    }

    override fun allocationSize(value: SeedMethod) = 4

    override fun write(value: SeedMethod, buf: Buffer) {
        buf.writeInt(value.ordinal + 1)
    }
}






internal object FfiConverterOptionalLong: FfiConverterRustBuffer<kotlin.Long?> {
    override fun read(buf: NoCopySource): kotlin.Long? {
        if (buf.readByte().toInt() == 0) {
            return null
        }
        return FfiConverterLong.read(buf)
    }

    override fun allocationSize(value: kotlin.Long?): kotlin.Int {
        if (value == null) {
            return 1
        } else {
            return 1 + FfiConverterLong.allocationSize(value)
        }
    }

    override fun write(value: kotlin.Long?, buf: Buffer) {
        if (value == null) {
            buf.writeByte(0)
        } else {
            buf.writeByte(1)
            FfiConverterLong.write(value, buf)
        }
    }
}




internal object FfiConverterOptionalString: FfiConverterRustBuffer<kotlin.String?> {
    override fun read(buf: NoCopySource): kotlin.String? {
        if (buf.readByte().toInt() == 0) {
            return null
        }
        return FfiConverterString.read(buf)
    }

    override fun allocationSize(value: kotlin.String?): kotlin.Int {
        if (value == null) {
            return 1
        } else {
            return 1 + FfiConverterString.allocationSize(value)
        }
    }

    override fun write(value: kotlin.String?, buf: Buffer) {
        if (value == null) {
            buf.writeByte(0)
        } else {
            buf.writeByte(1)
            FfiConverterString.write(value, buf)
        }
    }
}




internal object FfiConverterOptionalByteArray: FfiConverterRustBuffer<kotlin.ByteArray?> {
    override fun read(buf: NoCopySource): kotlin.ByteArray? {
        if (buf.readByte().toInt() == 0) {
            return null
        }
        return FfiConverterByteArray.read(buf)
    }

    override fun allocationSize(value: kotlin.ByteArray?): kotlin.Int {
        if (value == null) {
            return 1
        } else {
            return 1 + FfiConverterByteArray.allocationSize(value)
        }
    }

    override fun write(value: kotlin.ByteArray?, buf: Buffer) {
        if (value == null) {
            buf.writeByte(0)
        } else {
            buf.writeByte(1)
            FfiConverterByteArray.write(value, buf)
        }
    }
}




internal object FfiConverterOptionalTypeAskarEntry: FfiConverterRustBuffer<AskarEntry?> {
    override fun read(buf: NoCopySource): AskarEntry? {
        if (buf.readByte().toInt() == 0) {
            return null
        }
        return FfiConverterTypeAskarEntry.read(buf)
    }

    override fun allocationSize(value: AskarEntry?): kotlin.Int {
        if (value == null) {
            return 1
        } else {
            return 1 + FfiConverterTypeAskarEntry.allocationSize(value)
        }
    }

    override fun write(value: AskarEntry?, buf: Buffer) {
        if (value == null) {
            buf.writeByte(0)
        } else {
            buf.writeByte(1)
            FfiConverterTypeAskarEntry.write(value, buf)
        }
    }
}




internal object FfiConverterOptionalTypeAskarKeyEntry: FfiConverterRustBuffer<AskarKeyEntry?> {
    override fun read(buf: NoCopySource): AskarKeyEntry? {
        if (buf.readByte().toInt() == 0) {
            return null
        }
        return FfiConverterTypeAskarKeyEntry.read(buf)
    }

    override fun allocationSize(value: AskarKeyEntry?): kotlin.Int {
        if (value == null) {
            return 1
        } else {
            return 1 + FfiConverterTypeAskarKeyEntry.allocationSize(value)
        }
    }

    override fun write(value: AskarKeyEntry?, buf: Buffer) {
        if (value == null) {
            buf.writeByte(0)
        } else {
            buf.writeByte(1)
            FfiConverterTypeAskarKeyEntry.write(value, buf)
        }
    }
}




internal object FfiConverterOptionalTypeAskarKeyAlg: FfiConverterRustBuffer<AskarKeyAlg?> {
    override fun read(buf: NoCopySource): AskarKeyAlg? {
        if (buf.readByte().toInt() == 0) {
            return null
        }
        return FfiConverterTypeAskarKeyAlg.read(buf)
    }

    override fun allocationSize(value: AskarKeyAlg?): kotlin.Int {
        if (value == null) {
            return 1
        } else {
            return 1 + FfiConverterTypeAskarKeyAlg.allocationSize(value)
        }
    }

    override fun write(value: AskarKeyAlg?, buf: Buffer) {
        if (value == null) {
            buf.writeByte(0)
        } else {
            buf.writeByte(1)
            FfiConverterTypeAskarKeyAlg.write(value, buf)
        }
    }
}




internal object FfiConverterOptionalTypeSeedMethod: FfiConverterRustBuffer<SeedMethod?> {
    override fun read(buf: NoCopySource): SeedMethod? {
        if (buf.readByte().toInt() == 0) {
            return null
        }
        return FfiConverterTypeSeedMethod.read(buf)
    }

    override fun allocationSize(value: SeedMethod?): kotlin.Int {
        if (value == null) {
            return 1
        } else {
            return 1 + FfiConverterTypeSeedMethod.allocationSize(value)
        }
    }

    override fun write(value: SeedMethod?, buf: Buffer) {
        if (value == null) {
            buf.writeByte(0)
        } else {
            buf.writeByte(1)
            FfiConverterTypeSeedMethod.write(value, buf)
        }
    }
}




internal object FfiConverterOptionalSequenceTypeAskarEntry: FfiConverterRustBuffer<List<AskarEntry>?> {
    override fun read(buf: NoCopySource): List<AskarEntry>? {
        if (buf.readByte().toInt() == 0) {
            return null
        }
        return FfiConverterSequenceTypeAskarEntry.read(buf)
    }

    override fun allocationSize(value: List<AskarEntry>?): kotlin.Int {
        if (value == null) {
            return 1
        } else {
            return 1 + FfiConverterSequenceTypeAskarEntry.allocationSize(value)
        }
    }

    override fun write(value: List<AskarEntry>?, buf: Buffer) {
        if (value == null) {
            buf.writeByte(0)
        } else {
            buf.writeByte(1)
            FfiConverterSequenceTypeAskarEntry.write(value, buf)
        }
    }
}




internal object FfiConverterSequenceString: FfiConverterRustBuffer<List<kotlin.String>> {
    override fun read(buf: NoCopySource): List<kotlin.String> {
        val len = buf.readInt()
        return List<kotlin.String>(len) {
            FfiConverterString.read(buf)
        }
    }

    override fun allocationSize(value: List<kotlin.String>): kotlin.Int {
        val sizeForLength = 4
        val sizeForItems = value.map { FfiConverterString.allocationSize(it) }.sum()
        return sizeForLength + sizeForItems
    }

    override fun write(value: List<kotlin.String>, buf: Buffer) {
        buf.writeInt(value.size)
        value.forEach {
            FfiConverterString.write(it, buf)
        }
    }
}




internal object FfiConverterSequenceTypeAskarEntry: FfiConverterRustBuffer<List<AskarEntry>> {
    override fun read(buf: NoCopySource): List<AskarEntry> {
        val len = buf.readInt()
        return List<AskarEntry>(len) {
            FfiConverterTypeAskarEntry.read(buf)
        }
    }

    override fun allocationSize(value: List<AskarEntry>): kotlin.Int {
        val sizeForLength = 4
        val sizeForItems = value.map { FfiConverterTypeAskarEntry.allocationSize(it) }.sum()
        return sizeForLength + sizeForItems
    }

    override fun write(value: List<AskarEntry>, buf: Buffer) {
        buf.writeInt(value.size)
        value.forEach {
            FfiConverterTypeAskarEntry.write(it, buf)
        }
    }
}




internal object FfiConverterSequenceTypeAskarKeyEntry: FfiConverterRustBuffer<List<AskarKeyEntry>> {
    override fun read(buf: NoCopySource): List<AskarKeyEntry> {
        val len = buf.readInt()
        return List<AskarKeyEntry>(len) {
            FfiConverterTypeAskarKeyEntry.read(buf)
        }
    }

    override fun allocationSize(value: List<AskarKeyEntry>): kotlin.Int {
        val sizeForLength = 4
        val sizeForItems = value.map { FfiConverterTypeAskarKeyEntry.allocationSize(it) }.sum()
        return sizeForLength + sizeForItems
    }

    override fun write(value: List<AskarKeyEntry>, buf: Buffer) {
        buf.writeInt(value.size)
        value.forEach {
            FfiConverterTypeAskarKeyEntry.write(it, buf)
        }
    }
}



internal object FfiConverterMapStringString: FfiConverterRustBuffer<Map<kotlin.String, kotlin.String>> {
    override fun read(buf: NoCopySource): Map<kotlin.String, kotlin.String> {
        val len = buf.readInt()
        return buildMap<kotlin.String, kotlin.String>(len) {
            repeat(len) {
                val k = FfiConverterString.read(buf)
                val v = FfiConverterString.read(buf)
                this[k] = v
            }
        }
    }

    override fun allocationSize(value: Map<kotlin.String, kotlin.String>): kotlin.Int {
        val spaceForMapSize = 4
        val spaceForChildren = value.map { (k, v) ->
            FfiConverterString.allocationSize(k) +
            FfiConverterString.allocationSize(v)
        }.sum()
        return spaceForMapSize + spaceForChildren
    }

    override fun write(value: Map<kotlin.String, kotlin.String>, buf: Buffer) {
        buf.writeInt(value.size)
        value.forEach { (k, v) ->
            FfiConverterString.write(k, buf)
            FfiConverterString.write(v, buf)
        }
    }
}




 
@Throws(ErrorCode::class)

public fun `setDefaultLogger`() =
    
    rustCallWithError(ErrorCode) { _status: RustCallStatus ->
    UniFFILib.uniffi_askar_uniffi_fn_func_set_default_logger(_status)
}



