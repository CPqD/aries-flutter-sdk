import 'package:did_agent/agent/enums/history_type.dart';
import 'package:did_agent/agent/models/credential/credential_attribute.dart';

class HistoryRecord {
  final String id;
  final DateTime createdAt;
  final HistoryType historyType;
  final String connectionId;
  final String associatedRecordId;
  final String? theirLabel;
  final String? content;
  final List<CredentialAttribute>? credentialPreviewAttr;
  final String? proofRequestedCredentials;

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

      return HistoryRecord(
        id: map["id"].toString(),
        createdAt: DateTime.tryParse(map["createdAt"].toString()) ?? DateTime.now(),
        historyType: HistoryType.from(map["historyType"].toString()),
        connectionId: map["connectionId"].toString(),
        associatedRecordId: map["associatedRecordId"].toString(),
        theirLabel: map["theirLabel"].toString(),
        content: map["content"].toString(),
        credentialPreviewAttr: credentialPreviewAttrs,
        proofRequestedCredentials: map["proofRequestedCredentials"].toString(),
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
      default:
        return HistoryType.portugueseTranslations[historyType] ?? '';
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
