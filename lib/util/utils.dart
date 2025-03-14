import 'dart:convert';

import 'package:did_agent/agent/aries_result.dart';
import 'package:did_agent/agent/enums/aries_method.dart';
import 'package:did_agent/agent/models/connection_record.dart';
import 'package:did_agent/agent/models/credential_exchange_record.dart';
import 'package:did_agent/agent/models/credential_record.dart';
import 'package:did_agent/agent/models/did_comm_message_record.dart';
import 'package:did_agent/agent/models/proof_exchange_record.dart';
import 'package:did_agent/page/home.dart';
import 'package:flutter/services.dart';

Future<AriesResult> init() => AriesResult.invoke(AriesMethod.init);

Future<AriesResult> openWallet() => AriesResult.invoke(AriesMethod.openWallet);

Future<AriesResult<List<ConnectionRecord>>> getConnections() async {
  final result = await AriesResult.invoke(AriesMethod.getConnections);

  if (!result.success || result.value == null) {
    return AriesResult(success: false, error: result.error, value: []);
  }

  try {
    final List<dynamic> jsonList = jsonDecode(result.value);

    final originalList = List<Map<String, dynamic>>.from(jsonList);

    return AriesResult(
      success: true,
      error: result.error,
      value: originalList.map((map) => ConnectionRecord.fromMap(map)).toList(),
    );
  } catch (e) {
    print('failed to decode = ${e.toString()}\n\n');

    return AriesResult(success: false, error: e.toString(), value: []);
  }
}

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

Future<AriesResult<List<CredentialExchangeRecord>>> getCredentialsOffers() async {
  final result = await AriesResult.invoke(AriesMethod.getCredentialsOffers);

  if (!result.success || result.value == null) {
    return AriesResult(success: false, error: result.error, value: []);
  }

  try {
    final List<dynamic> jsonList = jsonDecode(result.value);

    final originalList = List<Map<String, dynamic>>.from(jsonList);

    return AriesResult(
      success: true,
      error: result.error,
      value: originalList.map((map) => CredentialExchangeRecord.fromMap(map)).toList(),
    );
  } catch (e) {
    print('failed to decode = ${e.toString()}\n\n');

    return AriesResult(success: false, error: e.toString(), value: []);
  }
}

Future<AriesResult<List<ProofExchangeRecord>>> getProofOffers() async {
  final result = await AriesResult.invoke(AriesMethod.getProofOffers);

  if (!result.success || result.value == null) {
    return AriesResult(success: false, error: result.error, value: []);
  }

  try {
    final List<dynamic> jsonList = jsonDecode(result.value);

    final originalList = List<Map<String, dynamic>>.from(jsonList);

    return AriesResult(
      success: true,
      error: result.error,
      value: originalList.map((map) => ProofExchangeRecord.fromMap(map)).toList(),
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

Future<AriesResult> acceptCredentialOffer(String credentialId) => AriesResult.invoke(
    AriesMethod.acceptCredentialOffer, {'credentialRecordId': credentialId});

Future<AriesResult> acceptProofOffer(String proofId) =>
    AriesResult.invoke(AriesMethod.acceptProofOffer, {'proofRecordId': proofId});

Future<AriesResult<DidCommMessageRecord?>> getDidCommMessage(
    String associatedRecordId) async {
  final result = await AriesResult.invoke(
      AriesMethod.getDidCommMessage, {'associatedRecordId': associatedRecordId});

  if (!result.success || result.value == null) {
    return AriesResult(success: false, error: result.error);
  }

  try {
    final resultMap = Map<String, dynamic>.from(jsonDecode(result.value));

    return AriesResult(
      success: true,
      error: result.error,
      value: DidCommMessageRecord.fromMap(resultMap),
    );
  } catch (e) {
    print('failed to decode = ${e.toString()}\n\n');

    return AriesResult(success: false, error: e.toString());
  }
}

Future<AriesResult> declineCredentialOffer(String credentialId) => AriesResult.invoke(
    AriesMethod.declineCredentialOffer, {'credentialRecordId': credentialId});

Future<AriesResult> declineProofOffer(String proofId) =>
    AriesResult.invoke(AriesMethod.declineProofOffer, {'proofRecordId': proofId});

Future<AriesResult> removeConnection(String connectionId) => AriesResult.invoke(
    AriesMethod.removeConnection, {'connectionRecordId': connectionId});

Future<AriesResult> removeCredential(String credentialId) => AriesResult.invoke(
    AriesMethod.removeCredential, {'credentialRecordId': credentialId});

Future<AriesResult> subscribe() => AriesResult.invoke(AriesMethod.subscribe);

Future<AriesResult> shutdown() => AriesResult.invoke(AriesMethod.shutdown);

Future<dynamic> receiveFromNative(MethodCall call) async {
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
  channelWallet.setMethodCallHandler(receiveFromNative);
}

void logPrint(Object object) async {
  int defaultPrintLength = 1020;
  if (object.toString().length <= defaultPrintLength) {
    print(object);
  } else {
    String log = object.toString();
    int start = 0;
    int endIndex = defaultPrintLength;
    int logLength = log.length;
    int tmpLogLength = log.length;
    while (endIndex < logLength) {
      print(log.substring(start, endIndex));
      endIndex += defaultPrintLength;
      start += defaultPrintLength;
      tmpLogLength -= defaultPrintLength;
    }
    if (tmpLogLength > 0) {
      print(log.substring(start, logLength));
    }
  }
}
