package br.org.serpro.did_agent.utils

import com.google.gson.Gson
import org.hyperledger.ariesframework.anoncreds.storage.CredentialRecord
import org.hyperledger.ariesframework.connection.messages.ConnectionInvitationMessage
import org.hyperledger.ariesframework.connection.models.didauth.DidDoc
import org.hyperledger.ariesframework.connection.models.didauth.DidDocService
import org.hyperledger.ariesframework.connection.models.didauth.publicKey.PublicKey
import org.hyperledger.ariesframework.connection.repository.ConnectionRecord
import org.hyperledger.ariesframework.credentials.repository.CredentialExchangeRecord
import org.hyperledger.ariesframework.oob.messages.OutOfBandInvitation
import org.hyperledger.ariesframework.proofs.models.RequestedAttribute
import org.hyperledger.ariesframework.proofs.models.RequestedPredicate
import org.hyperledger.ariesframework.proofs.repository.ProofExchangeRecord
import org.hyperledger.ariesframework.revocationnotification.model.RevocationNotification
import org.hyperledger.ariesframework.storage.DidCommMessageRecord

class JsonConverter {
    companion object {
        fun toMap(connection: ConnectionRecord): Map<String, Any?> {
            return mapOf(
                "id" to connection.id,
                "createdAt" to connection.createdAt.toString(),
                "updatedAt" to connection.updatedAt.toString(),
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

        fun toMap(credentialRecord: CredentialRecord): Map<String, Any?> {
            return mapOf(
                "recordId" to credentialRecord.id,
                "credentialId" to credentialRecord.credentialId,
                "attributes" to credentialRecord.parseCredential(credentialRecord.credential),
                "createdAt" to credentialRecord.createdAt.toString(),
                "updatedAt" to credentialRecord.updatedAt.toString(),
                "revocationId" to credentialRecord.credentialRevocationId,
                "linkSecretId" to credentialRecord.linkSecretId,
                "credential" to credentialRecord.credential,
                "schemaId" to credentialRecord.schemaId,
                "schemaName" to credentialRecord.schemaName,
                "schemaVersion" to credentialRecord.schemaVersion,
                "schemaIssuerId" to credentialRecord.schemaIssuerId,
                "issuerId" to credentialRecord.issuerId,
                "definitionId" to credentialRecord.credentialDefinitionId,
                "revocationRegistryId" to credentialRecord.revocationRegistryId,
                "revocationNotification" to credentialRecord.revocationNotification?.let { toMap(it) }
            )
        }

        fun toMap(revocationNotification: RevocationNotification): Map<String, Any?> {
            return mapOf(
                "revocationDate" to revocationNotification.revocationDate.toInstant().toString(),
                "comment" to revocationNotification.comment
            )
        }

        fun toMap(credentialExchangeRecord: CredentialExchangeRecord): Map<String, Any?> {
            return mapOf(
                "id" to credentialExchangeRecord.id,
                "createdAt" to credentialExchangeRecord.createdAt.toString(),
                "updatedAt" to credentialExchangeRecord.updatedAt.toString(),
                "connectionId" to credentialExchangeRecord.connectionId,
                "threadId" to credentialExchangeRecord.threadId,
                "state" to credentialExchangeRecord.state,
                "protocolVersion" to credentialExchangeRecord.protocolVersion,
            )
        }

        fun toMap(didCommMessage: DidCommMessageRecord): Map<String, Any?> {
            return mapOf(
                "id" to didCommMessage.id,
                "tags" to didCommMessage.getTags(),
                "createdAt" to didCommMessage.createdAt.toString(),
                "updatedAt" to didCommMessage.updatedAt.toString(),
                "message" to didCommMessage.message,
                "role" to didCommMessage.role,
                "associatedRecordId" to didCommMessage.associatedRecordId,
            )
        }

        fun toMap(didDoc: DidDoc): Map<String, Any?> {
            return mapOf(
                "id" to didDoc.id,
                "context" to didDoc.context,
                "publicKey" to toPublicKeyList(didDoc.publicKey),
                "authentication" to toStringList(didDoc.authentication),
                "service" to toDidDocServiceList(didDoc.service),
            )
        }

        fun toMap(didDocService: DidDocService): Map<String, Any?> {
            return mapOf(
                "id" to didDocService.id
            )
        }

        fun toMap(requestedAttribute: RequestedAttribute): Map<String, Any?> {
            return mapOf(
                "credentialId" to requestedAttribute.credentialId,
                "schemaId" to requestedAttribute.credentialInfo?.schemaId,
                "credentialDefinitionId" to requestedAttribute.credentialInfo?.credentialDefinitionId,
                "attributes" to requestedAttribute.credentialInfo?.attributes,
                "revoked" to requestedAttribute.revoked,
            )
        }

        fun toMap(requestedPredicate: RequestedPredicate): Map<String, Any?> {
            return mapOf(
                "credentialId" to requestedPredicate.credentialId,
                "schemaId" to requestedPredicate.credentialInfo?.schemaId,
                "credentialDefinitionId" to requestedPredicate.credentialInfo?.credentialDefinitionId,
                "attributes" to requestedPredicate.credentialInfo?.attributes,
                "revoked" to requestedPredicate.revoked,
                "predicateError" to ""
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
            )
        }

        fun toMap(proofExchangeRecord: ProofExchangeRecord): Map<String, Any?> {
            return mapOf(
                "id" to proofExchangeRecord.id,
                "createdAt" to proofExchangeRecord.createdAt.toString(),
                "updatedAt" to proofExchangeRecord.updatedAt.toString(),
                "connectionId" to proofExchangeRecord.connectionId,
                "threadId" to proofExchangeRecord.threadId,
                "state" to proofExchangeRecord.state,
            )
        }

        fun toMap(publicKey: PublicKey): Map<String, Any?> {
            return mapOf(
                "id" to publicKey.id,
                "controller" to publicKey.controller,
                "value" to publicKey.value,
            )
        }

        fun toStringList(objs: List<Any>): List<String> {
            val result = mutableListOf<String>()

            for (obj in objs) {
                result.add(obj.toString())
            }

            return result
        }

        fun toDidDocServiceList(didDocServices: List<DidDocService>): List<Map<String, Any?>> {
            val result = mutableListOf<Map<String, Any?>>()

            for (didDocService in didDocServices) {
                result.add(toMap(didDocService))
            }

            return result
        }

        fun toPublicKeyList(publicKeys: List<PublicKey>): List<Map<String, Any?>> {
            val result = mutableListOf<Map<String, Any?>>()

            for (publicKey in publicKeys) {
                result.add(toMap(publicKey))
            }

            return result
        }

        fun toRequestedAttributesList(requestedAttributes: List<RequestedAttribute>): List<Map<String, Any?>> {
            val result = mutableListOf<Map<String, Any?>>()

            for (requestedAttribute in requestedAttributes) {
                result.add(toMap(requestedAttribute))
            }

            return result
        }

        fun toJson(value: Any): String? {
            return Gson().toJson(value)
        }
    }
}