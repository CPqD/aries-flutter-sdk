package org.hyperledger.ariesframework.connection.handlers

import android.util.Log
import org.hyperledger.ariesframework.InboundMessageContext
import org.hyperledger.ariesframework.OutboundMessage
import org.hyperledger.ariesframework.agent.Agent
import org.hyperledger.ariesframework.agent.MessageHandler
import org.hyperledger.ariesframework.connection.messages.DidExchangeRequestMessage

class DidExchangeRequestHandler(val agent: Agent) : MessageHandler {
    override val messageType = DidExchangeRequestMessage.type

    override suspend fun handle(messageContext: InboundMessageContext): OutboundMessage? {
        Log.e("DidExchangeRequestHandler","--> handle\n\n")

        val connectionRecord = agent.didExchangeService.processRequest(messageContext)
        if (connectionRecord.autoAcceptConnection == true || agent.agentConfig.autoAcceptConnections) {
            return agent.didExchangeService.createResponse(connectionRecord.id)
        }

        return null
    }
}
