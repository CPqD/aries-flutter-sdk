import Flutter
import UIKit
import AriesFramework

var agent: Agent!


let invitationUrl = "https://blockchain.cpqd.com.br/cpqdid/agent-mediator-endpoint-com?c_i=eyJAdHlwZSI6ICJkaWQ6c292OkJ6Q2JzTlloTXJqSGlxWkRUVUFTSGc7c3BlYy9jb25uZWN0aW9ucy8xLjAvaW52aXRhdGlvbiIsICJAaWQiOiAiMGEyYzc4MTYtMGYxZC00OTc3LTg5YzAtMGE0NmNhNTg4Nzk0IiwgInJlY2lwaWVudEtleXMiOiBbIjRFVFhHZGM3UjJzYVBzZktZR1g1dU15dDNFWU5aQVdyejJpN3VXbnN0eGJkIl0sICJsYWJlbCI6ICJNZWRpYWRvciBTT1UgaUQiLCAic2VydmljZUVuZHBvaW50IjogImh0dHBzOi8vYmxvY2tjaGFpbi5jcHFkLmNvbS5ici9jcHFkaWQvYWdlbnQtbWVkaWF0b3ItZW5kcG9pbnQtY29tIn0="
//        let invitationUrl = "https://public.mediator.indiciotech.io?c_i=eyJAdHlwZSI6ICJkaWQ6c292OkJ6Q2JzTlloTXJqSGlxWkRUVUFTSGc7c3BlYy9jb25uZWN0aW9ucy8xLjAvaW52aXRhdGlvbiIsICJAaWQiOiAiMDVlYzM5NDItYTEyOS00YWE3LWEzZDQtYTJmNDgwYzNjZThhIiwgInNlcnZpY2VFbmRwb2ludCI6ICJodHRwczovL3B1YmxpYy5tZWRpYXRvci5pbmRpY2lvdGVjaC5pbyIsICJyZWNpcGllbnRLZXlzIjogWyJDc2dIQVpxSktuWlRmc3h0MmRIR3JjN3U2M3ljeFlEZ25RdEZMeFhpeDIzYiJdLCAibGFiZWwiOiAiSW5kaWNpbyBQdWJsaWMgTWVkaWF0b3IifQ=="

@main
@objc class AppDelegate: FlutterAppDelegate {
    
    let channelName = "br.gov.serprocpqd/wallet"
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        let rootViewController : FlutterViewController = window?.rootViewController as! FlutterViewController
        
        channelWallet(controller: rootViewController as! FlutterBinaryMessenger)
        
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    
    func channelWallet(controller : FlutterBinaryMessenger) {
        let channel = FlutterMethodChannel(name: channelName,
                                           binaryMessenger: controller)
        channel.setMethodCallHandler({
            [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            
            switch (call.method) {
            case "openwallet":
                self!.openWallet(flutterResult: result)
            case "getCredentials":
                self!.getCredentials(flutterResult: result)
            case "getConnections":
                self!.getConnections(flutterResult: result)
            case "receiveInvitation":
                self!.receiveInvitation(url: (call.arguments as! [String])[0], flutterResult: result)
            case "shutdown":
                self!.shutdown(flutterResult: result)
            case "acceptCredentialOffer":
                self!.acceptCredentialOffer(credentialRecordId: (call.arguments as! [String])[0], flutterResult: result)
            case "declineCredentialOffer":
                self!.declineCredentialOffer(credentialRecordId: (call.arguments as! [String])[0],flutterResult: result)
            case "acceptProofOffer":
                self!.acceptProofOffer(proofRecordId: (call.arguments as! [String])[0], flutterResult: result)
            case "declineProofOffer":
                self!.declineProofOffer(proofRecordId: (call.arguments as! [String])[0], flutterResult: result)
            case "removeCredential":
                self!.removeCredential(credentialRecordId: (call.arguments as! [String])[0],flutterResult: result)
            case "removeConnections":
                self!.removeConnections(connectionId: (call.arguments as! [String])[0],flutterResult: result)
            default:
                var dict : [String : Any] = [:]
                dict["error"] = ""
                dict["result"] = false
                result(dict)
            }
        })
    }
    
    func openWallet(flutterResult : @escaping FlutterResult)  {
        let userDefaults = UserDefaults.standard
        var key = userDefaults.value(forKey:"walletKey") as? String
        if (key == nil) {
            do {
                key = try Agent.generateWalletKey()
                userDefaults.set(key, forKey: "walletKey")
            } catch {
                if let err = error as NSError? {
                    print("Cannot generate key: \(err.userInfo["message"] ?? "Unknown error")")
                    flutterResult(FlutterError.init(code: "ERROR", message: "error:  \(err.userInfo["message"])", details: nil))
                    return
                }
            }
        }
        let genesisPath = Bundle(for: AppDelegate.self).path(forResource: "bcovrin-genesis", ofType: "txn")
        let config = AgentConfig(walletKey: key!,
                                 genesisPath: genesisPath!,
                                 mediatorConnectionsInvite: invitationUrl,
                                 mediatorPickupStrategy: .Implicit,
                                 label: "SampleApp",
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
                
                flutterResult(FlutterError.init(code: "ERROR", message: "error: \(error)", details: nil))
                
            }
            
            
            
        }
    }
    
