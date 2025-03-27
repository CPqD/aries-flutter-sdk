package br.org.serpro.did_agent

import androidx.lifecycle.lifecycleScope
import android.content.Context
import android.content.SharedPreferences
import android.util.Log
import br.org.serpro.did_agent.utils.CredentialUtils
import br.org.serpro.did_agent.utils.JsonConverter
import br.org.serpro.did_agent.utils.ProofUtils
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking
import kotlinx.datetime.Instant
import org.hyperledger.ariesframework.agent.Agent
import org.hyperledger.ariesframework.agent.AgentEvents
import org.hyperledger.ariesframework.agent.AgentConfig
import org.hyperledger.ariesframework.agent.MediatorPickupStrategy
import org.hyperledger.ariesframework.credentials.models.CredentialState
import org.hyperledger.ariesframework.credentials.v1.models.AutoAcceptCredential
import org.hyperledger.ariesframework.proofs.models.AutoAcceptProof
import org.hyperledger.ariesframework.problemreports.messages.CredentialProblemReportMessage
import org.hyperledger.ariesframework.problemreports.messages.MediationProblemReportMessage
import org.hyperledger.ariesframework.problemreports.messages.PresentationProblemReportMessage
import org.hyperledger.ariesframework.proofs.models.ProofState
import java.io.File
import kotlin.Exception


const val genesisPath = "bcovrin-genesis.txn"
const val mediatorUrl = "https://blockchain.cpqd.com.br/cpqdid/agent-mediator-endpoint-com?c_i=eyJAdHlwZSI6ICJkaWQ6c292OkJ6Q2JzTlloTXJqSGlxWkRUVUFTSGc7c3BlYy9jb25uZWN0aW9ucy8xLjAvaW52aXRhdGlvbiIsICJAaWQiOiAiMGEyYzc4MTYtMGYxZC00OTc3LTg5YzAtMGE0NmNhNTg4Nzk0IiwgInJlY2lwaWVudEtleXMiOiBbIjRFVFhHZGM3UjJzYVBzZktZR1g1dU15dDNFWU5aQVdyejJpN3VXbnN0eGJkIl0sICJsYWJlbCI6ICJNZWRpYWRvciBTT1UgaUQiLCAic2VydmljZUVuZHBvaW50IjogImh0dHBzOi8vYmxvY2tjaGFpbi5jcHFkLmNvbS5ici9jcHFkaWQvYWdlbnQtbWVkaWF0b3ItZW5kcG9pbnQtY29tIn0="

class MainActivity: FlutterFragmentActivity() {
    companion object {
        private const val INTEGRITYCHANNEL = "br.gov.serprocpqd/wallet"
    }
    private var agent: Agent? = null
    private var walletKey: String? = null
    private var subscribed = false

