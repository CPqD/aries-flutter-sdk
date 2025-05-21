import 'dart:convert';

import 'package:did_agent/agent/aries_result.dart';
import 'package:did_agent/agent/enums/aries_method.dart';
import 'package:did_agent/agent/enums/history_type.dart';
import 'package:did_agent/agent/models/connection/connection_record.dart';
import 'package:did_agent/agent/models/credential/credential_exchange_record.dart';
import 'package:did_agent/agent/models/credential/credential_record.dart';
import 'package:did_agent/agent/models/did_comm_message_record.dart';
import 'package:did_agent/agent/models/history/history_record.dart';
import 'package:did_agent/agent/models/proof/basic_message_record.dart';
import 'package:did_agent/agent/models/proof/details/proof_details.dart';
import 'package:did_agent/agent/models/proof/details/requested_attribute.dart';
import 'package:did_agent/agent/models/proof/details/requested_predicate.dart';
import 'package:did_agent/agent/models/proof/proof_exchange_record.dart';
import 'package:did_agent/agent/models/proof/proof_request.dart';
import 'package:did_agent/page/connection_history_page.dart';
import 'package:did_agent/page/home_page.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<AriesResult> init() async {
  var mediatorUrl = String.fromEnvironment('MEDIATOR_URL');

  if (mediatorUrl.isEmpty) {
    mediatorUrl = dotenv.env['MEDIATOR_URL'] ?? '';
  }

  return await AriesResult.invoke(AriesMethod.init, {'mediatorUrl': mediatorUrl});
}

Future<AriesResult> openWallet() => AriesResult.invoke(AriesMethod.openWallet);

Future<AriesResult<List<ConnectionRecord>>> getConnections(
    {bool hideMediator = false}) async {
  final result = await AriesResult.invoke(AriesMethod.getConnections, {
    'hideMediator': hideMediator,
  });

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
    print('getConnections - failed to decode = ${e.toString()}\n\n');

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
    print('getCredentials - failed to decode = ${e.toString()}\n\n');

    return AriesResult(success: false, error: e.toString(), value: []);
  }
}

Future<AriesResult<CredentialRecord>> getCredential(String credentialId) async {
  final result =
      await AriesResult.invoke(AriesMethod.getCredential, {'credentialId': credentialId});

  if (!result.success || result.value == null) {
    return AriesResult(success: false, error: result.error);
  }

  try {
    final credentialMap = Map<String, dynamic>.from(jsonDecode(result.value));

    return AriesResult(
      success: true,
      error: result.error,
      value: CredentialRecord.fromMap(credentialMap),
    );
  } catch (e) {
    print('getCredential - failed to decode = ${e.toString()}\n\n');

    return AriesResult(success: false, error: e.toString());
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
    print('getCredentialsOffers - failed to decode = ${e.toString()}\n\n');

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
    print('getProofOffers - failed to decode = ${e.toString()}\n\n');

    return AriesResult(success: false, error: e.toString(), value: []);
  }
}

Future<AriesResult> receiveInvitation(String url) => AriesResult.invoke(
      AriesMethod.invitation,
      {'invitationUrl': url},
    );

Future<AriesResult> acceptCredentialOffer(String credentialId, String protocolVersion) {
  final result = AriesResult.invoke(AriesMethod.acceptCredentialOffer, {
    'credentialRecordId': credentialId,
    'protocolVersion': protocolVersion,
  });

  connectionHistoryKey.currentState?.refreshHistory();

  return result;
}

Future<AriesResult> acceptProofOffer(
  String proofId,
  Map<String, RequestedAttribute> selectedAttributes,
  Map<String, RequestedPredicate> selectedPredicates,
) {
  final Map<String, String> selectedCredentialsAttributes = {};

  selectedAttributes.forEach((key, value) {
    selectedCredentialsAttributes[key] = value.credentialId;
  });

  final Map<String, String> selectedCredentialsPredicates = {};

  selectedPredicates.forEach((key, value) {
    selectedCredentialsPredicates[key] = value.credentialId;
  });

  final result = AriesResult.invoke(AriesMethod.acceptProofOffer, {
    'proofRecordId': proofId,
    'selectedCredentialsAttributes': selectedCredentialsAttributes,
    'selectedCredentialsPredicates': selectedCredentialsPredicates
  });

  connectionHistoryKey.currentState?.refreshHistory();

  return result;
}

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
    print('getDidCommMessage - failed to decode = ${e.toString()}\n\n');

    return AriesResult(success: false, error: e.toString());
  }
}

