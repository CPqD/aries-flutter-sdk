package org.hyperledger.ariesframework.basicmessage.handlers

import android.util.Log
import org.hyperledger.ariesframework.InboundMessageContext
import org.hyperledger.ariesframework.OutboundMessage
import org.hyperledger.ariesframework.agent.Agent
import org.hyperledger.ariesframework.agent.AgentEvents
import org.hyperledger.ariesframework.agent.MessageHandler
import org.hyperledger.ariesframework.basicmessage.messages.BasicMessage

class BasicMessageHandler(val agent: Agent) : MessageHandler {
    override val messageType = BasicMessage.type

    override suspend fun handle(messageContext: InboundMessageContext): OutboundMessage? {
        Log.e("BasicMessageHandler","--> handle\n\n")

        val message = messageContext.message as BasicMessage
        agent.eventBus.publish(AgentEvents.BasicMessageEvent(message.content))
        return null
    }
}
