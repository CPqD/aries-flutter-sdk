package org.hyperledger.ariesframework.credentials.handlers

import android.util.Log
import org.hyperledger.ariesframework.InboundMessageContext
import org.hyperledger.ariesframework.OutboundMessage
import org.hyperledger.ariesframework.agent.Agent
import org.hyperledger.ariesframework.agent.MessageHandler
import org.hyperledger.ariesframework.credentials.messages.RequestCredentialMessage
import org.hyperledger.ariesframework.credentials.models.AcceptRequestOptions
import org.hyperledger.ariesframework.credentials.models.AutoAcceptCredential

class RequestCredentialHandler(val agent: Agent) : MessageHandler {
    override val messageType = RequestCredentialMessage.type

    override suspend fun handle(messageContext: InboundMessageContext): OutboundMessage? {
        Log.e("RequestCredentialHandler","--> handle(messageContext: ${messageContext.toString()})\n\n")

        val credentialRecord = agent.credentialService.processRequest(messageContext)

        if (credentialRecord.autoAcceptCredential == AutoAcceptCredential.Always ||
            agent.agentConfig.autoAcceptCredential == AutoAcceptCredential.Always
        ) {
            val message = agent.credentialService.createCredential(AcceptRequestOptions(credentialRecord.id))
            return OutboundMessage(message, messageContext.connection!!)
        }

        return null
    }
}
