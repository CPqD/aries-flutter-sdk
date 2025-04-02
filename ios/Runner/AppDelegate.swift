import Flutter
import UIKit
import AriesFramework

@main
@objc class AppDelegate: FlutterAppDelegate {
    
    let channelName = "br.gov.serprocpqd/wallet"
    
    var mediatorUrl = "https://blockchain.cpqd.com.br/cpqdid/agent-mediator-endpoint-com?c_i=eyJAdHlwZSI6ICJkaWQ6c292OkJ6Q2JzTlloTXJqSGlxWkRUVUFTSGc7c3BlYy9jb25uZWN0aW9ucy8xLjAvaW52aXRhdGlvbiIsICJAaWQiOiAiMGEyYzc4MTYtMGYxZC00OTc3LTg5YzAtMGE0NmNhNTg4Nzk0IiwgInJlY2lwaWVudEtleXMiOiBbIjRFVFhHZGM3UjJzYVBzZktZR1g1dU15dDNFWU5aQVdyejJpN3VXbnN0eGJkIl0sICJsYWJlbCI6ICJNZWRpYWRvciBTT1UgaUQiLCAic2VydmljZUVuZHBvaW50IjogImh0dHBzOi8vYmxvY2tjaGFpbi5jcHFkLmNvbS5ici9jcHFkaWQvYWdlbnQtbWVkaWF0b3ItZW5kcG9pbnQtY29tIn0="
    
    var walletKey: String?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        let rootViewController : FlutterViewController = window?.rootViewController as! FlutterViewController
        
        channelWallet(controller: rootViewController as! FlutterBinaryMessenger)
        
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
   
}

extension AppDelegate : AgentDelegate{
    
    func onCredentialStateChanged(credentialRecord: CredentialExchangeRecord) {
        sendCredentialEventToFlutter(id: credentialRecord.id, state: credentialRecord.state.rawValue)
    }

    func onCredentialStateV2Changed(credentialRecord: CredentialExchangeRecord) {
        sendCredentialEventToFlutter(id: credentialRecord.id, state: credentialRecord.state.rawValue)
    }
    
    func onRevocationNotificationChanged(credentialExchangeRecord: CredentialExchangeRecord) {
        sendCredentialRevocationToFlutter(id: credentialExchangeRecord.id)
    }
    
    func onRevocationNotificationV2Changed(credentialExchangeRecord: CredentialExchangeRecord) {
        sendCredentialRevocationToFlutter(id: credentialExchangeRecord.id)
    }
    
    func onProofStateChanged(proofRecord: ProofExchangeRecord) {
        sendProofReceivedToFlutter(id: proofRecord.id, state: proofRecord.state.rawValue)
    }
    

    func onBasicMessageChanged(record: BasicMessageRecord) {
        sendBasicMessageToFlutter(record)
    }
    
    func onConnectionStateChanged(connectionRecord: ConnectionRecord) {
        
    }
    func onMediationStateChanged(mediationRecord: MediationRecord){
        
    }
    func onOutOfBandStateChanged(outOfBandRecord: OutOfBandRecord){
        
    }
    func onProblemReportReceived(message: BaseProblemReportMessage){
        
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
    
    func sendCredentialRevocationToFlutter(id: String) {
        let rootViewController : FlutterViewController = window?.rootViewController as! FlutterViewController
        let channel = FlutterMethodChannel(name: channelName, binaryMessenger: rootViewController  as! FlutterBinaryMessenger)
        let data = ["id": id,
        ]
        channel.invokeMethod("credentialRevocationReceived", arguments:data) { (result) in
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
    
    func sendBasicMessageToFlutter(_ message: BasicMessageRecord) {
        let rootViewController : FlutterViewController = window?.rootViewController as! FlutterViewController
        let channel = FlutterMethodChannel(name: channelName, binaryMessenger: rootViewController  as! FlutterBinaryMessenger)
        let data = MapConverter.toMap(message)
        channel.invokeMethod("basicMessageReceived", arguments:data) { (result) in
            if let resultString = result as? String {
                print(resultString)
            }
        }
    }
    
    
}
