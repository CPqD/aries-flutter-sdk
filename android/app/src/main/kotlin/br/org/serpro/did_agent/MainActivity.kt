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
import org.hyperledger.ariesframework.agent.AgentEvents
import org.hyperledger.ariesframework.agent.AgentConfig
import org.hyperledger.ariesframework.credentials.models.CredentialState
import org.hyperledger.ariesframework.agent.MediatorPickupStrategy
import org.hyperledger.ariesframework.credentials.models.AutoAcceptCredential
import org.hyperledger.ariesframework.proofs.models.AutoAcceptProof
import org.hyperledger.ariesframework.problemreports.messages.CredentialProblemReportMessage
import org.hyperledger.ariesframework.problemreports.messages.MediationProblemReportMessage
import org.hyperledger.ariesframework.problemreports.messages.PresentationProblemReportMessage
import org.hyperledger.ariesframework.proofs.models.ProofState
import org.hyperledger.ariesframework.credentials.models.AcceptOfferOptions
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

    private lateinit var methodChannel: MethodChannel

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine)

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, INTEGRITYCHANNEL)

        methodChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "init" -> {
                    try {
                        init(result)
                    } catch (e: Exception) {
                        result.error("1", "Erro ao inicializar agente: " + e.toString(), null)
                    }
                }
                "openwallet" -> {
                    try {
                        openWallet(result)
                    } catch (e: Exception) {
                        result.error("1", "Erro ao processar o methodchannel openwallet: " + e.toString(), null)
                    }
                }
                "receiveInvitation" -> {
                    try {
                        val invitationUrl = call.argument<String>("invitationUrl")
                        receiveInvitation(invitationUrl, result)
                    } catch (e: Exception) {
                        result.error("1", "Erro ao processar o methodchannel receiveInvitation: " + e.toString(), null)
                    }
                }
                "subscribe" -> {
                    try {
                        subscribeEvents(result)
                    } catch (e: Exception) {
                        result.error("1", "Erro ao processar o methodchannel subscribe: " + e.toString(), null)
                    }
                }
                "shutdown" -> {
                    try {
                        shutdown(result)
                    } catch (e: Exception) {
                        result.error("1", "Erro ao processar o methodchannel shutdown: " + e.toString(), null)
                    }
                }
                "acceptOffer" -> {
                    try {
                        val credentialRecordId = call.argument<String>("credentialRecordId")
                        acceptOffer(credentialRecordId, result)
                    }catch (e:Exception){
                        result?.error("1","Erro ao processar o methodchannel acceptOffer: "+e.toString(),null)
                    }
                }
                "declineOffer" -> {
                    try { 
                        val credentialRecordId = call.argument<String>("credentialRecordId")
                        declineOffer(credentialRecordId, result)
                    }catch (e:Exception){
                        result?.error("1","Erro ao processar o methodchannel declineOffer: "+e.toString(),null)
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
                Log.e("MainActivity", "Unable to connect: ${e.localizedMessage}")

                result.error("1", e.message, null)
            }
        }
    }

    private fun subscribeEvents(result: MethodChannel.Result) {
        if (agent == null) {
            result.error("1", "Agent is null", null)
            return
        }

        agent!!.eventBus.subscribe<AgentEvents.CredentialEvent> {
            lifecycleScope.launch(Dispatchers.Main) {
                Log.d("MainActivity", "Credential ${it.record.state}: ${it.record.id} - ${it.record.threadId}")
                sendCredentialToFlutter(it.record.id, it.record.state.toString())
            }
        }

        agent!!.eventBus.subscribe<AgentEvents.ProofEvent> {
            lifecycleScope.launch(Dispatchers.Main) {
                Log.d("MainActivity", "Proof ${it.record.state}: ${it.record.id}")
                sendProofToFlutter(it.record.id, it.record.state.toString())
            }
        }

        agent!!.eventBus.subscribe<AgentEvents.ProblemReportEvent> {
            lifecycleScope.launch(Dispatchers.Main) {
                if (it.message is CredentialProblemReportMessage) {
                    Log.e("MainActivity", "Issuer reported a problem while issuing the credential - ${it.message.description.en}")
                }
                if (it.message is PresentationProblemReportMessage) {
                    Log.e("MainActivity", "Verifier reported a problem while verifying the presentation - ${it.message.description.en}")
                }
                if (it.message is MediationProblemReportMessage) {
                    Log.e("MainActivity", "Mediator reported a problem - ${it.message.description.en}")
                }
            }
        }
    }

    private fun sendCredentialToFlutter(id: String, state: String) {
        methodChannel.invokeMethod("credentialReceived", mapOf("id" to id, "state" to state))
    }

    private fun sendProofToFlutter(id: String, state: String) {
        methodChannel.invokeMethod("proofReceived", mapOf("id" to id, "state" to state))
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
                Log.e("MainActivity", "Unable to shutdown agent: ${e.localizedMessage}")

                result.error("1", e.message, null)
            }
        }
    }

    private fun acceptOffer(credentialRecordId: String?, result: MethodChannel.Result) {
        Log.d("MainActivity", "accept offer called from Kotlin...")

        if (credentialRecordId == null) {
            result.error("1", "CredenctialRecordId is null", null)
            return
        }

        if (agent == null) {
            result.error("1", "Agent is null", null)
            return
        }
        val acceptOfferOption = AcceptOfferOptions(credentialRecordId = credentialRecordId, autoAcceptCredential = AutoAcceptCredential.Always);

        lifecycleScope.launch(Dispatchers.Main) {
            try {
                agent!!.credentials.acceptOffer(acceptOfferOption)

                result.success(mapOf("error" to "", "result" to true))
            } catch (e: Exception) {
                Log.e("MainActivity","Failed to receive a credential: ${e.localizedMessage}")

                result.error("1", e.message, null)
            }
        }
    }

    private fun declineOffer(credentialRecordId: String?, result: MethodChannel.Result) {
        Log.d("MainActivity", "decline offer called from Kotlin...")

        if (credentialRecordId == null) {
            result.error("1", "CredentialRecordId is null", null)
            return
        }

        if (agent == null) {
            result.error("1", "Agent is null", null)
            return
        }

        val acceptOfferOption = AcceptOfferOptions(credentialRecordId = credentialRecordId, autoAcceptCredential = AutoAcceptCredential.Never);

        lifecycleScope.launch(Dispatchers.Main) {
            try {
                agent!!.credentials.declineOffer(acceptOfferOption)

                result.success(mapOf("error" to "", "result" to true))
            } catch (e: Exception) {
                Log.e("MainActivity","Failed to decline a credential: ${e.localizedMessage}")

                result.error("1", e.message, null)
            }
        }
    }
}

