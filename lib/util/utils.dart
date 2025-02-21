import 'package:flutter/services.dart';

final channelWallet = MethodChannel("br.gov.serprocpqd/wallet");
final methodOpenWallet = "openwallet";

Future<Map<String, dynamic>?> openWallet() async {
  try {
    final result = await channelWallet.invokeMethod(methodOpenWallet);
    return Map<String, dynamic>.from(result);
  } on PlatformException catch (e) {
    print("Failed to Invoke Open Wallet: '${e.message}'.");
    return null;
  }
}

Future<dynamic> recebeFromSwift(MethodCall call) async {
  switch (call.method) {
    case 'calldart':
      // Do something
      final Map arguments = call.arguments;
      print(arguments);
      return "$arguments";
    // break;
    default:
      throw PlatformException(
        code: 'Unimplemented',
        details: 'Method ${call.method} not implemented',
      );
  }
}

configureChannelSwift() {
  channelWallet.setMethodCallHandler(recebeFromSwift);
}
