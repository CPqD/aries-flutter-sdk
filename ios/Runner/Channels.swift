//
//  Channels.swift
//  Runner
//
//  Created by serpro on 02/04/25.
//


import AriesFramework

var agent: Agent!

extension AppDelegate {
    
    func channelWallet(controller : FlutterBinaryMessenger) {
        let channel = FlutterMethodChannel(name: channelName,
                                           binaryMessenger: controller)
        channel.setMethodCallHandler({
            [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            
            let args = self!.argsToMap(call.arguments)
            switch (call.method) {
            case "init":
                self!.initWallet(mediatorUrl: args?["mediatorUrl"] as? String, flutterResult: result)
            case "openwallet":
                self!.openWallet(flutterResult: result)
            case "getCredentials":
                self!.getCredentials(flutterResult: result)
            case "getCredential":
                self!.getCredential(credentialId: args?["credentialId"] as! String, flutterResult: result)
            case "getConnections":
                self!.getConnections( hideMediator: args?["hideMediator"] as! Bool, flutterResult: result)
            case "getCredentialsOffers":
                self!.getCredentialsOffers(flutterResult: result)
            case "getDidCommMessage":
                self!.getDidCommMessage(associatedRecordId: args?["associatedRecordId"] as! String, flutterResult: result)
            case "getDidCommMessagesByRecord":
                self!.getDidCommMessagesByRecord(associatedRecordId: args?["associatedRecordId"] as! String, flutterResult: result)
            case "getProofOffers":
                self!.getProofOffers(flutterResult: result)
            case "getProofOfferDetails":
                self!.getProofOfferDetails(proofRecordId: args?["proofRecordId"] as! String, flutterResult: result)
            case "receiveInvitation":
                self!.receiveInvitation(url: args?["invitationUrl"] as! String, flutterResult: result)
            case "shutdown":
                self!.shutdown(flutterResult: result)
            case "acceptCredentialOffer":
                self!.acceptCredentialOffer(credentialRecordId: args?["credentialRecordId"] as? String,
                                            protocolVersion: args?["protocolVersion"] as? String, flutterResult: result)
            case "declineCredentialOffer":
                self!.declineCredentialOffer(credentialRecordId: args?["credentialRecordId"] as? String, protocolVersion: args?["protocolVersion"] as? String,flutterResult: result)
            case "acceptProofOffer":
                self!.acceptProofOffer(proofRecordId:args?["proofRecordId"] as? String,
                                       selectedCredentialsAttributes: args?["selectedCredentialsAttributes"] as? [String : String], selectedCredentialsPredicates:args?["selectedCredentialsPredicates"] as? [String : String],
                                       flutterResult: result)
            case "declineProofOffer":
                self!.declineProofOffer(proofRecordId: args?["proofRecordId"] as? String, flutterResult: result)
            case "removeCredential":
                self!.removeCredential(credentialRecordId: args?["credentialRecordId"] as? String,flutterResult: result)
            case "removeConnection":
                self!.removeConnection(connectionId: args?["connectionRecordId"] as? String,flutterResult: result)
            case "getConnectionHistory":
                self!.getConnectionHistory(connectionId: args?["connectionId"] as! String,flutterResult: result)
            default:
                var dict : [String : Any] = [:]
                dict["error"] = ""
                dict["result"] = false
                result(dict)
            }
        })
    }
    
    func argsToMap(_ arguments: Any?) -> [String: Any]? {
        return arguments as? [String: Any]
    }
    
    //MARK: initWallet
    func initWallet (mediatorUrl : String?, flutterResult : @escaping FlutterResult) {
        guard let mediatorUrl = mediatorUrl else {
            sendError("mediatorUrl is null", flutterResult)
            return
        }
        
        self.mediatorUrl = mediatorUrl
        let userDefaults = UserDefaults.standard
        self.walletKey = userDefaults.value(forKey:"flutter.walletKey") as? String
        if (self.walletKey == nil) {
            do {
                self.walletKey = try Agent.generateWalletKey()
                userDefaults.set(self.walletKey, forKey: "flutter.walletKey")
                var dict : [String : Any] = [:]
                dict["error"] = ""
                dict["result"] = true
                flutterResult(dict)
            } catch let error{
                if let err = error as NSError? {
                    sendError(err, flutterResult)
                    return
                }
            }
        }
        else {
            var dict : [String : Any] = [:]
            dict["error"] = ""
            dict["result"] = true
            flutterResult(dict)
        }
    }
    
    //MARK: openWallet
    func openWallet(flutterResult : @escaping FlutterResult)  {
        
        let genesisPath = Bundle(for: AppDelegate.self).path(forResource: "bcovrin-genesis", ofType: "txn")
        let config = AgentConfig(walletKey: self.walletKey!,
                                 genesisPath: genesisPath!,
                                 mediatorConnectionsInvite: self.mediatorUrl,
                                 mediatorPickupStrategy: .Implicit,
                                 label: "MyWallet",
                                 autoAcceptCredential: .never,
                                 autoAcceptProof: .never)
        Task{
            do {
                agent = Agent(agentConfig: config, agentDelegate:  self)
                try await agent!.initialize()
                var dict : [String : Any] = [:]
                dict["error"] = ""
                dict["result"] = true
                
                flutterResult(dict)
            } catch  let error{
                print("Cannot initialize agent: \(error)")
                sendError(error, flutterResult)
                
            }
        }
    }
    
    //MARK: getCredentials
    func getCredentials(flutterResult : @escaping FlutterResult) {
        Task {
            let credentials =  await agent!.credentialRepository?.getAll()
            var listCredentials : [[String : Any?]] = []
            for credential in credentials ?? [] {
                if let rowDict = MapConverter.toMap(credential) {
                    listCredentials.append(rowDict)
                }
            }
            var dict : [String : Any] = [:]
            dict["error"] = ""
            dict["result"] = toJson(listCredentials)
            flutterResult(dict)
        }
    }
    
    //MARK: getCredential
    func getCredential(credentialId: String, flutterResult : @escaping FlutterResult) {
        Task {
            do{
                let credential =  try await agent!.credentialRepository?.getById(credentialId)
                guard let credential else {
                    sendError("error: credential not found", flutterResult)
                    
                    return
                }
                
                var dict : [String : Any] = [:]
                dict["error"] = ""
                dict["result"] = toJson(MapConverter.toMap(credential) as Any)
                flutterResult(dict)

            } catch let error {
                sendError(error, flutterResult)
            }
        }
    }
    
    //MARK: getConnections
    func getConnections(hideMediator : Bool, flutterResult : @escaping FlutterResult) {
        Task {
            let connections =  await agent!.connectionRepository?.getAll()
            var list : [[String : Any?]] = []
            for connection in connections ?? [] {
                if(hideMediator && connection.mediatorId == nil){
                    continue
                }
                if let rowDict = MapConverter.toMap(connection) {
                    list.append(rowDict)
                    print(rowDict)
                }
            }
            var dict : [String : Any] = [:]
            dict["error"] = ""
            dict["result"] = toJson(list)
            flutterResult(dict)
        }
    }
    
    //MARK: getCredentialsOffers
    func getCredentialsOffers(flutterResult : @escaping FlutterResult) {
        Task {
            let credentialsOffers =  await agent!.credentialExchangeRepository?.findByQuery("{\"state\": \"\(CredentialState.OfferReceived.rawValue)\"}" )
            var listCredentials : [[String : Any?]] = []
            for credential in credentialsOffers ?? [] {
                if let rowDict = MapConverter.toMap( credential) {
                    listCredentials.append(rowDict)
                }
            }

            var dict : [String : Any] = [:]
            dict["error"] = ""
            dict["result"] = toJson(listCredentials)
            
            
            flutterResult(dict)
        }
    }
    
    //MARK: acceptCredentialOffer
    func acceptCredentialOffer (credentialRecordId : String?, protocolVersion: String?, flutterResult : @escaping FlutterResult) {
        guard let credentialId = credentialRecordId else {
            sendError("credentialRecordId is null", flutterResult)
            return
        }
        Task{
            let offerOption = AcceptOfferOptions(credentialRecordId: credentialId, autoAcceptCredential: .always)
            do {
                
                if (protocolVersion == "v2") {
                    _ = try await agent!.credentialsV2.acceptOffer(options: offerOption)
                } else {
                    _ = try await agent!.credentials.acceptOffer(options: offerOption)
                }
                var dict : [String : Any] = [:]
                dict["error"] = ""
                dict["result"] = true
                flutterResult(dict)
            } catch let error {
                sendError(error, flutterResult)
            }
        }
    }
    
    //MARK: declineCredentialOffer
    func declineCredentialOffer (credentialRecordId : String?, protocolVersion: String?,flutterResult : @escaping FlutterResult) {
        guard let credentialId = credentialRecordId else {
            sendError("credentialRecordId is null", flutterResult)
            return
        }
        Task{
            do {
                let acceptOfferOption = AcceptOfferOptions(
                    credentialRecordId: credentialId,
                    autoAcceptCredential : AutoAcceptCredential.never
                )
                
                if (protocolVersion == "v2") {
                    _ = try await agent!.credentialsV2.declineOffer(options: acceptOfferOption)
                } else {
                    _ = try await agent!.credentials.declineOffer(credentialRecordId: credentialId)
                }
                var dict : [String : Any] = [:]
                dict["error"] = ""
                dict["result"] = true
                flutterResult(dict)
            } catch let error {
                sendError(error, flutterResult)
            }
        }
    }
    
    //MARK: acceptProofOffer
    func acceptProofOffer (proofRecordId : String?, selectedCredentialsAttributes: [String: String]? , selectedCredentialsPredicates: [String: String]?, flutterResult : @escaping FlutterResult) {
        guard let proofId = proofRecordId else {
            sendError("proofRecordId is null", flutterResult)
            return
        }
        Task{
            do {
                let retrievedCredentials = try await agent!.proofs.getRequestedCredentialsForProofRequest(proofRecordId: proofId)
                var requestedCredentials = RequestedCredentials()
                
                retrievedCredentials.requestedAttributes.keys.forEach{ attributeName in
                    var attributeArray = retrievedCredentials.requestedAttributes[attributeName]
                    
                    var validAtributes = attributeArray?.filter { (attr) -> Bool in
                        attr.revoked != true && selectedCredentialsAttributes?[attributeName] == attr.credentialId
                    }
                    if (!(validAtributes?.isEmpty ?? true)) {
                        requestedCredentials.requestedAttributes[attributeName] = validAtributes![0]
                    }
                }
                
                retrievedCredentials.requestedPredicates.keys.forEach{ predicateName in
                    var predicateArray = retrievedCredentials.requestedPredicates[predicateName]
                    
                    var validPredicates = predicateArray?.filter { (attr) -> Bool in
                        attr.revoked != true && selectedCredentialsAttributes?[predicateName] == attr.credentialId
                    }
                    if (!(validPredicates?.isEmpty ?? true)) {
                        requestedCredentials.requestedPredicates[predicateName] = validPredicates![0]
                    }
                }
                
                _ = try await agent!.proofs.acceptRequest(proofRecordId: proofId, requestedCredentials:  requestedCredentials)
                var dict : [String : Any] = [:]
                dict["error"] = ""
                dict["result"] = true
                flutterResult(dict)
            } catch let error {
                sendError(error, flutterResult)
            }
        }
    }
    
    //MARK: declineProofOffer
    func declineProofOffer (proofRecordId : String?, flutterResult : @escaping FlutterResult) {
        guard let proofId = proofRecordId else {
            sendError("proofRecordId is null", flutterResult)
            return
        }
        Task{
            do {
                _ = try await agent!.proofs.declineRequest(proofRecordId: proofId)
                var dict : [String : Any] = [:]
                dict["error"] = ""
                dict["result"] = true
                flutterResult(dict)
            } catch let error {
                sendError(error, flutterResult)
            }
        }
    }
    
    //MARK: removeCredential
    func removeCredential (credentialRecordId : String?, flutterResult : @escaping FlutterResult) {
        guard let credentialId = credentialRecordId else {
            sendError("credentialRecordId is null", flutterResult)
            return
        }
        Task{
            do {
                _ = try await agent!.credentialRepository.deleteById(credentialId)
                var dict : [String : Any] = [:]
                dict["error"] = ""
                dict["result"] = true
                flutterResult(dict)
            } catch let error {
                sendError(error, flutterResult)
            }
        }
    }
    
    //MARK: removeConnection
    func removeConnection(connectionId: String?, flutterResult : @escaping FlutterResult) {
        guard let connId = connectionId else {
            sendError("connectionId is null", flutterResult)
            return
        }
        Task{
            do {
                _ = try await agent!.connectionRepository.deleteById(connId)
                var dict : [String : Any] = [:]
                dict["error"] = ""
                dict["result"] = true
                flutterResult(dict)
            } catch let error {
                sendError (error, flutterResult)
            }
        }
    }
    
    //MARK: receiveInvitation
    func receiveInvitation(url: String, flutterResult : @escaping FlutterResult) {
        Task {
            do {
                let (_, connection) = try await agent!.oob.receiveInvitationFromUrl(url)
                var dict : [String : Any] = [:]
                dict["error"] = ""
                dict["result"] = true
                flutterResult(dict)
            }  catch let error{
                sendError(error, flutterResult)
            }
        }
    }
    
    //MARK: shutdown
    func shutdown(flutterResult : @escaping FlutterResult) {
        Task {
            do {
                try await agent!.shutdown()
                var dict : [String : Any] = [:]
                dict["error"] = ""
                dict["result"] = true
                flutterResult(dict)
            } catch let error{
                sendError(error, flutterResult)
            }
        }
    }
    
    //MARK: getDidCommMessage
    func getDidCommMessage(associatedRecordId: String, flutterResult : @escaping FlutterResult) {
        Task {
            
                let didCommMessage =  await agent!.didCommMessageRepository?.findByQuery("{\"associatedRecordId\": \"\(associatedRecordId)\"}")
                if (didCommMessage == nil) {
                    sendError("didCommMessage not found", flutterResult)
                    return
                }
                if(didCommMessage?.count ?? 0 == 0) {
                    sendError("didCommMessage not found", flutterResult)
                    return
                }
                var dict : [String : Any] = [:]
                dict["error"] = ""
                dict["result"] = toJson(MapConverter.toMap( didCommMessage![0]) as Any)
                
                flutterResult(dict)
                
            
        }
    }
    
    //MARK: getProofOffers
    func getProofOffers(flutterResult : @escaping FlutterResult) {
        Task {
            print("inicio")
            let items =  await agent!.proofRepository.findByQuery("{\"state\": \"\(ProofState.RequestReceived)\"}")
            print("inicio 2")
            var list : [[String : Any?]] = []
            for item in items  {
                if let rowDict = MapConverter.toMap(item) {
                    
                    list.append(rowDict)
                }
            }
            flutterResult(list)
        }
    }
    
    //MARK: getProofOfferDetails
    func getProofOfferDetails(proofRecordId: String, flutterResult : @escaping FlutterResult) {
        Task {
            do{
                var attributesList : Array<[String : Any]> = []
                var predicatesList : Array<[String : Any]> = []
                
                
                var recordMessageType =  try await agent!.didCommMessageRepository.getSingleByQuery("{\"associatedRecordId\": \"\(proofRecordId)\"}")
                
                guard let proofRequestJson = await getProofRequestJson(proofRecordId: proofRecordId, recordMessageType:recordMessageType) else {
                    self.sendError("proofRequestJson is null", flutterResult)
                    return
                }
                
                let data = proofRequestJson.data(using: .utf8)!
                let decoder = JSONDecoder()
                let proofRequest = try! decoder.decode(ProofRequest.self, from: data)
                
                var retrievedCredentials = try await agent!.proofService.getRequestedCredentialsForProofRequest(proofRequest: proofRequest)
                
                retrievedCredentials.requestedAttributes.forEach { (key, value) in
                    var errorMsg = ""
                    let attrArray = retrievedCredentials.requestedAttributes[key]
                    if ((attrArray?.count ?? 0) == 0) {
                        errorMsg = "Não há nenhuma credencial do tipo '\(key)'."
                    }
                    var nonRevoked = attrArray?.filter { $0.revoked == false  }
                    if errorMsg.isEmpty && (nonRevoked?.isEmpty ?? true) {
                        errorMsg = "Não há nenhuma credencial não revogada do tipo '\(key)'."
                    }
                    
                    attributesList.append(["error": errorMsg,
                                           "name" : key,
                                           "availableCredentials": MapConverter.toRequestedAttributesList(requestedAttributes: nonRevoked!)]
                    )
                }
                
                retrievedCredentials.requestedPredicates.forEach { (key, value) in
                    var errorMsg = ""
                    let predicateArray = retrievedCredentials.requestedPredicates[key]
                    if ((predicateArray?.count ?? 0) == 0) {
                        errorMsg = "Não há nenhuma credencial relacionada a '\(key)'."
                    }
                    var nonRevoked = predicateArray?.filter { $0.revoked == false  }
                    if errorMsg.isEmpty && (nonRevoked?.isEmpty ?? true) {
                        errorMsg = "Não há nenhuma credencial não revogada relacionada a '\(key)'."
                    }
                    
                    predicatesList.append(["error": errorMsg,
                                           "name" : key,
                                           "availableCredentials": MapConverter.toRequestedPredicatesList(requestedPredicates: nonRevoked!)]
                    )
                    
                }
                
                var dict : [String : Any] = [:]
                dict["attributes"] = attributesList
                dict["predicates"] = predicatesList
                dict["proofRequest"] = proofRequestJson
                flutterResult(dict)
                
            }catch let error {
                sendError(error, flutterResult)
            }
        }
    }
    
    //MARK: getDidCommMessagesByRecord
    func getDidCommMessagesByRecord(associatedRecordId: String,flutterResult : @escaping FlutterResult) {
        Task {
            print("inicio")
            let items =  await agent!.didCommMessageRepository.findByQuery("{\"associatedRecordId\": \"\(associatedRecordId)\"}")
            print("inicio 2")
            
            var list : [[String : Any?]] = []
            for item in items  {
                if let rowDict = MapConverter.toMap(item) {
                    
                    list.append(rowDict)
                }
            }
            flutterResult(list)
        }
    }
    
    //MARK: getConnections
    func getConnectionHistory(connectionId: String,flutterResult : @escaping FlutterResult) {
        Task {
            do{
                var credentialsMap : [String: [String: Any?]] = [:]
                var proofsMap : [String: [String: Any?]] = [:]
                var basicMessagesList : Array<[String: Any?]> = []
                
                var credentials =  await agent!.credentialExchangeRepository.findByQuery("{\"connectionId\": \"\(connectionId)\"}")
                for record in credentials {
                    var map = MapConverter.toMap(record)
                    map?["recordType"] = "CredentialRecord"
                    if let _ = credentialsMap[record.id] {
                        if record.state != CredentialState.OfferSent {
                            continue
                        }
                    }
                    credentialsMap[record.id] = map
                }
                
                var proofs =  await agent!.proofRepository.findByQuery("{\"connectionId\": \"\(connectionId)\"}")
                
                for record in proofs {
                    var map = MapConverter.toMap(record)
                    map?["recordType"] = "ProofExchangeRecord"
                    if let _ = proofsMap[record.id] {
                        if record.state != ProofState.RequestSent {
                            continue
                        }
                    }
                    proofsMap[record.id] = map
                }
                
                var basicMessages =  try await agent!.basicMessageRepository.findByConnectionRecordId(connectionRecordId: connectionId)
                
                for record in basicMessages {
                    var map = MapConverter.toMap(record)
                    map?["recordType"] = "BasicMessage"
                    if map != nil {
                        basicMessagesList.append(map!)
                    }
                }
                
                var dict : [String : Any] = [:]
                dict["credentials"] = credentialsMap
                dict["proofs"] = proofsMap
                dict["basicMessages"] = toJson(basicMessagesList)
                flutterResult(dict)
                
            } catch {
                
            }
        }
    }
    
    func sendError(_ error: Error,_ flutterResult : @escaping FlutterResult) {
        flutterResult(FlutterError.init(code: "1", message: "error: \(error)", details: nil))
    }
    
    func sendError(_ error: String,_ flutterResult : @escaping FlutterResult) {
        flutterResult(FlutterError.init(code: "1", message: "error: \(error)", details: nil))
    }
    
    func getProofRequestJson(proofRecordId: String, recordMessageType: DidCommMessageRecord) async -> String? {
        do{
            
            if(recordMessageType.message.contains("/2,0'")) {
                let proofRequestMessageJson = try await agent!.didCommMessageRepository.getAgentMessage(
                    associatedRecordId: proofRecordId,
                    messageType: RequestPresentationMessageV2.type
                )
                
                let proofRequestMessage = MessageSerializer.decodeFromString(proofRequestMessageJson) as! RequestPresentationMessageV2
                return try proofRequestMessage.indyProofRequest()
                
            } else {
                let proofRequestMessageJson = try await agent!.didCommMessageRepository.getAgentMessage(
                    associatedRecordId: proofRecordId,
                    messageType: RequestPresentationMessage.type
                )
                
                var proofRequestMessage = MessageSerializer.decodeFromString(proofRequestMessageJson) as! RequestPresentationMessage
                return try proofRequestMessage.indyProofRequest()
            }
        }catch let e {
            return nil
        }
    }
    
    func toJson(_ json: Any) -> String{
        let jsonData = try! JSONSerialization.data(withJSONObject: json, options: [])
        return String(data: jsonData, encoding: .utf8)!
    }

    
}
