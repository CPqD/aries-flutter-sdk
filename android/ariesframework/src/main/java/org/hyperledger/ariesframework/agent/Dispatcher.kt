package org.hyperledger.ariesframework.agent

import android.util.Log
import org.hyperledger.ariesframework.InboundMessageContext
import org.slf4j.LoggerFactory

class Dispatcher(val agent: Agent) {
    private val logger = LoggerFactory.getLogger(Dispatcher::class.java)
    var handlers = mutableMapOf<String, MessageHandler>()

    fun registerHandler(handler: MessageHandler) {
        handlers[handler.messageType] = handler
        handlers[replaceNewDidCommPrefixWithLegacyDidSov(handler.messageType)] = handler
    }

    suspend fun dispatch(messageContext: InboundMessageContext) {
        Log.e("AgentMessage","--> dispatch: ${messageContext.message.type}\n\n")

        logger.debug("Dispatching message of type: ${messageContext.message.type}")
        val handler = handlers[messageContext.message.type]
            ?: throw Exception("No handler for message type: ${messageContext.message.type}")

        try {
            val outboundMessage = handler.handle(messageContext)
            if (outboundMessage != null) {
                logger.debug("Finishing dispatch with message of type: ${outboundMessage.payload.type}")
                agent.messageSender.send(outboundMessage)
            } else {
                logger.debug("Finishing dispatch without response")
            }
        } catch (e: Exception) {
            logger.error("Failed to dispatch message of type: ${messageContext.message.type}")
            throw e
        }
    }

    fun getHandlerForType(messageType: String): MessageHandler? {
        return handlers[messageType]
    }

    fun canHandleMessage(message: AgentMessage): Boolean {
        return handlers[message.type] != null
    }

    companion object {
        fun replaceNewDidCommPrefixWithLegacyDidSov(messageType: String): String {
//            Log.e("AgentMessage","--> replaceNewDidCommPrefixWithLegacyDidSov($messageType)\n\n")

            val didSovPrefix = "did:sov:BzCbsNYhMrjHiqZDTUASHg;spec"
            val didCommPrefix = "https://didcomm.org"

            if (messageType.startsWith(didCommPrefix)) {
                return messageType.replace(didCommPrefix, didSovPrefix)
            }

            return messageType
        }
    }
}
