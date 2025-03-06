package org.hyperledger.ariesframework.credentials.handlers

import android.util.Log
import org.hyperledger.ariesframework.InboundMessageContext
import org.hyperledger.ariesframework.OutboundMessage
import org.hyperledger.ariesframework.agent.Agent
import org.hyperledger.ariesframework.agent.MessageHandler
import org.hyperledger.ariesframework.credentials.messages.IssueCredentialMessage
import org.hyperledger.ariesframework.credentials.models.AcceptCredentialOptions
import org.hyperledger.ariesframework.credentials.models.AutoAcceptCredential

class IssueCredentialHandler(val agent: Agent) : MessageHandler {
    override val messageType = IssueCredentialMessage.type

    override suspend fun handle(messageContext: InboundMessageContext): OutboundMessage? {
        Log.e("IssueCredentialHandler","--> handle(messageContext: ${messageContext.toString()})\n\n")

        val credentialRecord = agent.credentialService.processCredential(messageContext)

        if (credentialRecord.autoAcceptCredential == AutoAcceptCredential.Always ||
            agent.agentConfig.autoAcceptCredential == AutoAcceptCredential.Always
        ) {
            val message = agent.credentialService.createAck(AcceptCredentialOptions(credentialRecord.id))
            return OutboundMessage(message, messageContext.connection!!)
        }

        return null
    }
}
