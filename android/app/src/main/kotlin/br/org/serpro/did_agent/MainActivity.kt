package br.org.serpro.did_agent

import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant


class MainActivity: FlutterFragmentActivity() {
    companion object {
        private const val INTEGRITYCHANNEL = "br.gov.serprocpqd/wallet"

    }
    private var result: MethodChannel.Result? = null
    private lateinit var resultCallback: MethodChannel.Result

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, INTEGRITYCHANNEL).setMethodCallHandler {
                call, result ->
            when (call.method) {
                "openwallet" -> {
                    try {
                        openWallet(result)
                    }catch (e:Exception){
                        result?.error("1","Erro ao processar o methodchannel openwallet: "+e.toString(),null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        
    }
    
    private fun openWallet(result: MethodChannel.Result) {
        Log.d("MainActivity", "openWallet called from Kotlin...")

        val response = mapOf("success" to true)
        result.success(response)
    }
}