    private lateinit var methodChannel: MethodChannel

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
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
                "getCredentials" -> {
                    try {
                        getCredentials(result)
                    } catch (e: Exception) {
                        result.error("1", "Erro ao processar o methodchannel getCredentials: " + e.toString(), null)
                    }
                }
                "getCredential" -> {
                    try {
                        val credentialId = call.argument<String>("credentialId")
                        getCredential(credentialId, result)
                    } catch (e: Exception) {
                        result.error("1", "Erro ao processar o methodchannel getCredentials: " + e.toString(), null)
                    }
                }
                "getConnections" -> {
                    try {
                        getConnections(result)
                    } catch (e: Exception) {
                        result.error("1", "Erro ao processar o methodchannel getConnections: " + e.toString(), null)
                    }
                }
                "getCredentialsOffers" -> {
                    try {
                        getCredentialsOffers(result)
                    } catch (e: Exception) {
                        result.error("1", "Erro ao processar o methodchannel getCredentialsOffers: " + e.toString(), null)
                    }
                }
                "getDidCommMessage" -> {
                    try {
                        val associatedRecordId = call.argument<String>("associatedRecordId")
                        getDidCommMessage(associatedRecordId, result)
                    } catch (e: Exception) {
                        result.error("1", "Erro ao processar o methodchannel getDidCommMessage: " + e.toString(), null)
                    }
                }
                "getDidCommMessagesByRecord" -> {
                    try {
                        val associatedRecordId = call.argument<String>("associatedRecordId")
                        getDidCommMessagesByRecord(associatedRecordId, result)
                    } catch (e: Exception) {
                        result.error("1", "Erro ao processar o methodchannel getDidCommMessageSent: " + e.toString(), null)
                    }
                }
                "getProofOffers" -> {
                    try {
                        getProofOffers(result)
                    } catch (e: Exception) {
                        result.error("1", "Erro ao processar o methodchannel getProofOffers: " + e.toString(), null)
                    }
                }
                "getProofOfferDetails" -> {
                    try {
                        val proofRecordId = call.argument<String>("proofRecordId")
                        getProofOfferDetails(proofRecordId, result)
                    } catch (e: Exception) {
                        result.error("1", "Erro ao processar o methodchannel getProofOfferDetails: " + e.toString(), null)
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
                "acceptCredentialOffer" -> {
                    try {
                        val credentialRecordId = call.argument<String>("credentialRecordId")
                        val protocolVersion = call.argument<String>("protocolVersion")

                        acceptCredentialOffer(credentialRecordId, protocolVersion, result)
                    }catch (e:Exception){
                        result.error("1","Erro ao processar o methodchannel acceptOffer: "+e.toString(),null)
                    }
                }
                "declineCredentialOffer" -> {
                    try {
                        val credentialRecordId = call.argument<String>("credentialRecordId")
                        val protocolVersion = call.argument<String>("protocolVersion")

                        declineCredentialOffer(credentialRecordId, protocolVersion, result)
                    }catch (e:Exception){
                        result.error("1","Erro ao processar o methodchannel declineOffer: "+e.toString(),null)
                    }
                }
                "acceptProofOffer" -> {
                    try {
                        val proofRecordId = call.argument<String>("proofRecordId")
                        val selectedCredentialsAttributes = call.argument<Map<String, String>>("selectedCredentialsAttributes")
                        val selectedCredentialsPredicates = call.argument<Map<String, String>>("selectedCredentialsPredicates")
                        acceptProofOffer(proofRecordId, selectedCredentialsAttributes, selectedCredentialsPredicates, result)
                    }catch (e:Exception){
                        result.error("1","Erro ao processar o methodchannel acceptProofOffer: "+e.toString(),null)
                    }
                }
                "declineProofOffer" -> {
                    try {
                        val proofRecordId = call.argument<String>("proofRecordId")
                        declineProofOffer(proofRecordId, result)
                    }catch (e:Exception){
                        result.error("1","Erro ao processar o methodchannel declineProofOffer: "+e.toString(),null)
                    }
                }
                "removeCredential" -> {
                    try {
                        val credentialRecordId = call.argument<String>("credentialRecordId")
                        removeCredential(credentialRecordId, result)
                    }catch (e:Exception){
                        result.error("1","Erro ao processar o methodchannel removeCredential: "+e.toString(),null)
                    }
                }
                "removeConnection" -> {
                    try {
                        val connectionRecordId = call.argument<String>("connectionRecordId")
                        removeConnection(connectionRecordId, result)
                    }catch (e:Exception){
                        result.error("1","Erro ao processar o methodchannel removeConnection: "+e.toString(),null)
                    }
                }
                "getConnectionHistory" -> {
                    try {
                        val connectionId = call.argument<String>("connectionId")

                        getConnectionHistory(connectionId, result)
                    } catch (e: Exception) {
                        result.error("1", "Erro ao processar o methodchannel getConnectionHistory: " + e.toString(), null)
                    }
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun init(result: MethodChannel.Result) {
        Log.d("MainActivity", "init called from Kotlin...")

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

        result.success(mapOf("error" to "", "result" to true))
    }

    private fun copyResourceFile(resource: String) {
        val inputStream = applicationContext.assets.open(resource)
        val file = File(applicationContext.filesDir.absolutePath, resource)
        file.outputStream().use { inputStream.copyTo(it) }
    }

    private fun openWallet(result: MethodChannel.Result) {
        Log.d("MainActivity", "openWallet called from Kotlin...")

        if (agent != null) {
            result.error("1", "Wallet is already open", null)
            return
        }

        try {
            copyResourceFile(genesisPath)
        } catch (e: Exception) {
            Log.e("MainActivity", "Cannot open genesis: ${e.message}")
            result.error("1", "Cannot open genesis: ${e.message}", null)
            return
        }

        val config = AgentConfig(
            walletKey = walletKey!!,
            genesisPath = File(applicationContext.filesDir.absolutePath, genesisPath).absolutePath,
            mediatorConnectionsInvite = mediatorUrl,
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

    private fun getCredentials(result: MethodChannel.Result) {
        Log.d("MainActivity", "getCredentials called from Kotlin...")

        validateAgent()

        try {
            val credentials = runBlocking { CredentialUtils.getAllAsMaps(agent!!) }

            result.success(mapOf("error" to "", "result" to JsonConverter.toJson(credentials)))
        } catch (e: Exception) {
            Log.e("MainActivity", "Cannot get credentials: ${e.message}")
            result.error("1", "Cannot get credentials: ${e.message}", null)
            return
        }
    }

    private fun getCredential(credentialId: String?, result: MethodChannel.Result) {
        Log.d("MainActivity", "getCredential called from Kotlin...")

        validateAgent()
        validateNotNull("CredentialId", credentialId)

        try {
            val credential = runBlocking { CredentialUtils.getDetails(agent!!, credentialId!!) }

            if (credential == null) {
                result.error("1", "credential not found", null)
                return
            }

            result.success(mapOf("error" to "", "result" to JsonConverter.toJson(credential)))
        } catch (e: Exception) {
            Log.e("MainActivity", "Cannot get credential: ${e.message}")
            result.error("1", "Cannot get credential: ${e.message}", null)
            return
        }
    }

    private fun getConnections(result: MethodChannel.Result) {
        Log.d("MainActivity", "getConnections called from Kotlin...")

        validateAgent()

        try {
            val connections = runBlocking {  agent?.connectionRepository?.getAll() }

            Log.d("MainActivity", "connections: ${connections.toString()}")

            val connectionsList = mutableListOf<Map<String, Any?>>()

            if (connections.isNullOrEmpty()) {
                Log.d("MainActivity", "getConnections -> connections.isNullOrEmpty")

                result.success(mapOf("error" to "", "result" to JsonConverter.toJson(connectionsList)))

                return
            }

            Log.d("MainActivity", "getConnections -> connections is not Null Or Empty")

            for (connection in connections) {
                connectionsList.add(JsonConverter.toMap(connection))
            }

            result.success(mapOf("error" to "", "result" to JsonConverter.toJson(connectionsList)))

        } catch (e: Exception) {
            Log.e("MainActivity", "Cannot get connections: ${e.message}")
            result.error("1", "Cannot get connections: ${e.message}", null)
            return
        }
    }

    private fun getCredentialsOffers(result: MethodChannel.Result) {
        Log.d("MainActivity", "getCredentialsOffers called from Kotlin...")

        validateAgent()

        try {
            val credentialsOffersList = runBlocking {  CredentialUtils.getExchangesByState(agent!!, CredentialState.OfferReceived) }

            result.success(mapOf("error" to "", "result" to JsonConverter.toJson(credentialsOffersList)))
        } catch (e: Exception) {
            Log.e("MainActivity", "Cannot get credentialsOffers: ${e.message}")
            result.error("1", "Cannot get credentialsOffers: ${e.message}", null)
            return
        }
    }

    private fun getProofOffers(result: MethodChannel.Result) {
        Log.d("MainActivity", "getProofOffers called from Kotlin...")

        validateAgent()

        try {
            val proofOffersList = runBlocking { ProofUtils.findByState(agent!!, ProofState.RequestReceived) }

            result.success(mapOf("error" to "", "result" to JsonConverter.toJson(proofOffersList)))
        } catch (e: Exception) {
            Log.e("MainActivity", "Cannot get proofOffers: ${e.message}")
            result.error("1", "Cannot get proofOffers: ${e.message}", null)
            return
        }
    }

    private fun getProofOfferDetails(proofRecordId: String?, result: MethodChannel.Result) {
        Log.d("MainActivity", "getProofOfferDetails called from Kotlin...")

        validateAgent()
        validateNotNull("ProofRecordId", proofRecordId)

        try {
            val (attributesList, predicatesList, proofRequestJson) = runBlocking { ProofUtils.getDetails(agent!!, proofRecordId!!) }

            val jsonResult = mapOf(
                "attributes" to JsonConverter.toJson(attributesList),
                "predicates" to JsonConverter.toJson(predicatesList),
                "proofRequest" to proofRequestJson,
            )

            result.success(mapOf("error" to "", "result" to jsonResult))
        } catch (e: Exception) {
            Log.e("MainActivity", "Cannot get proofOffer: ${e.message}")
            result.error("1", "Cannot get getProofOfferDetails: ${e.message}", null)
            return
        }
    }

    private fun getConnectionHistory(connectionId: String?, result: MethodChannel.Result) {
        Log.d("MainActivity", "getConnectionHistory called from Kotlin...")

        validateNotNull("ConnectionId", connectionId)
        validateAgent()

        val credentialsMap = emptyMap<String, Map<String, Any?>>().toMutableMap()
        val proofsMap = emptyMap<String, Map<String, Any?>>().toMutableMap()

        try {
            val credentials = runBlocking {  agent!!.credentialExchangeRepository.findByQuery("{\"connectionId\": \"${connectionId!!}\"}") }
            val proofs = runBlocking {  agent!!.proofRepository.findByQuery("{\"connectionId\": \"${connectionId!!}\"}") }

            Log.d("MainActivity", "credentials: $credentials")
            Log.d("MainActivity", "proofs: $proofs")


            for (record in credentials) {
                val map = JsonConverter.toMap(record).toMutableMap()
                map["recordType"] = "CredentialRecord"

                if (credentialsMap.containsKey(record.id) && record.state != CredentialState.OfferSent) {
                    continue
                }

                credentialsMap[record.id] = map
            }

            for (record in proofs) {
                val map = JsonConverter.toMap(record).toMutableMap()
                map["recordType"] = "ProofExchangeRecord"

                if (proofsMap.containsKey(record.id) && record.state != ProofState.RequestSent) {
                    continue
                }

                proofsMap[record.id] = map
            }

            Log.d("MainActivity", "credentialsMap: $credentialsMap")
            Log.d("MainActivity", "proofsMap: $proofsMap")

            val jsonResult = mapOf(
                "credentials" to JsonConverter.toJson(credentialsMap.values),
                "proofs" to JsonConverter.toJson(proofsMap.values)
            )
            Log.d("MainActivity", "jsonResult: $jsonResult")

            result.success(mapOf("error" to "", "result" to jsonResult))
        } catch (e: Exception) {
            Log.e("MainActivity", "Cannot get getConnectionHistory: ${e.message}")
            result.error("1", "Cannot get getConnectionHistory: ${e.message}", null)
            return
        }
    }

    private fun getDidCommMessage(associatedRecordId: String?, result: MethodChannel.Result) {
        Log.d("MainActivity", "getDidCommMessage called from Kotlin...")

        validateAgent()
        validateNotNull("AssociatedRecordId", associatedRecordId)

        try {
            val didCommMessage = runBlocking {  agent?.didCommMessageRepository?.getSingleByQuery("{\"associatedRecordId\": \"$associatedRecordId\"}") }

            Log.d("MainActivity", "didCommMessage: ${didCommMessage.toString()}")

            if (didCommMessage == null) {
                result.error("1", "didCommMessage not found", null)
                return
            }

            val didCommMessageMap = JsonConverter.toMap(didCommMessage)

            result.success(mapOf("error" to "", "result" to JsonConverter.toJson(didCommMessageMap)))

        } catch (e: Exception) {
            Log.e("MainActivity", "Cannot get didCommMessage: ${e.message}")
            result.error("1", "Cannot get didCommMessage: ${e.message}", null)
            return
        }
    }

    private fun getDidCommMessagesByRecord(associatedRecordId: String?, result: MethodChannel.Result) {
        Log.d("MainActivity", "getDidCommMessagesByRecord called from Kotlin...")

        validateAgent()
        validateNotNull("AssociatedRecordId", associatedRecordId)

        try {
            val didCommMessagesList = mutableListOf<Map<String, Any?>>()

            val didCommMessages = runBlocking {
                agent!!.didCommMessageRepository.findByQuery("{\"associatedRecordId\": \"$associatedRecordId\"}")
            }

            for (didCommMessage in didCommMessages) {
                Log.d("MainActivity", "didCommMessage: $didCommMessage")

                didCommMessagesList.add(JsonConverter.toMap(didCommMessage))
            }

            result.success(mapOf("error" to "", "result" to JsonConverter.toJson(didCommMessagesList)))
        } catch (e: Exception) {
            Log.e("MainActivity", "Cannot get DidCommMessageSent: ${e.message}")
            result.error("1", "Cannot get DidCommMessageSent: ${e.message}", null)
            return
        }
    }

    private fun receiveInvitation(invitationUrl: String?, result: MethodChannel.Result) {
        Log.d("MainActivity", "receiveInvitation called from Kotlin with invitationUrl: $invitationUrl")

        validateAgent()
        validateNotNull("Invitation URL", invitationUrl)

        lifecycleScope.launch(Dispatchers.Main) {
            try {
                val (_, connection) = agent!!.oob.receiveInvitationFromUrl(invitationUrl!!)
                Log.d("MainActivity", "Connected to ${connection ?: "unknown agent"}")

                result.success(mapOf("error" to "", "result" to true))
            } catch (e: Exception) {
                Log.e("MainActivity", "Unable to connect: ${e.localizedMessage}")

                result.error("1", e.message, null)
            }
        }
    }

    private fun subscribeEvents(result: MethodChannel.Result) {
        validateAgent()
        validateSubscribe()

        subscribed = true

        try {
            agent!!.eventBus.subscribe<AgentEvents.CredentialEvent> {
                lifecycleScope.launch(Dispatchers.Main) {
                    Log.d("MainActivity", "Credential ${it.record.id}: ${it.record}")

                    sendCredentialToFlutter(it.record.id, it.record.state.toString())
                }
            }

            agent!!.eventBus.subscribe<AgentEvents.CredentialEventV2> {
                lifecycleScope.launch(Dispatchers.Main) {
                    Log.d("MainActivity", "Credential V2 ${it.record.id}: ${it.record}")

                    sendCredentialToFlutter(it.record.id, it.record.state.toString())
                }
            }

            agent!!.eventBus.subscribe<AgentEvents.RevocationNotificationReceivedEvent> {
                lifecycleScope.launch(Dispatchers.Main) {
                    Log.d("MainActivity", "RevocationNotificationReceivedEvent ${it.record.id}: ${it.record}")

                    sendCredentialRevocationToFlutter(it.record.id)
                }
            }

            agent!!.eventBus.subscribe<AgentEvents.RevocationNotificationReceivedEventV2> {
                lifecycleScope.launch(Dispatchers.Main) {
                    Log.d("MainActivity", "RevocationNotificationReceivedEventV2 ${it.record.id}: ${it.record}")

                    sendCredentialRevocationToFlutter(it.record.id)
                }
            }

            agent!!.eventBus.subscribe<AgentEvents.ProofEvent> {
                lifecycleScope.launch(Dispatchers.Main) {
                    Log.d("MainActivity", "Proof ${it.record.state}: ${it.record.id}")

                    sendProofToFlutter(it.record.id, it.record.state.toString())
                }
            }

            agent!!.eventBus.subscribe<AgentEvents.BasicMessageEvent> {
                lifecycleScope.launch(Dispatchers.Main) {
                    Log.e("MainActivity", "Basic Message Event: content=${it.message.content} / connectionRecordId=$${it.message.connectionRecordId}")


                    sendBasicMessageToFlutter(
                        it.message.content,
                        it.message.connectionRecordId,
                        it.message.theirLabel,
                    )
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
        } catch (e: Exception) {
            Log.e("MainActivity", "Unable to subscribe: ${e.localizedMessage}")

            result.error("1", e.message, null)
        }

        result.success(mapOf("error" to "", "result" to true))
    }

    private fun shutdown(result: MethodChannel.Result) {
        Log.d("MainActivity", "shutdown called from Kotlin...")

        validateAgent()

        lifecycleScope.launch(Dispatchers.Main) {
            try {
                agent!!.shutdown()
                agent = null;
                subscribed = false;

                result.success(mapOf("error" to "", "result" to true))
            } catch (e: Exception) {
                Log.e("MainActivity", "Unable to shutdown agent: ${e.localizedMessage}")

                result.error("1", e.message, null)
            }
        }
    }

    private fun acceptCredentialOffer(credentialRecordId: String?, protocolVersion: String?, result: MethodChannel.Result) {
        Log.d("MainActivity", "accept offer called from Kotlin...")

        validateNotNull("CredentialRecordId", credentialRecordId)
        validateNotNull("ProtocolVersion", protocolVersion)
        validateAgent()

        lifecycleScope.launch(Dispatchers.IO) {
            try {
                CredentialUtils.acceptOffer(agent!!, credentialRecordId!!, protocolVersion!!)

                result.success(mapOf("error" to "", "result" to true))
            } catch (e: Exception) {
                Log.e("MainActivity","Failed to accept a credential offer: ${e.localizedMessage}")

                result.error("1", e.message, null)
            }
        }
    }


    private fun declineCredentialOffer(credentialRecordId: String?, protocolVersion: String?, result: MethodChannel.Result) {
        Log.d("MainActivity", "decline offer called from Kotlin...")

        validateNotNull("CredentialRecordId", credentialRecordId)
        validateNotNull("ProtocolVersion", protocolVersion)
        validateAgent()

        lifecycleScope.launch(Dispatchers.Main) {
            try {
                CredentialUtils.declineOffer(agent!!, credentialRecordId!!, protocolVersion!!)

                result.success(mapOf("error" to "", "result" to true))
            } catch (e: Exception) {
                Log.e("MainActivity","Failed to decline a credential: ${e.localizedMessage}")

                result.error("1", e.message, null)
            }
        }
    }

    private fun acceptProofOffer(proofRecordId: String?, selectedCredentialsAttributes: Map<String, String>?, selectedCredentialsPredicates: Map<String, String>?, result: MethodChannel.Result) {
        Log.d("MainActivity", "acceptProofOffer: $proofRecordId")

        validateNotNull("ProofRecordId", proofRecordId)
        validateNotNull("SelectedCredentialsAttributes", selectedCredentialsAttributes)
        validateNotNull("SelectedCredentialsPredicates", selectedCredentialsPredicates)
        validateAgent()

        try {
            runBlocking { ProofUtils.acceptRequest(agent!!, proofRecordId!!, selectedCredentialsAttributes!!, selectedCredentialsPredicates!!) }

            result.success(mapOf("error" to "", "result" to true))
        } catch (e: Exception) {
            Log.e("MainActivity","Failed to present proof: ${e.localizedMessage}")

            result.error("1", e.message, null)
        }
    }

    private fun declineProofOffer(proofRecordId: String?, result: MethodChannel.Result) {
        Log.d("MainActivity", "declineProofOffer: $proofRecordId")

        validateNotNull("ProofRecordId", proofRecordId)
        validateAgent()

        lifecycleScope.launch(Dispatchers.IO) {
            try {
                agent!!.proofs.declineRequest(proofRecordId!!)

                result.success(mapOf("error" to "", "result" to true))
            } catch (e: Exception) {
                Log.e("MainActivity","Failed to decline a proof: ${e.localizedMessage}")

                result.error("1", e.message, null)
            }
        }
    }

    private fun removeCredential(credentialRecordId: String?, result: MethodChannel.Result) {
        Log.d("MainActivity", "decline offer called from Kotlin...")

        validateNotNull("CredentialRecordId", credentialRecordId)
        validateAgent()

        try {
            val deleteResult = runBlocking { agent?.credentialRepository?.deleteById(credentialRecordId!!) }

            Log.d("MainActivity","deleteResult: ${deleteResult.toString()}")

            result.success(mapOf("error" to "", "result" to true))
        } catch (e: Exception) {
            Log.e("MainActivity","Failed to remove a credential: ${e.localizedMessage}")

            result.error("1", e.message, null)
        }
    }

    private fun removeConnection(connectionRecordId: String?, result: MethodChannel.Result) {
        Log.d("MainActivity", "decline offer called from Kotlin...")

        validateNotNull("ConnectionRecordId", connectionRecordId)
        validateAgent()

        try {
            val deleteResult = runBlocking { agent?.connectionRepository?.deleteById(connectionRecordId!!) }

            Log.d("MainActivity","deleteResult: ${deleteResult.toString()}")

            result.success(mapOf("error" to "", "result" to true))
        } catch (e: Exception) {
            Log.e("MainActivity","Failed to remove a connection: ${e.localizedMessage}")

            result.error("1", e.message, null)
        }
    }

    private fun sendBasicMessageToFlutter(messageContent: String, connectionRecordId: String?, connectionLabel: String?) {
        methodChannel.invokeMethod(
            "basicMessageReceived",
            mapOf(
                "message" to messageContent,
                "connectionRecordId" to connectionRecordId,
                "connectionLabel" to connectionLabel,
            )
        )
    }

    private fun sendCredentialToFlutter(id: String, state: String) {
        Log.e("MainActivity", "Invoking credentialReceived from Kotlin")
        methodChannel.invokeMethod("credentialReceived", mapOf("id" to id, "state" to state))
    }

    private fun sendCredentialRevocationToFlutter(id: String) {
        Log.e("MainActivity", "Invoking credentialReceived from Kotlin")
        methodChannel.invokeMethod("credentialRevocationReceived", mapOf("id" to id))
    }

    private fun sendProofToFlutter(id: String, state: String) {
        Log.e("MainActivity", "Invoking proofReceived from Kotlin")
        methodChannel.invokeMethod("proofReceived", mapOf("id" to id, "state" to state))
    }

    private fun validateAgent() {
        if (agent == null) {
            throw Exception("Agent is null")
        }
    }

    private fun validateSubscribe() {
        if (subscribed) {
            throw Exception("Already subscribed!")
        }
    }

    private fun validateNotNull(name: String, value: Any?) {
        if (value == null) {
            throw Exception("$name is null")
        }
    }
}

