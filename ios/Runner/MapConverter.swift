//
//  Channels.swift
//  Runner
//
//  Created by serpro on 19/02/25.
//

import AriesFramework

class MapConverter {
    
    static func toMap(_ obj: DidDoc?)-> [String: Any?]? {
        let encoder = JSONEncoder()
        let data = try! encoder.encode(obj)
        do {
            return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        } catch {
            print(error.localizedDescription)
        }
        
        return nil
    }
    
    static func toMap(_ obj: DidDocService)-> [String: Any?]? {
        let encoder = JSONEncoder()
        // swiftlint:disable:next force_try
        let data = try! encoder.encode(obj)
        do {
            return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        } catch {
            print(error.localizedDescription)
        }
        
        return nil
    }
    
    static func toMap(_ obj: RequestedAttribute)-> [String: Any?]? {
        let encoder = JSONEncoder()
        // swiftlint:disable:next force_try
        let data = try! encoder.encode(obj)
        do {
            return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        } catch {
            print(error.localizedDescription)
        }
        
        return nil
    }
    
    static func toMap(_ obj: RequestedPredicate)-> [String: Any?]? {
        let encoder = JSONEncoder()
        // swiftlint:disable:next force_try
        let data = try! encoder.encode(obj)
        do {
            return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        } catch {
            print(error.localizedDescription)
        }
        
        return nil
    }
    
    static func toStringList(objs: Array<Any>) -> Array<String> {
        var result = Array<String>()
        
        for obj in objs {
            result.append("\(obj)")
        }
        
        return result
    }
    
    static func toDidDocServiceList(didDocServices: Array<DidDocService>)-> Array<Dictionary<String, Any?>> {
        var result = Array<Dictionary<String, Any?>>()
        
        for didDocService in didDocServices {
            if let didDocService = toMap(didDocService) {
                result.append(didDocService)
            }
        }
        
        return result
    }
    
    static func toRequestedAttributesList(requestedAttributes: Array<RequestedAttribute>) -> Array<[String: Any?]> {
        var result = Array<[String: Any?]>()
        
        for requestedAttribute in requestedAttributes {
            result.append(toMap(requestedAttribute)!)
        }
        
        return result
    }
    
    static func toRequestedPredicatesList(requestedPredicates: Array<RequestedPredicate>) -> Array<[String: Any?]> {
        var result = Array<[String: Any?]>()
        
        for requestedPredicate in requestedPredicates {
            result.append(toMap(requestedPredicate)!)
        }
        
        return result
    }
    
    //MARK: NOVOS
    static func toMap(_ obj : CredentialRecord) -> [String: Any?]? {
        
        return [
            "id" : obj.id,
            "createdAt" : "\(obj.createdAt)",
            "updatedAt" : obj.updatedAt == nil ? nil : "\(obj.updatedAt!)",
            "tags" : obj.tags,
            "credentialId" : obj.credentialId,
            "credentialRevocationId" : obj.credentialRevocationId,
            "revocationRegistryId" : obj.revocationRegistryId,
            "linkSecretId" : obj.linkSecretId,
            "credential" : obj.credential,
            "attributes" : obj.parseCredential(credentialJson: obj.credential),
            "schemaId" : obj.schemaId,
            "schemaName" : obj.schemaName,
            "schemaVersion" : obj.schemaVersion,
            "schemaIssuerId" : obj.schemaIssuerId,
            "issuerId" : obj.issuerId,
            "credentialDefinitionId" : obj.credentialDefinitionId,
            "revocationNotification" : toMap(obj.revocationNotification)
        ]
    }
    
    static func toMap(_ obj: ConnectionRecord?) -> [String: Any?]? {
        guard let obj = obj else {
            return nil
        }
        
        return [
            "id" : obj.id,
            "createdAt" : "\(obj.createdAt)",
            "updatedAt" : obj.updatedAt == nil ? nil : "\(obj.updatedAt!)",
            "tags" : obj.tags,
            "state" : convertConnectionState(obj.state),
            "role" : convertConnectionRole(obj.role),
            "didDoc" : toMap(obj.didDoc),
            "did" : obj.did,
            "verkey" : obj.verkey,
            "theirDidDoc" : toMap(obj.theirDidDoc),
            "theirDid" : obj.theirDid,
            "theirLabel" : obj.theirLabel,
            "invitation" : toMap(obj.invitation),
            "outOfBandInvitation" : toMap(obj.outOfBandInvitation),
            "alias" : obj.alias,
            "autoAcceptConnection" : obj.autoAcceptConnection,
            "imageUrl" : obj.imageUrl,
            "multiUseInvitation" : obj.multiUseInvitation,
            "threadId" : obj.threadId,
            "mediatorId" : obj.mediatorId,
            "errorMessage" : obj.errorMessage,
            "type" : ConnectionRecord.type,
        ]
    }
    
    
    static func toMap(_ revocation: RevocationNotification?) -> [String: Any?]? {
        return revocation == nil ? nil : [
            "comment" : revocation!.comment,
            "revocationDate": "\(revocation!.revocationDate)"
        ]
    }
    
