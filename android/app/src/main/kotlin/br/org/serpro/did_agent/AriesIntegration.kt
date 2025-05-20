package br.org.serpro.did_agent

import android.content.ContentResolver
import android.content.Context
import android.content.SharedPreferences
import android.provider.Settings
import android.util.Log
import androidx.lifecycle.LifecycleCoroutineScope
import br.org.serpro.did_agent.utils.ConnectionUtils
import br.org.serpro.did_agent.utils.CredentialUtils
import br.org.serpro.did_agent.utils.JsonConverter
import br.org.serpro.did_agent.utils.ProofUtils
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking
import org.hyperledger.ariesframework.agent.Agent
import org.hyperledger.ariesframework.agent.AgentConfig
import org.hyperledger.ariesframework.agent.AgentEvents
import org.hyperledger.ariesframework.agent.MediatorPickupStrategy
import org.hyperledger.ariesframework.credentials.models.CredentialState
import org.hyperledger.ariesframework.credentials.v1.models.AutoAcceptCredential
import org.hyperledger.ariesframework.oob.models.CreateOutOfBandInvitationConfig
import org.hyperledger.ariesframework.problemreports.messages.CredentialProblemReportMessage
import org.hyperledger.ariesframework.problemreports.messages.MediationProblemReportMessage
import org.hyperledger.ariesframework.problemreports.messages.PresentationProblemReportMessage
import org.hyperledger.ariesframework.proofs.models.AutoAcceptProof
import org.hyperledger.ariesframework.proofs.models.ProofState
import java.io.File

const val genesisPath = "bcovrin-genesis.txn"

class AriesIntegration(private val mainActivity: MainActivity) {
    private var agent: Agent? = null
    private var mediatorUrl: String? = null
    private var walletKey: String? = null
    private var subscribed = false

    fun init(mediatorUrl: String?, sharedPreferences: SharedPreferences, result: MethodChannel.Result) {
        Log.d("AriesIntegration", "init called from Kotlin...")

        validateNotNull("MediatorUrl", mediatorUrl)

        this.mediatorUrl = mediatorUrl

        walletKey = sharedPreferences.getString("flutter.walletKey", null)

        if (walletKey == null) {
            try {
                walletKey = Agent.generateWalletKey()
                sharedPreferences.edit().putString("flutter.walletKey", walletKey).apply()

                Log.d("AriesIntegration", "Key was generated successfully")
            } catch (e: Exception) {
                Log.e("AriesIntegration", "Cannot generate key: ${e.message}")
                result.error("1", "Cannot generate key: ${e.message}", null)
                return
            }
        }

        result.success(mapOf("error" to "", "result" to true))
    }

    fun openWallet(applicationContext: Context, result: MethodChannel.Result) {
        Log.d("AriesIntegration", "openWallet called from Kotlin...")

        if (agent != null) {
            result.error("1", "Wallet is already open", null)
            return
        }

        try {
            copyResourceFile(applicationContext, genesisPath)
        } catch (e: Exception) {
            Log.e("AriesIntegration", "Cannot open genesis: ${e.message}")
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

        Log.d("AriesIntegration", "Agent Config")

        CoroutineScope(Dispatchers.Main).launch {
            try {
                agent = Agent(applicationContext, config)
                Log.d("AriesIntegration", "Agent Created")

                agent?.initialize()
                Log.d("AriesIntegration", "Agent Initialized")

                val response = mapOf("error" to "", "result" to true)
                result.success(response)
            } catch (e: Exception) {
                Log.e("AriesIntegration", "Cannot initialize agent: ${e.message}")
                val response = mapOf("error" to e.message, "result" to false)
                result.success(response)
            }
        }
    }

    fun getCredentials(result: MethodChannel.Result) {
        Log.d("AriesIntegration", "getCredentials called from Kotlin...")

        validateAgent()

        try {
            val credentials = runBlocking { CredentialUtils.getAllAsMaps(agent!!) }

            result.success(mapOf("error" to "", "result" to JsonConverter.toJson(credentials)))
        } catch (e: Exception) {
            Log.e("AriesIntegration", "Cannot get credentials: ${e.message}")
            result.error("1", "Cannot get credentials: ${e.message}", null)
        }
    }

    fun getCredential(credentialId: String?, result: MethodChannel.Result) {
        Log.d("AriesIntegration", "getCredential called from Kotlin...")

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
            Log.e("AriesIntegration", "Cannot get credential: ${e.message}")
            result.error("1", "Cannot get credential: ${e.message}", null)
        }
    }

