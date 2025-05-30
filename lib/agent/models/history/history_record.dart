import 'dart:convert';

import 'package:did_agent/agent/enums/history_type.dart';
import 'package:did_agent/agent/models/credential/credential_attribute.dart';
import 'package:did_agent/agent/models/proof/proof_requested_credentials.dart';

class HistoryRecord {
  final String id;
  final DateTime createdAt;
  final HistoryType historyType;
  final String connectionId;
  final String associatedRecordId;
  final String? theirLabel;
  final String? content;
  final List<CredentialAttribute>? credentialPreviewAttr;
  final ProofRequestedCredentials? proofRequestedCredentials;

  HistoryRecord(
      {required this.id,
      required this.createdAt,
      required this.historyType,
      required this.connectionId,
      required this.associatedRecordId,
      this.theirLabel,
      this.content,
      this.credentialPreviewAttr,
      this.proofRequestedCredentials});

  factory HistoryRecord.fromMap(Map<String, dynamic> map) {
    try {
      List<CredentialAttribute>? credentialPreviewAttrs;

      if (map["credentialPreviewAttr"] != null) {
        final credPreviewAttrMap =
            List<Map<String, dynamic>>.from(map["credentialPreviewAttr"]);

        credentialPreviewAttrs = CredentialAttribute.fromList(credPreviewAttrMap);
      }

      ProofRequestedCredentials? proofRequestedCredentials;

      if (map["proofRequestedCredentials"] != null) {
        final proofRequestedCredentialsMap =
            jsonDecode(map["proofRequestedCredentials"].toString());

        proofRequestedCredentials =
            ProofRequestedCredentials.fromMap(proofRequestedCredentialsMap);
      }

      return HistoryRecord(
        id: map["id"].toString(),
        createdAt: DateTime.tryParse(map["createdAt"].toString()) ?? DateTime.now(),
        historyType: HistoryType.from(map["historyType"].toString()),
        connectionId: map["connectionId"].toString(),
        associatedRecordId: map["associatedRecordId"].toString(),
        theirLabel: map["theirLabel"].toString(),
        content: map["content"].toString(),
        credentialPreviewAttr: credentialPreviewAttrs,
        proofRequestedCredentials: proofRequestedCredentials,
      );
    } catch (e) {
      throw Exception('Failed to create HistoryRecord from map: $e');
    }
  }

  static List<HistoryRecord> fromList(List<Map<String, dynamic>> list) {
    return list.map((e) => HistoryRecord.fromMap(e)).toList();
  }

  bool wasSent() {
    return HistoryType.isSent(historyType.value);
  }

  String getTitle() {
    switch (historyType) {
      case HistoryType.basicMessageReceived:
      case HistoryType.basicMessageSent:
        return content ?? '';
      case HistoryType.connectionCreated:
        return theirLabel == null ? 'Conexão criada' : 'Conexão criada com $theirLabel';
      case HistoryType.credentialRevoked:
        return theirLabel == null
            ? 'Credencial revogada'
            : 'Credencial revogada por $theirLabel';
      case HistoryType.credentialOfferReceived:
        return theirLabel == null
            ? 'Oferta de credencial recebida'
            : '$theirLabel enviou uma oferta de credencial';
      case HistoryType.credentialOfferAccepted:
        return 'Oferta de credencial aceita';
      case HistoryType.credentialOfferDeclined:
        return 'Oferta de credencial recusada';
      case HistoryType.proofRequestReceived:
        return theirLabel == null
            ? 'Oferta de prova recebida'
            : 'Oferta de prova solicitada por $theirLabel';
      case HistoryType.proofRequestAccepted:
        return theirLabel == null
            ? 'Prova realizada'
            : 'Prova realizada para $theirLabel';
      case HistoryType.proofRequestDeclined:
        return theirLabel == null
            ? 'Prova recusada'
            : 'Prova de $theirLabel foi recusada';
    }
  }

  @override
  String toString() {
    return 'HistoryRecord{'
        'id: $id, '
        'createdAt: $createdAt, '
        'historyType: ${historyType.value}, '
        'connectionId: $connectionId, '
        'associatedRecordId: $associatedRecordId, '
        'theirLabel: $theirLabel, '
        'content: $content, '
        'credentialPreviewAttr: $credentialPreviewAttr, '
        'proofRequestedCredentials: $proofRequestedCredentials'
        '}';
  }
}
