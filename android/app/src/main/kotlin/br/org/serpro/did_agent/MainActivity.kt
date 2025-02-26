package br.org.serpro.did_agent

import androidx.lifecycle.lifecycleScope
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
import java.io.File
import java.lang.Exception

const val genesisPath = "bcovrin-genesis.txn"

class MainActivity: FlutterFragmentActivity() {
    companion object {
        private const val INTEGRITYCHANNEL = "br.gov.serprocpqd/wallet"
    }
    private var agent: Agent? = null
    private var walletKey: String? = null

    private var result: MethodChannel.Result? = null
    private lateinit var resultCallback: MethodChannel.Result

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, INTEGRITYCHANNEL).setMethodCallHandler {
                call, result ->
            when (call.method) {
                "init" -> {
                    try {
                        init(result)
                    }catch (e:Exception){
                        result?.error("1","Erro ao inicializar agente: "+e.toString(),null)
                    }
                }
                "openwallet" -> {
                    try {
                        openWallet(result)
                    }catch (e:Exception){
                        result?.error("1","Erro ao processar o methodchannel openwallet: "+e.toString(),null)
                    }
                }
                "receiveInvitation" -> {
                    try {
                        val invitationUrl = call.argument<String>("invitationUrl")
                        receiveInvitation(invitationUrl, result)
                    }catch (e:Exception){
                        result?.error("1","Erro ao processar o methodchannel receiveInvitation: "+e.toString(),null)
                    }
                }
                "shutdown" -> {
                    try {
                        shutdown(result)
                    }catch (e:Exception){
                        result?.error("1","Erro ao processar o methodchannel shutdown: "+e.toString(),null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        
    }

    private fun init(result: MethodChannel.Result) {
        Log.d("MainActivity", "init called from Kotlin...")

        try {
           copyResourceFile(genesisPath)
        } catch (e: Exception) {
            Log.e("MainActivity", "Cannot open genesis: ${e.message}")
            result.error("1", "Cannot open genesis: ${e.message}", null)
            return
        }

        result.success(mapOf("error" to "", "result" to true))
    }

    private fun copyResourceFile(resource: String) {
        val inputStream = applicationContext.assets.open(resource)
        val file = File(applicationContext.filesDir.absolutePath, resource)
        file.outputStream().use { inputStream.copyTo(it) }
    }

     private fun openWallet(result: MethodChannel.Result) {
        Log.d("MainActivity", "openWallet called from Kotlin...")

         val sharedPreferences: SharedPreferences = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
         walletKey = sharedPreferences.getString("flutter.walletKey", null)

         if (walletKey == null) {
            try {
                walletKey = Agent.generateWalletKey()
                sharedPreferences.edit().putString("flutter.walletKey", walletKey).apply()

                Log.d("MainActivity", "Key was generated successfully")
            } catch (e: Exception) {
                Log.e("MainActivity", "Cannot generate key: ${e.message}")
                result.error("1", "Cannot generate key: ${e.message}", null)
                return
            }
        }

         val invitationUrl = "https://blockchain.cpqd.com.br/cpqdid/agent-mediator-endpoint-com?c_i=eyJAdHlwZSI6ICJkaWQ6c292OkJ6Q2JzTlloTXJqSGlxWkRUVUFTSGc7c3BlYy9jb25uZWN0aW9ucy8xLjAvaW52aXRhdGlvbiIsICJAaWQiOiAiMGEyYzc4MTYtMGYxZC00OTc3LTg5YzAtMGE0NmNhNTg4Nzk0IiwgInJlY2lwaWVudEtleXMiOiBbIjRFVFhHZGM3UjJzYVBzZktZR1g1dU15dDNFWU5aQVdyejJpN3VXbnN0eGJkIl0sICJsYWJlbCI6ICJNZWRpYWRvciBTT1UgaUQiLCAic2VydmljZUVuZHBvaW50IjogImh0dHBzOi8vYmxvY2tjaGFpbi5jcHFkLmNvbS5ici9jcHFkaWQvYWdlbnQtbWVkaWF0b3ItZW5kcG9pbnQtY29tIn0="

         val config = AgentConfig(
            walletKey = walletKey!!,
            genesisPath = File(applicationContext.filesDir.absolutePath, genesisPath).absolutePath,
            mediatorConnectionsInvite = invitationUrl,
            mediatorPickupStrategy = MediatorPickupStrategy.Implicit,
            label = "SampleApp",
            autoAcceptCredential = AutoAcceptCredential.Never,
            autoAcceptProof = AutoAcceptProof.Never
        )

         Log.d("MainActivity", "Agent Config")

        CoroutineScope(Dispatchers.Main).launch {
            try {
                agent = Agent(applicationContext, config)
                Log.d("MainActivity", "Agent Created")

                agent?.initialize()
                Log.d("MainActivity", "Agent Initialized")

                val response = mapOf("error" to "", "result" to true)
                result.success(response)
            } catch (e: Exception) {
                Log.e("MainActivity", "Cannot initialize agent: ${e.message}")
                val response = mapOf("error" to e.message, "result" to false)
                result.success(response)
            }
        }
    }

    private fun receiveInvitation(invitationUrl: String?, result: MethodChannel.Result) {
        Log.d("MainActivity", "receiveInvitation called from Kotlin with invitationUrl: $invitationUrl")

        if (invitationUrl == null) {
            result.error("1", "Invitation URL is null", null)
            return
        }

        if (agent == null) {
            result.error("1", "Agent is null", null)
            return
        }

        lifecycleScope.launch(Dispatchers.Main) {
            try {
                val (_, connection) = agent!!.oob.receiveInvitationFromUrl(invitationUrl)
                Log.d("MainActivity", "Connected to ${connection ?: "unknown agent"}")

                result.success(mapOf("error" to "", "result" to true))
            } catch (e: Exception) {
                Log.e("MainActivity","Unable to connect: ${e.localizedMessage}")

                result.error("1", e.message, null)
            }
        }
    }

    private fun shutdown(result: MethodChannel.Result) {
        Log.d("MainActivity", "shutdown called from Kotlin...")

        if (agent == null) {
            result.error("1", "Agent is null", null)
            return
        }

        lifecycleScope.launch(Dispatchers.Main) {
            try {
                agent!!.shutdown()
                agent = null;

                result.success(mapOf("error" to "", "result" to true))
            } catch (e: Exception) {
                Log.e("MainActivity","Unable to shutdown agent: ${e.localizedMessage}")

                result.error("1", e.message, null)
            }
        }
    }
}