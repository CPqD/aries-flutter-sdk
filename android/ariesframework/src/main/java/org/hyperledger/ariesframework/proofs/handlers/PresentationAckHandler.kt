package org.hyperledger.ariesframework.proofs.handlers

import android.util.Log
import org.hyperledger.ariesframework.InboundMessageContext
import org.hyperledger.ariesframework.OutboundMessage
import org.hyperledger.ariesframework.agent.Agent
import org.hyperledger.ariesframework.agent.MessageHandler
import org.hyperledger.ariesframework.proofs.messages.PresentationAckMessage

class PresentationAckHandler(val agent: Agent) : MessageHandler {
    override val messageType = PresentationAckMessage.type

    override suspend fun handle(messageContext: InboundMessageContext): OutboundMessage? {
        Log.e("PresentationAckHandler","--> handle\n\n")


        agent.proofService.processAck(messageContext)
        return null
    }
}