    fun getConnections(hideMediator: Boolean, result: MethodChannel.Result) {
        Log.d("AriesIntegration", "getConnections called from Kotlin...")

        validateAgent()

        try {
            val connectionsList = runBlocking { ConnectionUtils.getAllAsMaps(agent!!, hideMediator) }

            result.success(mapOf("error" to "", "result" to JsonConverter.toJson(connectionsList)))
        } catch (e: Exception) {
            Log.e("AriesIntegration", "Cannot get connections: ${e.message}")
            result.error("1", "Cannot get connections: ${e.message}", null)
        }
    }

    fun getCredentialsOffers(result: MethodChannel.Result) {
        Log.d("AriesIntegration", "getCredentialsOffers called from Kotlin...")

        validateAgent()

        try {
            val credentialsOffersList = runBlocking { CredentialUtils.getExchangesByState(agent!!, CredentialState.OfferReceived) }

            result.success(mapOf("error" to "", "result" to JsonConverter.toJson(credentialsOffersList)))
        } catch (e: Exception) {
            Log.e("AriesIntegration", "Cannot get credentialsOffers: ${e.message}")
            result.error("1", "Cannot get credentialsOffers: ${e.message}", null)
        }
    }

    fun getDidCommMessage(associatedRecordId: String?, result: MethodChannel.Result) {
        Log.d("AriesIntegration", "getDidCommMessage called from Kotlin...")

        validateAgent()
        validateNotNull("AssociatedRecordId", associatedRecordId)

        try {
            val didCommMessage = runBlocking {
                agent?.didCommMessageRepository?.getSingleByQuery("{\"associatedRecordId\": \"$associatedRecordId\"}")
            }

            Log.d("AriesIntegration", "didCommMessage: ${didCommMessage.toString()}")

            if (didCommMessage == null) {
                result.error("1", "didCommMessage not found", null)
                return
            }

            val didCommMessageMap = JsonConverter.toMap(didCommMessage)

            result.success(mapOf("error" to "", "result" to JsonConverter.toJson(didCommMessageMap)))

        } catch (e: Exception) {
            Log.e("AriesIntegration", "Cannot get didCommMessage: ${e.message}")
            result.error("1", "Cannot get didCommMessage: ${e.message}", null)
            return
        }
    }

    fun getDidCommMessagesByRecord(associatedRecordId: String?, result: MethodChannel.Result) {
        Log.d("AriesIntegration", "getDidCommMessagesByRecord called from Kotlin...")

        validateAgent()
        validateNotNull("AssociatedRecordId", associatedRecordId)

        try {
            val didCommMessagesList = mutableListOf<Map<String, Any?>>()

            val didCommMessages = runBlocking {
                agent!!.didCommMessageRepository.findByQuery(
                    "{\"associatedRecordId\": \"$associatedRecordId\"}"
                )
            }

            for (didCommMessage in didCommMessages) {
                Log.d("AriesIntegration", "didCommMessage: $didCommMessage")

                didCommMessagesList.add(JsonConverter.toMap(didCommMessage))
            }

            result.success(mapOf("error" to "", "result" to JsonConverter.toJson(didCommMessagesList)))
        } catch (e: Exception) {
            Log.e("AriesIntegration", "Cannot get DidCommMessageSent: ${e.message}")
            result.error("1", "Cannot get DidCommMessageSent: ${e.message}", null)
            return
        }
    }