    func receiveInvitation(url: String, flutterResult : @escaping FlutterResult) {
        Task {
            do {
                let (_, connection) = try await agent!.oob.receiveInvitationFromUrl(url)
                var dict : [String : Any] = [:]
                dict["error"] = ""
                dict["result"] = true
                flutterResult(dict)
            }  catch let error{
                flutterResult(FlutterError.init(code: "ERROR", message: "error: \(error)", details: nil))
            }
        }
    }
    func shutdown(flutterResult : @escaping FlutterResult) {
        Task {
            do {
                try await agent!.shutdown()
                var dict : [String : Any] = [:]
                dict["error"] = ""
                dict["result"] = true
                flutterResult(dict)
            } catch let error{
                flutterResult(FlutterError.init(code: "ERROR", message: "error: \(error)", details: nil))
            }
        }
    }
    
    func getCredentials(flutterResult : @escaping FlutterResult) {
        Task {
            let credentials =  await agent!.credentialRepository?.getAll()
            var listCredentials : [[String : Any]] = []
            for credential in credentials ?? [] {
                var rowDict : [String : Any] = [:]
                rowDict["id"] = credential.id
                rowDict["revocationId"] = credential.credentialRevocationId
                rowDict["linkSecretId"] = credential.linkSecretId
                rowDict["credentiald"] = credential.credential
                rowDict["schemaId"] = credential.schemaId
                rowDict["schemaName"] = credential.schemaName
                rowDict["schemaVersion"] = credential.schemaVersion
                rowDict["schemaIssuerId"] = credential.schemaIssuerId
                rowDict["issuerId"] = credential.issuerId
                rowDict["definitionId"] = credential.credentialDefinitionId
                rowDict["revocationRegistryId"] = credential.revocationRegistryId
                listCredentials.append(rowDict)
            }
            flutterResult(listCredentials)
        }
    }
    
    func getConnections(flutterResult : @escaping FlutterResult) {
        Task {
            print("inicio")
            let connections =  await agent!.connectionRepository?.getAll()
            print("inicio 2")
            var listCredentials : [[String : Any]] = []
            for connection in connections ?? [] {
                var rowDict : [String : Any] = [:]
                rowDict["id"] = connection.id
                rowDict["state"] = connection.state.rawValue
                rowDict["role"] = connection.role
                rowDict["did"] = connection.did
                rowDict["didDoc"] = connection.didDoc
                rowDict["verkey"] = connection.verkey
                rowDict["theirDidDoc"] = connection.theirDidDoc
                rowDict["theirDid"] = connection.theirDid
                rowDict["theirLabel"] = connection.theirLabel
                rowDict["invitation"] = connection.invitation
                rowDict["alias"] = connection.alias
                rowDict["autoAcceptConnection"] = connection.autoAcceptConnection
                rowDict["imageUrl"] = connection.imageUrl
                rowDict["multiUseInvitation"] = connection.multiUseInvitation
                rowDict["outOfBandInvitation"] = connection.outOfBandInvitation
                rowDict["threadId"] = connection.threadId
                rowDict["mediatorId"] = connection.mediatorId
                rowDict["errorMessage"] = connection.errorMessage
                
                listCredentials.append(rowDict)
            }
            flutterResult(listCredentials)
        }
    }
    
    func acceptCredentialOffer (credentialRecordId : String?, flutterResult : @escaping FlutterResult) {
        guard let credentialId = credentialRecordId else {
            flutterResult(FlutterError.init(code: "BAD_PARAMETER", message: "credentialRecordId is null", details: nil))
            return
        }
        Task{
            let offerOption = AcceptOfferOptions(credentialRecordId: credentialId, autoAcceptCredential: .always)
            do {
                _ = try await agent!.credentials.acceptOffer(options: offerOption)
                var dict : [String : Any] = [:]
                dict["error"] = ""
                dict["result"] = true
                flutterResult(dict)
            } catch let error {
                flutterResult(FlutterError.init(code: "BAD_CREDENTIAL_ID", message: "error: \(error)", details: nil))
            }
        }
    }
    
