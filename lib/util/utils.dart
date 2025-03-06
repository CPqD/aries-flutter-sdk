import 'dart:convert';

import 'package:did_agent/agent/aries_method.dart';
import 'package:did_agent/agent/aries_result.dart';
import 'package:did_agent/agent/credential_record.dart';
import 'package:did_agent/home.dart';
import 'package:flutter/services.dart';

Future<AriesResult> init() => AriesResult.invoke(AriesMethod.init);

Future<AriesResult> openWallet() => AriesResult.invoke(AriesMethod.openWallet);

Future<AriesResult<List<CredentialRecord>>> getCredentials() async {
  final result = await AriesResult.invoke(AriesMethod.getCredentials);

  if (!result.success || result.value == null) {
    return AriesResult(success: false, error: result.error, value: []);
  }

  try {
    final List<dynamic> jsonList = jsonDecode(result.value);

    final originalList = List<Map<String, dynamic>>.from(jsonList);

    return AriesResult(
      success: true,
      error: result.error,
      value: originalList.map((map) => CredentialRecord.fromMap(map)).toList(),
    );
  } catch (e) {
    print('failed to decode = ${e.toString()}\n\n');

    return AriesResult(success: false, error: e.toString(), value: []);
  }
}

Future<AriesResult> receiveInvitation(String url) => AriesResult.invoke(
      AriesMethod.invitation,
      {'invitationUrl': url},
    );

Future<AriesResult> subscribe() => AriesResult.invoke(AriesMethod.subscribe);

Future<AriesResult> shutdown() => AriesResult.invoke(AriesMethod.shutdown);

Future<AriesResult> acceptOffer(String credentialRecordId) => AriesResult.invoke(
    AriesMethod.acceptOffer, {'credentialRecordId': credentialRecordId});

Future<AriesResult> declineOffer(String credentialRecordId) => AriesResult.invoke(
    AriesMethod.declineOffer, {'credentialRecordId': credentialRecordId});

Future<dynamic> recebeFromNative(MethodCall call) async {
  switch (call.method) {
    case 'calldart':
      final Map arguments = call.arguments;
      print(arguments);
      return "$arguments";
    case 'credentialReceived':
      print('credentialReceived on FLUTTER: ${call.arguments}');

      final Map<String, String> arguments = Map<String, String>.from(call.arguments);

      homePageKey.currentState
          ?.receivedCredential(arguments["id"] ?? '', arguments["state"] ?? '');

      return "$arguments";
    case 'proofReceived':
      print('proofReceived on FLUTTER: ${call.arguments}');

      final Map<String, String> arguments = Map<String, String>.from(call.arguments);
      homePageKey.currentState
          ?.receivedProof(arguments["id"] ?? '', arguments["state"] ?? '');

      return "$arguments";
    default:
      throw PlatformException(
        code: 'Unimplemented',
        details: 'Method ${call.method} not implemented',
      );
  }
}

configureChannelNative() {
  channelWallet.setMethodCallHandler(recebeFromNative);
}
