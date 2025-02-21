package br.org.serpro.did_agent

import android.content.Context
import android.content.SharedPreferences
import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import org.hyperledger.ariesframework.agent.Agent
import org.hyperledger.ariesframework.agent.AgentConfig
import org.hyperledger.ariesframework.agent.MediatorPickupStrategy
import org.hyperledger.ariesframework.credentials.models.AutoAcceptCredential
import org.hyperledger.ariesframework.proofs.models.AutoAcceptProof
import java.lang.Exception


class MainActivity: FlutterFragmentActivity() {
    companion object {
        private const val INTEGRITYCHANNEL = "br.gov.serprocpqd/wallet"
    }
    private var agent: Agent? = null

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

         val sharedPreferences: SharedPreferences = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
         var key: String? = sharedPreferences.getString("flutter.walletKey", null)

         if (key == null) {
            try {
                key = Agent.generateWalletKey()
                sharedPreferences.edit().putString("flutter.walletKey", key).apply()
            } catch (e: Exception) {
                Log.e("MainActivity", "Cannot generate key: ${e.message}")
                result.error("1", "Cannot generate key: ${e.message}", null)
                return
            }
        }

         val invitationUrl = "https://blockchain.cpqd.com.br/cpqdid/agent-mediator-endpoint-com?c_i=eyJAdHlwZSI6ICJkaWQ6c292OkJ6Q2JzTlloTXJqSGlxWkRUVUFTSGc7c3BlYy9jb25uZWN0aW9ucy8xLjAvaW52aXRhdGlvbiIsICJAaWQiOiAiMGEyYzc4MTYtMGYxZC00OTc3LTg5YzAtMGE0NmNhNTg4Nzk0IiwgInJlY2lwaWVudEtleXMiOiBbIjRFVFhHZGM3UjJzYVBzZktZR1g1dU15dDNFWU5aQVdyejJpN3VXbnN0eGJkIl0sICJsYWJlbCI6ICJNZWRpYWRvciBTT1UgaUQiLCAic2VydmljZUVuZHBvaW50IjogImh0dHBzOi8vYmxvY2tjaGFpbi5jcHFkLmNvbS5ici9jcHFkaWQvYWdlbnQtbWVkaWF0b3ItZW5kcG9pbnQtY29tIn0="
         val genesisPath = assets.open("bcovrin-genesis.txn").bufferedReader().use { it.readText() }

         val config = AgentConfig(
            walletKey = key,
            genesisPath = genesisPath,
            mediatorConnectionsInvite = invitationUrl,
            mediatorPickupStrategy = MediatorPickupStrategy.Implicit,
            label = "SampleApp",
            autoAcceptCredential = AutoAcceptCredential.Never,
            autoAcceptProof = AutoAcceptProof.Never
        )

        CoroutineScope(Dispatchers.Main).launch {
            try {
                agent = Agent(applicationContext, config)
                agent?.initialize()
                val response = mapOf("error" to "", "result" to true)
                result.success(response)
            } catch (e: Exception) {
                Log.e("MainActivity", "Cannot initialize agent: ${e.message}")
                val response = mapOf("error" to e.message, "result" to false)
                result.success(response)
            }
        }
    }
}