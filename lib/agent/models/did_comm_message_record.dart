import 'dart:convert';

import 'package:did_agent/agent/enums/did_comm.dart';
import 'package:did_agent/agent/models/credential_preview.dart';

class DidCommMessageRecord {
  final String id;
  final Map<String, dynamic>? tags;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String message;
  final DidCommMessageRole role;
  final String? associatedRecordId;

  DidCommMessageRecord({
    required this.id,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
    required this.message,
    required this.role,
    required this.associatedRecordId,
  });

  factory DidCommMessageRecord.fromMap(Map<String, dynamic> map) {
    return DidCommMessageRecord(
      id: map["id"].toString(),
      tags: map["tags"] ?? {},
      createdAt: DateTime.tryParse(map["createdAt"].toString()),
      updatedAt: DateTime.tryParse(map["updatedAt"].toString()),
      message: map["message"].toString(),
      role: DidCommMessageRole.from(map["role"].toString()),
      associatedRecordId: map["associatedRecordId"].toString(),
    );
  }

  CredentialPreview getCredentialPreview({bool removeCredRevUuid = false}) {
    try {
      final messageMap = jsonDecode(message);
      return CredentialPreview.fromMap(messageMap["credential_preview"],
          removeCredRevUuid: removeCredRevUuid);
    } catch (e) {
      print("Failed to get CredentialPreview: ${e.toString()}");

      return CredentialPreview(attributes: [], type: '');
    }
  }

  @override
  String toString() {
    return 'DidCommMessageRecord{'
        'id: $id, '
        'tags: $tags, '
        'createdAt: $createdAt, '
        'updatedAt: $updatedAt, '
        'message: $message, '
        'role: $role, '
        'associatedRecordId: $associatedRecordId'
        '}';
  }
}