Future<AriesResult<List<DidCommMessageRecord>>> getDidCommMessagesByRecord(
    String associatedRecordId) async {
  final result = await AriesResult.invoke(
      AriesMethod.getDidCommMessagesByRecord, {'associatedRecordId': associatedRecordId});

  if (!result.success || result.value == null) {
    return AriesResult(success: false, error: result.error, value: []);
  }

  try {
    final List<dynamic> jsonList = jsonDecode(result.value);

    final originalList = List<Map<String, dynamic>>.from(jsonList);

    return AriesResult(
      success: true,
      error: result.error,
      value: originalList.map((map) => DidCommMessageRecord.fromMap(map)).toList(),
    );
  } catch (e) {
    print('getDidCommMessagesByRecord - failed to decode = ${e.toString()}\n\n');

    return AriesResult(success: false, error: e.toString(), value: []);
  }
}

Future<AriesResult<ProofOfferDetails?>> getProofOfferDetails(String proofId) async {
  print('getProofOfferDetails!!\n\n');

  final proofOfferDetails = await AriesResult.invoke(
    AriesMethod.getProofOfferDetails,
    {'proofRecordId': proofId},
  );

  if (!proofOfferDetails.success) {
    return AriesResult(success: false, error: proofOfferDetails.error);
  }

  try {
    final resultMap = Map<String, dynamic>.from(proofOfferDetails.value);

    print('getProofOfferDetails: $resultMap\n\n');

    final ariesResult = AriesResult(
      success: true,
      error: proofOfferDetails.error,
      value: ProofOfferDetails.fromMap(resultMap),
    );

    print('getProofOfferDetails ariesResult: $ariesResult\n\n');

    return ariesResult;
  } catch (e) {
    print('getProofOfferDetails - failed to decode = ${e.toString()}\n\n');

    return AriesResult(success: false, error: e.toString());
  }
}

Future<AriesResult<List<HistoryRecord>?>> getConnectionHistory(String connectionId,
    {List<HistoryType> historyTypes = const []}) async {
  print('getConnectionHistory!!\n\n');

  final historyTypesStr = historyTypes.map((historyType) => historyType.value).toList();

  final result = await AriesResult.invoke(
    AriesMethod.getConnectionHistory,
    {'connectionId': connectionId, 'historyTypes': historyTypesStr},
  );

  if (!result.success || result.value == null) {
    return AriesResult(success: false, error: result.error);
  }

  try {
    final List<dynamic> jsonList = jsonDecode(result.value);

    print('jsonList: $jsonList');

    final mapList = List<Map<String, dynamic>>.from(jsonList);

    print('mapList: $jsonList');

    final ariesResult = AriesResult(
      success: true,
      error: result.error,
      value: HistoryRecord.fromList(mapList),
    );

    print('getConnectionHistory ariesResult: $ariesResult\n\n');

    return ariesResult;
  } catch (e) {
    print('getConnectionHistory - failed to decode = ${e.toString()}\n\n');

    return AriesResult(success: false, error: e.toString());
  }
}

