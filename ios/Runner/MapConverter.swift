//
//  Channels.swift
//  Runner
//
//  Created by serpro on 19/02/25.
//

import AriesFramework

class MapConverter {
    static func toMap(connection: ConnectionRecord) -> Dictionary<String, Any?>? {
        let encoder = JSONEncoder()
        // swiftlint:disable:next force_try
        let data = try! encoder.encode(connection)
        do {
            return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        } catch {
            print(error.localizedDescription)
        }
        return nil
    }
    
    static func toMap(credential: CredentialRecord) -> Dictionary<String, Any?>? {
        let encoder = JSONEncoder()
        // swiftlint:disable:next force_try
        let data = try! encoder.encode(credential)
        do {
            return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        } catch {
            print(error.localizedDescription)
        }
        
        return nil
    }
    
    static func toMap(credentialExchangeRecord: CredentialExchangeRecord)-> Dictionary<String, Any?>? {
        let encoder = JSONEncoder()
        // swiftlint:disable:next force_try
        let data = try! encoder.encode(credentialExchangeRecord)
        do {
            return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        } catch {
            print(error.localizedDescription)
        }
        
        return nil
    }
    
    static func toMap(didCommMessage: DidCommMessageRecord)-> Dictionary<String, Any?>? {
        let encoder = JSONEncoder()
        // swiftlint:disable:next force_try
        let data = try! encoder.encode(didCommMessage)
        do {
            return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        } catch {
            print(error.localizedDescription)
        }
        
        return nil
    }
    
    static func toMap(didDoc: DidDoc?)-> Dictionary<String, Any?>? {
        let encoder = JSONEncoder()
        // swiftlint:disable:next force_try
        let data = try! encoder.encode(didDoc)
        do {
            return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        } catch {
            print(error.localizedDescription)
        }
        
        return nil
    }
    
    static func toMap(didDocService: DidDocService)-> Dictionary<String, Any?>? {
        let encoder = JSONEncoder()
        // swiftlint:disable:next force_try
        let data = try! encoder.encode(didDocService)
        do {
            return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        } catch {
            print(error.localizedDescription)
        }
        
        return nil
    }
    
    static func toMap(invitation: ConnectionInvitationMessage)-> Dictionary<String, Any?>? {
        let encoder = JSONEncoder()
        // swiftlint:disable:next force_try
        let data = try! encoder.encode(invitation)
        do {
            return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        } catch {
            print(error.localizedDescription)
        }
        
        return nil
    }
    
    static func toMap(outOfBandInvitation: OutOfBandInvitation)-> Dictionary<String, Any?>? {
        let text = outOfBandInvitation.toJsonString()
        if let data = text.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
    }
    
    static func toMap(proofExchangeRecord: ProofExchangeRecord)-> Dictionary<String, Any?>? {
        let encoder = JSONEncoder()
        // swiftlint:disable:next force_try
        let data = try! encoder.encode(proofExchangeRecord)
        do {
            return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        } catch {
            print(error.localizedDescription)
        }
        
        return nil
    }
    
    static func toMap(requestedAttribute: RequestedAttribute)-> Dictionary<String, Any?>? {
        let encoder = JSONEncoder()
        // swiftlint:disable:next force_try
        let data = try! encoder.encode(requestedAttribute)
        do {
            return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        } catch {
            print(error.localizedDescription)
        }
        
        return nil
    }
    
    static func toMap(requestedPredicate: RequestedPredicate)-> Dictionary<String, Any?>? {
        let encoder = JSONEncoder()
        // swiftlint:disable:next force_try
        let data = try! encoder.encode(requestedPredicate)
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
            if let didDocService = toMap(didDocService: didDocService) {
                result.append(didDocService)
            }
        }
        
        return result
    }
    
    static func toRequestedAttributesList(requestedAttributes: Array<RequestedAttribute>) -> Array<[String: Any?]> {
        var result = Array<[String: Any?]>()
        
        for requestedAttribute in requestedAttributes {
            result.append(toMap(requestedAttribute : requestedAttribute)!)
        }
        
        return result
    }
    
    static func toRequestedPredicatesList(requestedPredicates: Array<RequestedPredicate>) -> Array<[String: Any?]> {
        var result = Array<[String: Any?]>()
        
        for requestedPredicate in requestedPredicates {
            result.append(toMap(requestedPredicate : requestedPredicate)!)
        }
        
        return result
    }
}

