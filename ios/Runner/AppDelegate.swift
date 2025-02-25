import Flutter
import UIKit
import AriesFramework

var agent: Agent!


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
                    return
                }
            }
        }
        let invitationUrl = "https://blockchain.cpqd.com.br/cpqdid/agent-mediator-endpoint-com?c_i=eyJAdHlwZSI6ICJkaWQ6c292OkJ6Q2JzTlloTXJqSGlxWkRUVUFTSGc7c3BlYy9jb25uZWN0aW9ucy8xLjAvaW52aXRhdGlvbiIsICJAaWQiOiAiMGEyYzc4MTYtMGYxZC00OTc3LTg5YzAtMGE0NmNhNTg4Nzk0IiwgInJlY2lwaWVudEtleXMiOiBbIjRFVFhHZGM3UjJzYVBzZktZR1g1dU15dDNFWU5aQVdyejJpN3VXbnN0eGJkIl0sICJsYWJlbCI6ICJNZWRpYWRvciBTT1UgaUQiLCAic2VydmljZUVuZHBvaW50IjogImh0dHBzOi8vYmxvY2tjaGFpbi5jcHFkLmNvbS5ici9jcHFkaWQvYWdlbnQtbWVkaWF0b3ItZW5kcG9pbnQtY29tIn0="
        //        let invitationUrl = "https://public.mediator.indiciotech.io?c_i=eyJAdHlwZSI6ICJkaWQ6c292OkJ6Q2JzTlloTXJqSGlxWkRUVUFTSGc7c3BlYy9jb25uZWN0aW9ucy8xLjAvaW52aXRhdGlvbiIsICJAaWQiOiAiMDVlYzM5NDItYTEyOS00YWE3LWEzZDQtYTJmNDgwYzNjZThhIiwgInNlcnZpY2VFbmRwb2ludCI6ICJodHRwczovL3B1YmxpYy5tZWRpYXRvci5pbmRpY2lvdGVjaC5pbyIsICJyZWNpcGllbnRLZXlzIjogWyJDc2dIQVpxSktuWlRmc3h0MmRIR3JjN3U2M3ljeFlEZ25RdEZMeFhpeDIzYiJdLCAibGFiZWwiOiAiSW5kaWNpbyBQdWJsaWMgTWVkaWF0b3IifQ=="
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
                agent = Agent(agentConfig: config, agentDelegate: await CredentialHandler.shared)
                try await agent!.initialize()
            } catch {
                print("Cannot initialize agent: \(error)")
                
                var dict : [String : Any] = [:]
                dict["error"] = "\(error)"
                dict["result"] = false
                
                flutterResult(dict)
                return
            }
            
            var dict : [String : Any] = [:]
            dict["error"] = ""
            dict["result"] = true
            
            flutterResult(dict)
            callDartTest()
            
        }
    }
    
    func channelWallet(controller : FlutterBinaryMessenger) {
            let channel = FlutterMethodChannel(name: channelName,
                                               binaryMessenger: controller)
            channel.setMethodCallHandler({
                [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
                
                switch (call.method) {
                case "openwallet":
                    self!.openWallet(flutterResult: result)
                case "receiveInvitation":
                    self!.receiveInvitation(url: (call.arguments as! [String])[0], flutterResult: result)
                default:
                    var dict : [String : Any] = [:]
                    dict["error"] = ""
                    dict["result"] = false
                    result(dict)
                }
            })
        }
    
    func callDartTest() {
        let rootViewController : FlutterViewController = window?.rootViewController as! FlutterViewController
        let channel = FlutterMethodChannel(name: channelName, binaryMessenger: rootViewController  as! FlutterBinaryMessenger)
        let data = ["Erique": "Teste"]
        channel.invokeMethod("calldart", arguments:data) { (result) in
            if let resultString = result as? String {
                print(resultString)
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
            } catch {
                print(error)
                var dict : [String : Any] = [:]
                dict["error"] = "\(error)"
                dict["result"] = false
                flutterResult(dict)
            }
        }
    }
    
}



