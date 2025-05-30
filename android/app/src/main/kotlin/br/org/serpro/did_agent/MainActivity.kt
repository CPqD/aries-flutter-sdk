package br.org.serpro.did_agent

import androidx.lifecycle.lifecycleScope
import android.content.Context
import android.util.Log
import br.org.serpro.did_agent.utils.JsonConverter
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import org.hyperledger.ariesframework.basicmessage.repository.BasicMessageRecord
import kotlin.Exception

class MainActivity: FlutterFragmentActivity() {
    companion object {
        private const val INTEGRITYCHANNEL = "br.gov.serprocpqd/wallet"
    }

    private lateinit var ariesIntegration: AriesIntegration
    private lateinit var methodChannel: MethodChannel

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine)

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, INTEGRITYCHANNEL)

        ariesIntegration = AriesIntegration(this)

        methodChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "init" -> {
                    try {
                        val mediatorUrl = call.argument<String>("mediatorUrl")
                        val sharedPreferences = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)

                        ariesIntegration.init(mediatorUrl, sharedPreferences, result)
                    } catch (e: Exception) {
                        result.error("1", "Erro ao inicializar agente: $e", null)
                    }
                }
                "openwallet" -> {
                    try {
                        ariesIntegration.openWallet(applicationContext, result)
                    } catch (e: Exception) {
                        result.error("1", "Erro ao processar o methodchannel openwallet: $e", null)
                    }
                }
                "getCredentials" -> {
                    try {
                        ariesIntegration.getCredentials(result)
                    } catch (e: Exception) {
                        result.error("1", "Erro ao processar o methodchannel getCredentials: $e", null)
                    }
                }
                "getCredential" -> {
                    try {
                        val credentialId = call.argument<String>("credentialId")

                        ariesIntegration.getCredential(credentialId, result)
                    } catch (e: Exception) {
                        result.error("1", "Erro ao processar o methodchannel getCredentials: $e", null)
                    }
                }
                "getConnections" -> {
                    try {
                        var hideMediator = call.argument<Boolean>("hideMediator")

                        if (hideMediator == null) {
                            hideMediator = false
                        }

                        ariesIntegration.getConnections(hideMediator, result)
                    } catch (e: Exception) {
                        result.error("1", "Erro ao processar o methodchannel getConnections: $e", null)
                    }
                }
                "getCredentialsOffers" -> {
                    try {
                        ariesIntegration.getCredentialsOffers(result)
                    } catch (e: Exception) {
                        result.error("1", "Erro ao processar o methodchannel getCredentialsOffers: $e", null)
                    }
                }
                "getDidCommMessage" -> {
                    try {
                        val associatedRecordId = call.argument<String>("associatedRecordId")

                        ariesIntegration.getDidCommMessage(associatedRecordId, result)
                    } catch (e: Exception) {
                        result.error("1", "Erro ao processar o methodchannel getDidCommMessage: $e", null)
                    }
                }
                "getDidCommMessagesByRecord" -> {
                    try {
                        val associatedRecordId = call.argument<String>("associatedRecordId")

                        ariesIntegration.getDidCommMessagesByRecord(associatedRecordId, result)
                    } catch (e: Exception) {
                        result.error("1", "Erro ao processar o methodchannel getDidCommMessageSent: $e", null)
                    }
                }
                "getProofOffers" -> {
                    try {
                        ariesIntegration.getProofOffers(result)
                    } catch (e: Exception) {
                        result.error("1", "Erro ao processar o methodchannel getProofOffers: $e", null)
                    }
                }
                "getProofOfferDetails" -> {
                    try {
                        val proofRecordId = call.argument<String>("proofRecordId")

                        ariesIntegration.getProofOfferDetails(proofRecordId, result)
                    } catch (e: Exception) {
                        result.error("1", "Erro ao processar o methodchannel getProofOfferDetails: $e", null)
                    }
                }
                "receiveInvitation" -> {
                    try {
                        val invitationUrl = call.argument<String>("invitationUrl")

                        ariesIntegration.receiveInvitation(invitationUrl, result)
                    } catch (e: Exception) {
                        result.error("1", "Erro ao processar o methodchannel receiveInvitation: $e", null)
                    }
                }
                "subscribe" -> {
                    try {
                        ariesIntegration.subscribeEvents(lifecycleScope, result)
                    } catch (e: Exception) {
                        result.error("1", "Erro ao processar o methodchannel subscribe: $e", null)
                    }
                }
                "shutdown" -> {
                    try {
                        ariesIntegration.shutdown(lifecycleScope, result)
                    } catch (e: Exception) {
                        result.error("1", "Erro ao processar o methodchannel shutdown: $e", null)
                    }
                }
                "acceptCredentialOffer" -> {
                    try {
                        val credentialRecordId = call.argument<String>("credentialRecordId")
                        val protocolVersion = call.argument<String>("protocolVersion")

                        ariesIntegration.acceptCredentialOffer(credentialRecordId, protocolVersion, result)
                    }catch (e:Exception){
                        result.error("1","Erro ao processar o methodchannel acceptOffer: $e",null)
                    }
                }
                "declineCredentialOffer" -> {
                    try {
                        val credentialRecordId = call.argument<String>("credentialRecordId")
                        val protocolVersion = call.argument<String>("protocolVersion")

                        ariesIntegration.declineCredentialOffer(credentialRecordId, protocolVersion, result)
                    }catch (e:Exception){
                        result.error("1","Erro ao processar o methodchannel declineOffer: $e",null)
                    }
                }
                "acceptProofOffer" -> {
                    try {
                        val proofRecordId = call.argument<String>("proofRecordId")
                        val selectedCredentialsAttributes = call.argument<Map<String, String>>("selectedCredentialsAttributes")
                        val selectedCredentialsPredicates = call.argument<Map<String, String>>("selectedCredentialsPredicates")

                        ariesIntegration.acceptProofOffer(proofRecordId, selectedCredentialsAttributes, selectedCredentialsPredicates, result)
                    }catch (e:Exception){
                        result.error("1","Erro ao processar o methodchannel acceptProofOffer: $e",null)
                    }
                }
                "declineProofOffer" -> {
                    try {
                        val proofRecordId = call.argument<String>("proofRecordId")

                        ariesIntegration.declineProofOffer(proofRecordId, result)
                    }catch (e:Exception){
                        result.error("1","Erro ao processar o methodchannel declineProofOffer: $e",null)
                    }
                }
                "removeCredential" -> {
                    try {
                        val credentialRecordId = call.argument<String>("credentialRecordId")

                        ariesIntegration.removeCredential(credentialRecordId, result)
                    }catch (e:Exception){
                        result.error("1","Erro ao processar o methodchannel removeCredential: $e",null)
                    }
                }
                "removeConnection" -> {
                    try {
                        val connectionRecordId = call.argument<String>("connectionRecordId")

                        ariesIntegration.removeConnection(connectionRecordId, result)
                    }catch (e:Exception){
                        result.error("1","Erro ao processar o methodchannel removeConnection: $e",null)
                    }
                }
                "getConnectionHistory" -> {
                    try {
                        val connectionId = call.argument<String>("connectionId")
                        val historyTypes = call.argument<List<String>>("historyTypes")

                        ariesIntegration.getConnectionHistory(connectionId, historyTypes, result)
                    } catch (e: Exception) {
                        result.error("1", "Erro ao processar o methodchannel getConnectionHistory: $e", null)
                    }
                }
                "getCredentialHistory" -> {
                    try {
                        val credentialRecordId = call.argument<String>("credentialId")

                        ariesIntegration.getCredentialHistory(credentialRecordId, result)
                    } catch (e: Exception) {
                        result.error("1", "Erro ao processar o methodchannel getConnectionHistory: $e", null)
                    }
                }
                "getProofPresented" -> {
                    try {
                        val proofRecordId = call.argument<String>("proofRecordId")

                        ariesIntegration.getProofPresented(proofRecordId, result)
                    } catch (e: Exception) {
                        result.error("1", "Erro ao processar o methodchannel getProofPresented: $e", null)
                    }
                }
                "generateInvitation" -> {
                    try {
                        val deviceLabel = call.argument<String>("deviceLabel")

                        ariesIntegration.generateInvitation(deviceLabel, result)
                    } catch (e: Exception) {
                        result.error("1", "Erro ao processar o methodchannel generateInvitation: $e", null)
                    }
                }
                "sendMessage" -> {
                    try {
                        val connectionId = call.argument<String>("connectionId")
                        val message = call.argument<String>("message")

                        ariesIntegration.sendMessage(connectionId, message, result)
                    } catch (e: Exception) {
                        result.error("1", "Erro ao processar o methodchannel sendMessage: $e", null)
                    }
                }
                "requestProof" -> {
                    try {
                        val connectionId = call.argument<String>("connectionId")
                        val proofRequest = call.argument<Map<String, Any>?>("proofRequest")

                        ariesIntegration.requestProof(connectionId, proofRequest, result)
                    } catch (e: Exception) {
                        result.error("1", "Erro ao processar o methodchannel requestProof: $e", null)
                    }
                }

                else -> result.notImplemented()
            }
        }
    }

    fun sendBasicMessageToFlutter(basicMessageRecord: BasicMessageRecord) {
        val basicMessageRecordMap = JsonConverter.toMap(basicMessageRecord)

        methodChannel.invokeMethod(
            "basicMessageReceived",
            mapOf("basicMessageRecord" to JsonConverter.toJson(basicMessageRecordMap))
        )
    }

    fun sendCredentialToFlutter(id: String, state: String) {
        Log.e("MainActivity", "Invoking credentialReceived from Kotlin")
        methodChannel.invokeMethod("credentialReceived", mapOf("id" to id, "state" to state))
    }

    fun sendCredentialRevocationToFlutter(id: String) {
        Log.e("MainActivity", "Invoking credentialReceived from Kotlin")
        methodChannel.invokeMethod("credentialRevocationReceived", mapOf("id" to id))
    }

    fun sendProofToFlutter(id: String, state: String) {
        Log.e("MainActivity", "Invoking proofReceived from Kotlin")
        methodChannel.invokeMethod("proofReceived", mapOf("id" to id, "state" to state))
    }
}