    static func toMap(_ obj: ConnectionInvitationMessage?)-> [String: Any?]? {
        guard let obj = obj else {
            return nil
        }
        return [
            "id" : obj.id,
            "label" : obj.label,
            "imageUrl" : obj.imageUrl,
            "did" : obj.did,
            "recipientKeys" : obj.recipientKeys,
            "serviceEndpoint" : obj.serviceEndpoint,
            "routingKeys" : obj.routingKeys,
        ]
        
    }
    
    static func toMap(_ obj: OutOfBandInvitation?)-> [String: Any?]? {
        guard let obj = obj else {
            return nil
        }
        return [
            "id" : obj.id,
            "label" : obj.label,
            "goalCode" : obj.goalCode,
            "goal" : obj.goal,
            "accept" : obj.accept,
        ]
    }
    
    static func toMap(_ obj: DidCommMessageRecord?)-> [String: Any?]? {
        
        guard let obj = obj else {
            return nil
        }
        return [
            "id" : obj.id,
            "tags" : obj.tags,
            "createdAt" : "\(obj.createdAt)",
            "updatedAt" : obj.updatedAt == nil ? nil : "\(obj.updatedAt!)",
            "message" : obj.message,
            "role" : convertDidCommMessageRole(obj.role),
            "associatedRecordId" : obj.associatedRecordId,
        ]
    }
    
    static func toMap(_ obj: CredentialExchangeRecord?)-> [String: Any?]? {
        guard let obj = obj else {
            return nil
        }
        return [
            "id" : obj.id,
            "createdAt" : "\(obj.createdAt)",
            "updatedAt" : obj.updatedAt == nil ? nil : "\(obj.updatedAt!)",
            "connectionId" : obj.connectionId,
            "threadId" : obj.threadId,
            "state" : convertCredentialState(obj.state),
            "protocolVersion" : obj.protocolVersion,
        ]
    }
    
    static func toMap(_ obj: ProofExchangeRecord?)-> [String: Any?]? {
        guard let obj = obj else {
            return nil
        }
        return [
            "id" : obj.id,
            "createdAt" : "\(obj.createdAt)",
            "updatedAt" : obj.updatedAt == nil ? nil : "\(obj.updatedAt!)",
            "connectionId" : obj.connectionId,
            "threadId" : obj.threadId,
            "state" : convertProofState(obj.state),
        ]
        
    }
    
    static func toMap(_ obj: BasicMessageRecord?)-> [String: Any?]? {
        guard let obj = obj else {
            return nil
        }
        return [
            "id"  : obj.id,
            "createdAt" : "\(obj.createdAt)",
            "updatedAt" : obj.updatedAt == nil ? nil : "\(obj.updatedAt!)",
            "content"  : obj.content,
            "connectionRecord": toMap(obj.connectionRecord)
        ]
        
    }
    
    
    
    static func convertConnectionState(_ state: ConnectionState) -> String {
        switch state {
        case .Invited:
            return "Invited"
        case .Requested:
            return "Requested"
        case .Responded:
            return "Responded"
        case .Complete:
            return "Complete"
        }
    }
    
    static func convertConnectionRole(_ role: ConnectionRole) -> String {
        switch role {
        case .Invitee:
            return "Invitee"
        case .Inviter:
            return "Inviter"
        }
    }
    
    static func convertDidCommMessageRole(_ role: DidCommMessageRole) -> String {
        switch role {
        case .Sender:
            return "Sender"
        case .Receiver:
            return "Receiver"
        }
    }
    
    static func convertCredentialState(_ state: CredentialState) -> String {
        switch state {
        case .ProposalSent :
            return "ProposalSent"
        case .ProposalReceived :
            return "ProposalReceived"
        case .OfferSent :
            return "OfferSent"
        case .OfferReceived :
            return "OfferReceived"
        case .Declined :
            return "Declined"
        case .RequestSent :
            return "RequestSent"
        case .RequestReceived :
            return "RequestReceived"
        case .CredentialIssued :
            return "CredentialIssued"
        case .CredentialReceived :
            return "CredentialReceived"
        case .Done :
            return "Done"
        case .Revoked :
            return "Revoked"
        }
    }
    
    static func convertProofState(_ state: ProofState) -> String {
        switch state {
        case .ProposalSent :
            return "ProposalSent"
        case .ProposalReceived :
            return "ProposalReceived"
        case .RequestSent :
            return "RequestSent"
        case .RequestReceived :
            return "RequestReceived"
        case .PresentationSent :
            return "PresentationSent"
        case .PresentationReceived :
            return "PresentationReceived"
        case .Declined :
            return "Declined"
        case .Done :
            return "Done"
        }
    }
}