    func declineCredentialOffer (credentialRecordId : String?, flutterResult : @escaping FlutterResult) {
        guard let credentialId = credentialRecordId else {
            flutterResult(FlutterError.init(code: "BAD_PARAMETER", message: "credentialRecordId is null", details: nil))
            return
        }
        Task{
            do {
                _ = try await agent!.credentials.declineOffer(credentialRecordId: credentialId)
                var dict : [String : Any] = [:]
                dict["error"] = ""
                dict["result"] = true
                flutterResult(dict)
            } catch let error {
                flutterResult(FlutterError.init(code: "BAD_CREDENTIAL_ID", message: "error: \(error)", details: nil))
            }
        }
    }
    
    func acceptProofOffer (proofRecordId : String?, flutterResult : @escaping FlutterResult) {
        guard let proofId = proofRecordId else {
            flutterResult(FlutterError.init(code: "BAD_PARAMETER", message: "proofRecordId is null", details: nil))
            return
        }
        Task{
            do {
                let retrievedCredentials = try await agent!.proofs.getRequestedCredentialsForProofRequest(proofRecordId: proofId)
                
                let requestedCredentials = try await agent!.proofService.autoSelectCredentialsForProofRequest(retrievedCredentials: retrievedCredentials)
                _ = try await agent!.proofs.acceptRequest(proofRecordId: proofId, requestedCredentials:  requestedCredentials)
                var dict : [String : Any] = [:]
                dict["error"] = ""
                dict["result"] = true
                flutterResult(dict)
            } catch let error {
                flutterResult(FlutterError.init(code: "BAD_PROOF_ID", message: "error: \(error)", details: nil))
            }
        }
    }
    
    func declineProofOffer (proofRecordId : String?, flutterResult : @escaping FlutterResult) {
        guard let proofId = proofRecordId else {
            flutterResult(FlutterError.init(code: "BAD_PARAMETER", message: "proofRecordId is null", details: nil))
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
                flutterResult(FlutterError.init(code: "BAD_PROOF_ID", message: "error: \(error)", details: nil))
            }
        }
    }
    
    func removeCredential (credentialRecordId : String?, flutterResult : @escaping FlutterResult) {
        guard let credentialId = credentialRecordId else {
            flutterResult(FlutterError.init(code: "BAD_PARAMETER", message: "credentialRecordId is null", details: nil))
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
                flutterResult(FlutterError.init(code: "BAD_CREDENTIAL_ID", message: "error: \(error)", details: nil))
            }
        }
    }
    
    func removeConnections(connectionId: String?, flutterResult : @escaping FlutterResult) {
        guard let connId = connectionId else {
            flutterResult(FlutterError.init(code: "BAD_PARAMETER", message: "connectionId is null", details: nil))
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
                flutterResult(FlutterError.init(code: "BAD_CONNECTION_ID", message: "error: \(error)", details: nil))
            }
        }
    }

    
}

extension AppDelegate : AgentDelegate{
    func onCredentialStateChanged(credentialRecord: CredentialExchangeRecord) {
        
        sendCredentialEventToFlutter(id: credentialRecord.id, state: credentialRecord.state.rawValue)
    }
    func onConnectionStateChanged(connectionRecord: ConnectionRecord) {
        
    }
    func onMediationStateChanged(mediationRecord: MediationRecord){
        
    }
    func onOutOfBandStateChanged(outOfBandRecord: OutOfBandRecord){
        
    }
    func onProblemReportReceived(message: BaseProblemReportMessage){
        
    }

    func onProofStateChanged(proofRecord: ProofExchangeRecord) {
        sendProofReceivedToFlutter(id: proofRecord.id, state: proofRecord.state.rawValue)
    }
    
    //MARK: chamar flutter
    func sendCredentialEventToFlutter(id: String, state: String) {
        let rootViewController : FlutterViewController = window?.rootViewController as! FlutterViewController
        let channel = FlutterMethodChannel(name: channelName, binaryMessenger: rootViewController  as! FlutterBinaryMessenger)
        let data = ["id": id,
                    "state" : state
        ]
        channel.invokeMethod("credentialReceived", arguments:data) { (result) in
            if let resultString = result as? String {
                print(resultString)
            }
        }
    }
    
    func sendProofReceivedToFlutter(id: String, state: String) {
        let rootViewController : FlutterViewController = window?.rootViewController as! FlutterViewController
        let channel = FlutterMethodChannel(name: channelName, binaryMessenger: rootViewController  as! FlutterBinaryMessenger)
        let data = ["id": id,
                    "state" : state
        ]
        channel.invokeMethod("proofReceived", arguments:data) { (result) in
            if let resultString = result as? String {
                print(resultString)
            }
        }
    }
    
    
}



