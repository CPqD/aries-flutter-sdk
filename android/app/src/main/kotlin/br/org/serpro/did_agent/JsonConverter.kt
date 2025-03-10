package br.org.serpro.did_agent

import com.google.gson.Gson
import org.hyperledger.ariesframework.anoncreds.storage.CredentialRecord
import org.hyperledger.ariesframework.connection.messages.ConnectionInvitationMessage
import org.hyperledger.ariesframework.connection.models.ConnectionState
import org.hyperledger.ariesframework.connection.models.didauth.DidDoc
import org.hyperledger.ariesframework.connection.repository.ConnectionRecord
import org.hyperledger.ariesframework.oob.messages.OutOfBandInvitation

class JsonConverter {
    companion object {
        fun toMap(connection: ConnectionRecord): Map<String, Any?> {
            return mapOf(
                "id" to connection.id,
                "state" to connection.state.toString(),
                "role" to connection.role,
                "did" to connection.did,
                "didDoc" to toMap(connection.didDoc),
                "verkey" to connection.verkey,
                "theirDidDoc" to connection.theirDidDoc?.let { toMap(it) },
                "theirDid" to connection.theirDid,
                "theirLabel" to connection.theirLabel,
                "invitation" to connection.invitation?.let { toMap(it) },
                "alias" to connection.alias,
                "autoAcceptConnection" to connection.autoAcceptConnection,
                "imageUrl" to connection.imageUrl,
                "multiUseInvitation" to connection.multiUseInvitation,
                "outOfBandInvitation" to connection.outOfBandInvitation?.let { toMap(it) },
                "threadId" to connection.threadId,
                "mediatorId" to connection.mediatorId,
                "errorMessage" to connection.errorMessage,
            )
        }

        fun toMap(credential: CredentialRecord): Map<String, Any?> {
            return mapOf(
                "id" to credential.id,
                "revocationId" to credential.credentialRevocationId,
                "linkSecretId" to credential.linkSecretId,
                "credential" to credential.credential,
                "schemaId" to credential.schemaId,
                "schemaName" to credential.schemaName,
                "schemaVersion" to credential.schemaVersion,
                "schemaIssuerId" to credential.schemaIssuerId,
                "issuerId" to credential.issuerId,
                "definitionId" to credential.credentialDefinitionId,
                "revocationRegistryId" to credential.revocationRegistryId
            )
        }

        fun toMap(didDoc: DidDoc): Map<String, Any?> {
            return mapOf(
                "id" to didDoc.id,
                "context" to didDoc.context,
                "publicKey" to didDoc.publicKey,
                "authentication" to didDoc.authentication,
                "service" to didDoc.service,
            )
        }

        fun toMap(invitation: ConnectionInvitationMessage): Map<String, Any?> {
            return mapOf(
                "id" to invitation.id,
                "label" to invitation.label,
                "imageUrl" to invitation.imageUrl,
                "did" to invitation.did,
                "recipientKeys" to invitation.recipientKeys,
                "serviceEndpoint" to invitation.serviceEndpoint,
                "routingKeys" to invitation.routingKeys,
            )
        }

        fun toMap(outOfBandInvitation: OutOfBandInvitation): Map<String, Any?> {
            return mapOf(
                "id" to outOfBandInvitation.id,
                "label" to outOfBandInvitation.label,
                "goalCode" to outOfBandInvitation.goalCode,
                "goal" to outOfBandInvitation.goal,
                "accept" to outOfBandInvitation.accept,
                "handshakeProtocols" to outOfBandInvitation.handshakeProtocols,
                "requests" to outOfBandInvitation.requests,
                "services" to outOfBandInvitation.services,
            )
        }

        fun toJson(value: Any): String? {
            return Gson().toJson(value)
        }
    }
}