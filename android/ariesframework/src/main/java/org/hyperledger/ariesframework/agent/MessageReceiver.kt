package org.hyperledger.ariesframework.agent

import android.util.Log
import org.hyperledger.ariesframework.DecryptedMessageContext
import org.hyperledger.ariesframework.EncryptedMessage
import org.hyperledger.ariesframework.InboundMessageContext
import org.hyperledger.ariesframework.connection.models.didauth.DidCommService
import org.hyperledger.ariesframework.connection.models.didauth.DidDoc
import org.hyperledger.ariesframework.connection.repository.ConnectionRecord
import org.hyperledger.ariesframework.routing.Routing
import org.slf4j.LoggerFactory

class MessageReceiver(val agent: Agent) {
    private val logger = LoggerFactory.getLogger(MessageReceiver::class.java)

    suspend fun receiveMessage(encryptedMessage: EncryptedMessage) {
        Log.e("MessageReceiver","--> receiveMessage - encryptedMessage: $encryptedMessage\n\n")

        try {
            val decryptedMessage = agent.wallet.unpack(encryptedMessage)
            logger.error("[$] receiveMessage - decryptedMessage: $decryptedMessage")

            val message = MessageSerializer.decodeFromString(decryptedMessage.plaintextMessage)
            logger.error("[$] receiveMessage - message: $message")

            val connection = findConnection(decryptedMessage, message)
            logger.error("[$] receiveMessage - connection: $connection")

            val messageContext = InboundMessageContext(
                message,
                decryptedMessage.plaintextMessage,
                connection,
                decryptedMessage.senderKey,
                decryptedMessage.recipientKey,
            )
            agent.dispatcher.dispatch(messageContext)
        } catch (e: Exception) {
            logger.error("[$] failed to receive message: $e")
        }
    }

    suspend fun receivePlaintextMessage(plaintextMessage: String, connection: ConnectionRecord) {
        try {
            Log.e("MessageReceiver","--> receivePlaintextMessage\n\n")

            logger.error("[$] receivePlaintextMessage - encryptedMessage: $plaintextMessage")

            val message = MessageSerializer.decodeFromString(plaintextMessage)
            val messageContext = InboundMessageContext(
                message,
                plaintextMessage,
                connection,
                null,
                null,
            )
            agent.dispatcher.dispatch(messageContext)
        } catch (e: Exception) {
            logger.error("[\$] failed to receive plainText message: $e")
        }
    }

    private suspend fun findConnection(decryptedMessage: DecryptedMessageContext, message: AgentMessage): ConnectionRecord? {
        Log.e("MessageReceiver","--> findConnection\n\n")


        var connection = findConnectionByMessageKeys(decryptedMessage)
        if (connection == null) {
            connection = findConnectionByMessageThreadId(message)
            if (connection != null) {
                updateConnectionTheirDidDoc(connection, decryptedMessage.senderKey)
            }
        }
        return connection
    }

    private suspend fun findConnectionByMessageThreadId(message: AgentMessage): ConnectionRecord? {
        Log.e("MessageReceiver","--> findConnectionByMessageThreadId($message)\n\n")


        val pthId = message.thread?.parentThreadId ?: ""
        val oobRecord = agent.outOfBandService.findByInvitationId(pthId)
        val invitationKey = oobRecord?.outOfBandInvitation?.invitationKey() ?: ""
        return agent.connectionService.findByInvitationKey(invitationKey)
    }

    private suspend fun updateConnectionTheirDidDoc(connection: ConnectionRecord, senderKey: String?) {
        Log.e("MessageReceiver","--> updateConnectionTheirDidDoc(${connection.toString()}, $senderKey)\n\n")


        if (senderKey == null) {
            return
        }
        val service = DidCommService(
            id = "${connection.id}#1",
            serviceEndpoint = Routing.DID_COMM_TRANSPORT_QUEUE,
            recipientKeys = listOf(senderKey),
        )

        val theirDidDoc = DidDoc(
            id = senderKey,
            publicKey = emptyList(),
            service = listOf(service),
            authentication = emptyList(),
        )
        connection.theirDidDoc = theirDidDoc
        agent.connectionRepository.update(connection)
    }

    private suspend fun findConnectionByMessageKeys(decryptedMessage: DecryptedMessageContext): ConnectionRecord? {
        Log.e("MessageReceiver","--> findConnectionByMessageKeys(${decryptedMessage.toString()})\n\n")

        return agent.connectionService.findByKeys(
            decryptedMessage.senderKey ?: "",
            decryptedMessage.recipientKey ?: "",
        )
    }
}
