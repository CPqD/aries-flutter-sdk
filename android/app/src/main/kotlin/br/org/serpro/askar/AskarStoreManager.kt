package br.org.serpro.did_agent.askar

import android.util.Log
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CancellationException
import br.org.serpro.did_agent.askar.ErrorCodeException
import br.org.serpro.did_agent.askar.AskarStore

class AskarStoreManager {
     companion object {
        private var flutterEngine: FlutterEngine? = null

        fun initialize(flutterEngine: FlutterEngine) {
            this.flutterEngine = flutterEngine
        }

        private val channel: MethodChannel by lazy {
            MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, "br.gov.serprocpqd/wallet/askar")
        }
    }

    @Throws(ErrorCodeException::class)
    fun generateRawStoreKey(seed: String?): String {
        val data = mapOf("seed" to seed)
        var generatedKey = seed ?: "defaultRawStoreKey"

        channel.invokeMethod("AskarStoreManager_generateRawStoreKey", data, object : MethodChannel.Result {
            override fun success(result: Any?) {
                if (result is String) {
                    Log.d("AskarStoreManager", result)
                    generatedKey = result
                }
            }

            override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                Log.e("AskarStoreManager", "Error: $errorMessage")
            }

            override fun notImplemented() {
                Log.e("AskarStoreManager", "Method not implemented")
            }
        })

        return generatedKey
    }

    @Throws(ErrorCodeException::class, CancellationException::class)
    suspend fun open(specUri: String, keyMethod: String?, passKey: String?, profile: String?): AskarStore {
        // Implement the logic to open the Askar store
        return AskarStore(specUri, keyMethod, passKey, profile)
    }

    @Throws(ErrorCodeException::class, CancellationException::class)
    suspend fun provision(specUri: String, keyMethod: String?, passKey: String?, profile: String?, recreate: Boolean): AskarStore {
        // Implement the logic to provision the Askar store
        return AskarStore(specUri, keyMethod, passKey, profile)
    }

    @Throws(ErrorCodeException::class, CancellationException::class)
    suspend fun remove(specUri: String): Boolean {
        // Implement the logic to remove the Askar store
        return true
    }
}
