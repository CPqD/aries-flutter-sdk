package org.hyperledger.ariesframework.routing.handlers

import android.util.Log
import org.hyperledger.ariesframework.InboundMessageContext
import org.hyperledger.ariesframework.OutboundMessage
import org.hyperledger.ariesframework.agent.Agent
import org.hyperledger.ariesframework.agent.MessageHandler
import org.hyperledger.ariesframework.routing.messages.KeylistUpdateResponseMessage

class KeylistUpdateResponseHandler(val agent: Agent) : MessageHandler {
    override val messageType = KeylistUpdateResponseMessage.type

    override suspend fun handle(messageContext: InboundMessageContext): OutboundMessage? {
        Log.e("KeylistUpdateResponseHandler","--> handle\n\n")

        agent.mediationRecipient.processKeylistUpdateResults(messageContext)
        return null
    }
}
