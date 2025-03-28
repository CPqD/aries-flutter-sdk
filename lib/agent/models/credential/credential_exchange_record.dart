import 'dart:convert';

import '../../enums/credential_state.dart';

class CredentialExchangeRecord {
  final String id;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String connectionId;
  final String threadId;
  final String state;
  final String protocolVersion;

  CredentialExchangeRecord({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.connectionId,
    required this.threadId,
    required this.state,
    required this.protocolVersion,
  });

  factory CredentialExchangeRecord.fromMap(Map<String, dynamic> map) {
    return CredentialExchangeRecord(
      id: map["id"].toString(),
      createdAt: DateTime.tryParse(map["createdAt"].toString()),
      updatedAt: DateTime.tryParse(map["updatedAt"].toString()),
      connectionId: map["connectionId"].toString(),
      threadId: map["threadId"].toString(),
      state: map["state"].toString(),
      protocolVersion: map["protocolVersion"].toString(),
    );
  }

  String getStateInPortuguese() {
    return CredentialState.portugueseTranslations[state] ?? 'Estado Desconhecido';
  }

  @override
  String toString() {
    return 'CredentialExchangeRecord{'
        'id: $id, '
        'createdAt: $createdAt, '
        'updatedAt: $updatedAt, '
        'connectionId: $connectionId, '
        'connectionId: $threadId, '
        'state: $state, '
        'protocolVersion: $protocolVersion'
        '}';
  }

  static List<CredentialExchangeRecord> fromList(List<Map<String, dynamic>> list) {
    return list.map((e) => CredentialExchangeRecord.fromMap(e)).toList();
  }

  static List<CredentialExchangeRecord> fromJson(String json) {
    try {
      final jsonResult = List<Map<String, dynamic>>.from(jsonDecode(json));
      return fromList(jsonResult);
    } catch (e) {
      throw Exception('Failed to create CredentialExchangeRecord from json: $e');
    }
  }
}
