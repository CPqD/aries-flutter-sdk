import 'dart:convert';

import 'package:did_agent/agent/models/connection/connection_record.dart';

class BasicMessageRecord {
  final String id;
  final DateTime? createdAt;
  final String content;
  final ConnectionRecord? connectionRecord;

  BasicMessageRecord({
    required this.id,
    required this.createdAt,
    required this.content,
    required this.connectionRecord,
  });

  factory BasicMessageRecord.fromMap(Map<String, dynamic> map) {
    try {
      return BasicMessageRecord(
        id: map["id"].toString(),
        createdAt: DateTime.tryParse(map["createdAt"].toString()),
        content: map["content"].toString(),
        connectionRecord: ConnectionRecord.fromMap(map["connectionRecord"]),
      );
    } catch (e) {
      throw Exception('Failed to create BasicMessageRecord from map: $e');
    }
  }

  static List<BasicMessageRecord> fromList(List<Map<String, dynamic>> list) {
    return list.map((e) => BasicMessageRecord.fromMap(e)).toList();
  }

  static List<BasicMessageRecord> fromJson(String json) {
    try {
      final jsonResult = List<Map<String, dynamic>>.from(jsonDecode(json));

      return fromList(jsonResult);
    } catch (e) {
      throw Exception('Failed to create BasicMessageRecord from json: $e');
    }
  }

  @override
  String toString() {
    return 'BasicMessageRecord{'
        'id: $id, '
        'createdAt: $createdAt, '
        'connectionRecord: $connectionRecord, '
        'content: $content'
        '}';
  }
}
