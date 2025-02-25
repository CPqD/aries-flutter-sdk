import 'package:flutter/services.dart';

final channelWallet = MethodChannel("br.gov.serprocpqd/wallet");

enum AriesMethod {
  init('init'),
  openWallet('openwallet');

  final String value;

  const AriesMethod(this.value);
}

Future<Map<String, dynamic>?> init() => _invokeMethod(AriesMethod.init);

Future<Map<String, dynamic>?> openWallet() => _invokeMethod(AriesMethod.openWallet);

Future<Map<String, dynamic>?> _invokeMethod(AriesMethod method) async {
  print("\ninvoke ${method.value}");

  try {
    return Map<String, dynamic>.from(await channelWallet.invokeMethod(method.value));
  } on PlatformException catch (e) {
    print("Failed to Invoke ${method.value}: '${e.message}'.");
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