Future<AriesResult<List<HistoryRecord>?>> getCredentialHistory(String credentialId,
    {List<HistoryType> historyTypes = const []}) async {
  print('getCredentialHistory!!\n\n');

  final historyTypesStr = historyTypes.map((historyType) => historyType.value).toList();

  final result = await AriesResult.invoke(
    AriesMethod.getCredentialHistory,
    {'credentialId': credentialId, 'historyTypes': historyTypesStr},
  );

  if (!result.success || result.value == null) {
    return AriesResult(success: false, error: result.error);
  }

  try {
    final List<dynamic> jsonList = jsonDecode(result.value);

    print('jsonList: $jsonList');

    final mapList = List<Map<String, dynamic>>.from(jsonList);

    print('mapList: $jsonList');

    final ariesResult = AriesResult(
      success: true,
      error: result.error,
      value: HistoryRecord.fromList(mapList),
    );

    print('getConnectionHistory ariesResult: $ariesResult\n\n');

    return ariesResult;
  } catch (e) {
    print('getConnectionHistory - failed to decode = ${e.toString()}\n\n');

    return AriesResult(success: false, error: e.toString());
  }
}

Future<AriesResult> declineCredentialOffer(String credentialId, String protocolVersion) {
  final result = AriesResult.invoke(AriesMethod.declineCredentialOffer, {
    'credentialRecordId': credentialId,
    'protocolVersion': protocolVersion,
  });

  connectionHistoryKey.currentState?.refreshHistory();

  return result;
}

Future<AriesResult> declineProofOffer(String proofId) {
  final result = AriesResult.invoke(
    AriesMethod.declineProofOffer,
    {'proofRecordId': proofId},
  );

  connectionHistoryKey.currentState?.refreshHistory();

  return result;
}

Future<AriesResult<String>> generateInvitation({String? deviceLabel}) async {
  deviceLabel ??= "App Agent";

  final result = await AriesResult.invoke(
      AriesMethod.generateInvitation, {'deviceLabel': deviceLabel});

  if (!result.success || result.value == null) {
    return AriesResult(success: false, error: result.error);
  }

  try {
    return AriesResult<String>(
      success: result.success,
      error: result.error,
      value: result.value as String,
    );
  } catch (e) {
    print('generateInvitation - failed to decode = ${e.toString()}\n\n');

    return AriesResult(success: false, error: e.toString());
  }
}

Future<AriesResult<bool>> sendMessage({
  required String connectionId,
  required String message,
}) async {
  final result = await AriesResult.invoke(
    AriesMethod.sendMessage,
    {'connectionId': connectionId, 'message': message},
  );

  if (!result.success || result.value == null) {
    return AriesResult(success: false, error: result.error);
  }

  try {
    return AriesResult<bool>(
      success: result.success,
      error: result.error,
      value: result.value == true,
    );
  } catch (e) {
    print('sendMessage - failed to decode = ${e.toString()}\n\n');

    return AriesResult(success: false, error: e.toString());
  }
}

Future<AriesResult<ProofExchangeRecord>> requestProof({
  required String connectionId,
  required ProofRequest proofRequest,
}) async {
  final result = await AriesResult.invoke(
    AriesMethod.requestProof,
    {'connectionId': connectionId, 'proofRequest': proofRequest.toMap()},
  );

  if (!result.success || result.value == null) {
    return AriesResult(success: false, error: result.error);
  }

  try {
    final resultMap = Map<String, dynamic>.from(jsonDecode(result.value));

    return AriesResult<ProofExchangeRecord>(
      success: result.success,
      error: result.error,
      value: ProofExchangeRecord.fromMap(resultMap),
    );
  } catch (e) {
    print('requestProof - failed to decode = ${e.toString()}\n\n');

    return AriesResult(success: false, error: e.toString());
  }
}

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
    case 'basicMessageReceived':
      final Map<String, String> arguments = Map<String, String>.from(call.arguments);

      print('basicMessageReceived: $arguments');

      final basicMessageRecord =
          BasicMessageRecord.fromMap(jsonDecode(arguments["basicMessageRecord"] ?? '{}'));

      homePageKey.currentState?.basicMessageReceived(basicMessageRecord);

      return "$arguments";
    case 'credentialRevocationReceived':
      print('credentialRevocationReceived on FLUTTER: ${call.arguments}');

      final Map<String, String> arguments = Map<String, String>.from(call.arguments);

      homePageKey.currentState?.credentialRevocationReceived(arguments["id"] ?? '');

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
