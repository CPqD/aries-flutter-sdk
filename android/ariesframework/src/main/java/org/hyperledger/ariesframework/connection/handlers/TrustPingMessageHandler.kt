package org.hyperledger.ariesframework.connection.handlers

import android.util.Log
import org.hyperledger.ariesframework.InboundMessageContext
import org.hyperledger.ariesframework.OutboundMessage
import org.hyperledger.ariesframework.agent.Agent
import org.hyperledger.ariesframework.agent.MessageHandler
import org.hyperledger.ariesframework.connection.messages.TrustPingMessage
import org.hyperledger.ariesframework.connection.models.ConnectionState

class TrustPingMessageHandler(val agent: Agent) : MessageHandler {
    override val messageType = TrustPingMessage.type

    override suspend fun handle(messageContext: InboundMessageContext): OutboundMessage? {
        Log.d("TrustPingMessageHandler","--> handle\n\n")

        val connection = messageContext.connection
        if (connection != null && connection.state == ConnectionState.Responded) {
            agent.connectionService.updateState(connection, ConnectionState.Complete)
        }
        return null
    }
}
