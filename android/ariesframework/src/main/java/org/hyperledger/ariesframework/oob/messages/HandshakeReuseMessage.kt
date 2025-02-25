package org.hyperledger.ariesframework.oob.messages

import kotlinx.serialization.Serializable
import org.hyperledger.ariesframework.agent.AgentMessage
import org.hyperledger.ariesframework.agent.decorators.ThreadDecorator

@Serializable
class HandshakeReuseMessage() : AgentMessage(generateId(), HandshakeReuseMessage.type) {
    constructor(parentThreadId: String) : this() {
        this.thread = ThreadDecorator(id, parentThreadId)
    }

    companion object {
        const val type = "https://didcomm.org/out-of-band/1.1/handshake-reuse"
    }
}
