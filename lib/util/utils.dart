import 'package:did_agent/agent/aries_method.dart';
import 'package:did_agent/agent/aries_result.dart';
import 'package:flutter/services.dart';

Future<AriesResult> init() => AriesResult.invoke(AriesMethod.init);

Future<AriesResult> openWallet() => AriesResult.invoke(AriesMethod.openWallet);

Future<AriesResult> receiveInvitation(String url) =>
    AriesResult.invoke(AriesMethod.invitation, {'invitationUrl': url});

Future<AriesResult> shutdown() => AriesResult.invoke(AriesMethod.shutdown);

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
