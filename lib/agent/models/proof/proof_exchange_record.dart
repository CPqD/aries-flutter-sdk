import 'dart:convert';

import '../../enums/proof_state.dart';

class ProofExchangeRecord {
  final String id;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String connectionId;
  final String threadId;
  final String state;

  ProofExchangeRecord({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.connectionId,
    required this.threadId,
    required this.state,
  });

  factory ProofExchangeRecord.fromMap(Map<String, dynamic> map) {
    return ProofExchangeRecord(
      id: map["id"].toString(),
      createdAt: DateTime.tryParse(map["createdAt"].toString()),
      updatedAt: DateTime.tryParse(map["updatedAt"].toString()),
      connectionId: map["connectionId"].toString(),
      threadId: map["threadId"].toString(),
      state: map["state"].toString(),
    );
  }

  static List<ProofExchangeRecord> fromList(List<Map<String, dynamic>> list) {
    return list.map((e) => ProofExchangeRecord.fromMap(e)).toList();
  }

  static List<ProofExchangeRecord> fromJson(String json) {
    try {
      final jsonResult = List<Map<String, dynamic>>.from(jsonDecode(json));
      return fromList(jsonResult);
    } catch (e) {
      throw Exception('Failed to create CredentialExchangeRecord from json: $e');
    }
  }

  String getStateInPortuguese() {
    return ProofState.portugueseTranslations[state] ?? 'Estado Desconhecido';
  }

  @override
  String toString() {
    return 'ProofExchangeRecord{'
        'id: $id, '
        'createdAt: $createdAt, '
        'updatedAt: $updatedAt, '
        'connectionId: $connectionId, '
        'connectionId: $threadId, '
        'state: $state'
        '}';
  }
}
