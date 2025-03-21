import 'dart:convert';

import 'package:did_agent/agent/enums/did_comm.dart';
import 'package:did_agent/agent/models/credential/credential_preview.dart';
import 'package:did_agent/agent/models/proof/proof_preview.dart';

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

  CredentialPreview getCredentialPreview() {
    try {
      final messageMap = jsonDecode(message);
      return CredentialPreview.fromMap(messageMap["credential_preview"]);
    } catch (e) {
      print("Failed to get CredentialPreview: ${e.toString()}");

      return CredentialPreview(attributes: [], type: '');
    }
  }

  ProofPreview getProofPreview() {
    try {
      final messageMap = jsonDecode(message);
      final presentations =
          List<Map<String, dynamic>>.from(messageMap["request_presentations~attach"]);

      final requestPresentation = presentations.isEmpty ? {} : presentations[0];

      String encodedPreview = requestPresentation['data']['base64'];

      String decodedPreview = utf8.decode(base64Decode(encodedPreview));

      final preview = jsonDecode(decodedPreview);

      return ProofPreview.fromMap(preview);
    } catch (e) {
      print("Failed to get ProofPreview: ${e.toString()}");

      return ProofPreview(
        nonRevoked: {},
        requestedPredicates: {},
        requestedAttributes: [],
      );
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