    fun getProofOffers(result: MethodChannel.Result) {
        Log.d("AriesIntegration", "getProofOffers called from Kotlin...")

        validateAgent()

        try {
            val proofOffersList = runBlocking { ProofUtils.findByState(agent!!, ProofState.RequestReceived) }

            result.success(mapOf("error" to "", "result" to JsonConverter.toJson(proofOffersList)))
        } catch (e: Exception) {
            Log.e("AriesIntegration", "Cannot get proofOffers: ${e.message}")
            result.error("1", "Cannot get proofOffers: ${e.message}", null)
        }
    }

    fun getProofOfferDetails(proofRecordId: String?, result: MethodChannel.Result) {
        Log.d("AriesIntegration", "getProofOfferDetails called from Kotlin...")

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
            Log.e("AriesIntegration", "Cannot get proofOffer: ${e.message}")
            result.error("1", "Cannot get getProofOfferDetails: ${e.message}", null)
        }
    }

    fun receiveInvitation(invitationUrl: String?, result: MethodChannel.Result) {
        Log.d("AriesIntegration", "receiveInvitation called from Kotlin with invitationUrl: $invitationUrl")

        validateAgent()
        validateNotNull("Invitation URL", invitationUrl)

        try {
            val (_, connection) = runBlocking { agent!!.oob.receiveInvitationFromUrl(invitationUrl!!) }
            Log.d("AriesIntegration", "Connected to ${connection ?: "unknown agent"}")

            result.success(mapOf("error" to "", "result" to true))
        } catch (e: Exception) {
            Log.e("AriesIntegration", "Unable to connect: ${e.localizedMessage}")

            result.error("1", e.message, null)
        }
    }

    fun subscribeEvents(lifecycleScope: LifecycleCoroutineScope, result: MethodChannel.Result) {
        validateAgent()
        validateSubscribe()

        subscribed = true

        try {
            agent!!.eventBus.subscribe<AgentEvents.CredentialEvent> {
                lifecycleScope.launch(Dispatchers.Main) {
                    Log.d("AriesIntegration", "Credential ${it.record.id}: ${it.record}")

                    mainActivity.sendCredentialToFlutter(it.record.id, it.record.state.toString())
                }
            }

            agent!!.eventBus.subscribe<AgentEvents.CredentialEventV2> {
                lifecycleScope.launch(Dispatchers.Main) {
                    Log.d("AriesIntegration", "Credential V2 ${it.record.id}: ${it.record}")

                    mainActivity.sendCredentialToFlutter(it.record.id, it.record.state.toString())
                }
            }

            agent!!.eventBus.subscribe<AgentEvents.RevocationNotificationReceivedEvent> {
                lifecycleScope.launch(Dispatchers.Main) {
                    Log.d("AriesIntegration", "RevocationNotificationReceivedEvent ${it.record.id}: ${it.record}")

                    mainActivity.sendCredentialRevocationToFlutter(it.record.id)
                }
            }

            agent!!.eventBus.subscribe<AgentEvents.RevocationNotificationReceivedEventV2> {
                lifecycleScope.launch(Dispatchers.Main) {
                    Log.d("AriesIntegration", "RevocationNotificationReceivedEventV2 ${it.record.id}: ${it.record}")

                    mainActivity.sendCredentialRevocationToFlutter(it.record.id)
                }
            }

            agent!!.eventBus.subscribe<AgentEvents.ProofEvent> {
                lifecycleScope.launch(Dispatchers.Main) {
                    Log.d("AriesIntegration", "Proof ${it.record.state}: ${it.record.id}")

                    mainActivity.sendProofToFlutter(it.record.id, it.record.state.toString())
                }
            }

            agent!!.eventBus.subscribe<AgentEvents.BasicMessageEvent> {
                lifecycleScope.launch(Dispatchers.Main) {
                    Log.e("AriesIntegration", "Basic Message Event: content=${it.record}")

                    mainActivity.sendBasicMessageToFlutter(it.record)
                }
            }

            agent!!.eventBus.subscribe<AgentEvents.ProblemReportEvent> {
                lifecycleScope.launch(Dispatchers.Main) {
                    if (it.message is CredentialProblemReportMessage) {
                        Log.e("AriesIntegration", "Issuer reported a problem while issuing the credential - ${it.message.description.en}")
                    }
                    if (it.message is PresentationProblemReportMessage) {
                        Log.e("AriesIntegration", "Verifier reported a problem while verifying the presentation - ${it.message.description.en}")
                    }
                    if (it.message is MediationProblemReportMessage) {
                        Log.e("AriesIntegration", "Mediator reported a problem - ${it.message.description.en}")
                    }
                }
            }
        } catch (e: Exception) {
            Log.e("AriesIntegration", "Unable to subscribe: ${e.localizedMessage}")

            result.error("1", e.message, null)
        }

        result.success(mapOf("error" to "", "result" to true))
    }

    fun shutdown(lifecycleScope: LifecycleCoroutineScope, result: MethodChannel.Result) {
        Log.d("AriesIntegration", "shutdown called from Kotlin...")

        validateAgent()

        lifecycleScope.launch(Dispatchers.Main) {
            try {
                agent!!.shutdown()
                agent = null;
                subscribed = false;

                result.success(mapOf("error" to "", "result" to true))
            } catch (e: Exception) {
                Log.e("AriesIntegration", "Unable to shutdown agent: ${e.localizedMessage}")

                result.error("1", e.message, null)
            }
        }
    }

    fun acceptCredentialOffer(credentialRecordId: String?, protocolVersion: String?, result: MethodChannel.Result) {
        Log.d("AriesIntegration", "accept offer called from Kotlin...")

        validateNotNull("CredentialRecordId", credentialRecordId)
        validateNotNull("ProtocolVersion", protocolVersion)
        validateAgent()

        try {
            runBlocking { CredentialUtils.acceptOffer(agent!!, credentialRecordId!!, protocolVersion!!) }

            result.success(mapOf("error" to "", "result" to true))
        } catch (e: Exception) {
            Log.e("AriesIntegration","Failed to accept a credential offer: ${e.localizedMessage}")

            result.error("1", e.message, null)
        }
    }

    fun declineCredentialOffer(credentialRecordId: String?, protocolVersion: String?, result: MethodChannel.Result) {
        Log.d("AriesIntegration", "decline offer called from Kotlin...")

        validateNotNull("CredentialRecordId", credentialRecordId)
        validateNotNull("ProtocolVersion", protocolVersion)
        validateAgent()

        try {
            runBlocking { CredentialUtils.declineOffer(agent!!, credentialRecordId!!, protocolVersion!!) }

            result.success(mapOf("error" to "", "result" to true))
        } catch (e: Exception) {
            Log.e("AriesIntegration","Failed to decline a credential: ${e.localizedMessage}")

            result.error("1", e.message, null)
        }
    }

    fun acceptProofOffer(proofRecordId: String?, selectedCredentialsAttributes: Map<String, String>?, selectedCredentialsPredicates: Map<String, String>?, result: MethodChannel.Result) {
        Log.d("AriesIntegration", "acceptProofOffer: $proofRecordId")

        validateNotNull("ProofRecordId", proofRecordId)
        validateNotNull("SelectedCredentialsAttributes", selectedCredentialsAttributes)
        validateNotNull("SelectedCredentialsPredicates", selectedCredentialsPredicates)
        validateAgent()

        try {
            runBlocking { ProofUtils.acceptRequest(agent!!, proofRecordId!!, selectedCredentialsAttributes!!, selectedCredentialsPredicates!!) }

            result.success(mapOf("error" to "", "result" to true))
        } catch (e: Exception) {
            Log.e("AriesIntegration","Failed to present proof: ${e.localizedMessage}")

            result.error("1", e.message, null)
        }
    }

    fun declineProofOffer(proofRecordId: String?, result: MethodChannel.Result) {
        Log.d("AriesIntegration", "declineProofOffer: $proofRecordId")

        validateNotNull("ProofRecordId", proofRecordId)
        validateAgent()

        try {
            runBlocking { agent!!.proofs.declineRequest(proofRecordId!!) }

            result.success(mapOf("error" to "", "result" to true))
        } catch (e: Exception) {
            Log.e("AriesIntegration","Failed to decline a proof: ${e.localizedMessage}")

            result.error("1", e.message, null)
        }
    }

    fun removeCredential(credentialRecordId: String?, result: MethodChannel.Result) {
        Log.d("AriesIntegration", "decline offer called from Kotlin...")

        validateNotNull("CredentialRecordId", credentialRecordId)
        validateAgent()

        try {
            val deleteResult = runBlocking { agent?.credentialRepository?.deleteById(credentialRecordId!!) }

            Log.d("AriesIntegration","deleteResult: ${deleteResult.toString()}")

            result.success(mapOf("error" to "", "result" to true))
        } catch (e: Exception) {
            Log.e("AriesIntegration","Failed to remove a credential: ${e.localizedMessage}")

            result.error("1", e.message, null)
        }
    }

    fun removeConnection(connectionRecordId: String?, result: MethodChannel.Result) {
        Log.d("AriesIntegration", "decline offer called from Kotlin...")

        validateNotNull("ConnectionRecordId", connectionRecordId)
        validateAgent()

        try {
            val deleteResult = runBlocking { agent?.connectionRepository?.deleteById(connectionRecordId!!) }

            Log.d("AriesIntegration","deleteResult: ${deleteResult.toString()}")

            result.success(mapOf("error" to "", "result" to true))
        } catch (e: Exception) {
            Log.e("AriesIntegration","Failed to remove a connection: ${e.localizedMessage}")

            result.error("1", e.message, null)
        }
    }

    fun getConnectionHistory(connectionId: String?, historyTypes: List<String>?, result: MethodChannel.Result) {
        Log.d("AriesIntegration", "getConnectionHistory called from Kotlin...")

        validateNotNull("ConnectionId", connectionId)
        validateNotNull("HistoryTypes", historyTypes)
        validateAgent()

        try {
            val connectionHistory = runBlocking { ConnectionUtils.getHistoryFromTypes(agent!!, historyTypes!!, connectionId!!) }

            result.success(mapOf("error" to "", "result" to JsonConverter.toJson(connectionHistory)))
        } catch (e: Exception) {
            Log.e("AriesIntegration", "Cannot get connectionHistory: ${e.message}")
            result.error("1", "Cannot get connectionHistory: ${e.message}", null)
        }
    }

    fun getCredentialHistory(credentialRecordId: String?, result: MethodChannel.Result) {
        Log.d("AriesIntegration", "getCredentialHistory called from Kotlin...")

        validateNotNull("CredentialRecordId", credentialRecordId)
        validateAgent()

        try {
            val credentialHistory = runBlocking { CredentialUtils.getHistory(agent!!, credentialRecordId!!) }

            result.success(mapOf("error" to "", "result" to JsonConverter.toJson(credentialHistory)))
        } catch (e: Exception) {
            Log.e("AriesIntegration", "Cannot get credentialHistory: ${e.message}")
            result.error("1", "Cannot get credentialHistory: ${e.message}", null)
        }
    }

    fun generateInvitation(deviceLabel: String?, result: MethodChannel.Result) {
        Log.d("AriesIntegration", "generateInvitation called from Kotlin...")

        validateNotNull("DeviceLabel", deviceLabel)
        validateAgent()

        try {
            val config = CreateOutOfBandInvitationConfig(
                label = deviceLabel!!,
                handshake = true,
            )

            val outOfBandRecord = runBlocking { agent!!.oob.createInvitation(config) }

            val mediatorBaseUrl = mediatorUrl!!.substringBefore("?")

            val invitation: String = outOfBandRecord.outOfBandInvitation.toUrl(mediatorBaseUrl)

            result.success(mapOf("error" to "", "result" to invitation))
        } catch (e: Exception) {
            Log.e("AriesIntegration", "Cannot generate invitation: ${e.message}")
            result.error("1", "Cannot generate invitation: ${e.message}", null)
        }
    }

    private fun copyResourceFile(applicationContext: Context, resource: String) {
        val inputStream = applicationContext.assets.open(resource)
        val file = File(applicationContext.filesDir.absolutePath, resource)
        file.outputStream().use { inputStream.copyTo(it) }
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