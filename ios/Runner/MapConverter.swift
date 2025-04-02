//
//  Channels.swift
//  Runner
//
//  Created by serpro on 19/02/25.
//

import AriesFramework

class MapConverter {
    static func toMap(_ obj: ConnectionRecord) -> [String: Any?]? {
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
    
    static func toMap(_ obj: CredentialRecord) -> [String: Any?]? {
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
    
    static func toMap(_ obj: CredentialExchangeRecord)-> [String: Any?]? {
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
    
    static func toMap(_ obj: DidCommMessageRecord)-> [String: Any?]? {
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
    
    static func toMap(_ obj: DidDoc?)-> [String: Any?]? {
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
    
    static func toMap(_ obj: ConnectionInvitationMessage)-> [String: Any?]? {
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
    
    static func toMap(_ obj: OutOfBandInvitation)-> [String: Any?]? {
        let text = obj.toJsonString()
        if let data = text.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
    }
    
    static func toMap(_ obj: ProofExchangeRecord)-> [String: Any?]? {
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
    
    static func toMap(_ obj: BasicMessageRecord)-> [String: Any?]? {
        let encoder = JSONEncoder()
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
}

