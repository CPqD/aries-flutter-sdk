import 'dart:convert';

import 'package:did_agent/agent/models/credential/credential_revocation_notification.dart';

class CredentialRecord {
  final String recordId;
  final String credentialId;
  final Map<String, dynamic> attributes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String revocationId;
  final String linkSecretId;
  final String credential;
  final String schemaId;
  final String schemaName;
  final String schemaVersion;
  final String schemaIssuerId;
  final String issuerId;
  final String definitionId;
  final RevocationNotification? revocationNotification;

  String? revocationRegistryId;

  CredentialRecord({
    required this.recordId,
    required this.credentialId,
    required this.attributes,
    required this.createdAt,
    required this.updatedAt,
    required this.revocationId,
    required this.linkSecretId,
    required this.credential,
    required this.schemaId,
    required this.schemaName,
    required this.schemaVersion,
    required this.schemaIssuerId,
    required this.issuerId,
    required this.definitionId,
    this.revocationRegistryId,
    this.revocationNotification,
  });

  factory CredentialRecord.fromMap(Map<String, dynamic> map) {
    return CredentialRecord(
      recordId: map["recordId"].toString(),
      credentialId: map["credentialId"].toString(),
      attributes: Map<String, dynamic>.from(map["attributes"] ?? {}),
      createdAt: DateTime.tryParse(map["createdAt"].toString()),
      updatedAt: DateTime.tryParse(map["updatedAt"].toString()),
      revocationId: map["revocationId"].toString(),
      linkSecretId: map["linkSecretId"].toString(),
      credential: map["credential"].toString(),
      schemaId: map["schemaId"].toString(),
      schemaName: map["schemaName"].toString(),
      schemaVersion: map["schemaVersion"].toString(),
      schemaIssuerId: map["schemaIssuerId"].toString(),
      issuerId: map["issuerId"].toString(),
      definitionId: map["definitionId"].toString(),
      revocationRegistryId: map["revocationRegistryId"].toString(),
      revocationNotification: map["revocationNotification"] == null
          ? null
          : RevocationNotification.fromMap(map["revocationNotification"]),
    );
  }

  String getSubtitle() {
    return 'ID: $credentialId\n'
        '${createdAt?.toLocal()}';
  }

  Map<String, dynamic> getRawValues() {
    try {
      final decodedCredential = Map<String, dynamic>.from(jsonDecode(credential));
      return Map<String, dynamic>.from(decodedCredential["values"]);
    } catch (e) {
      print('Failed to get credential values: ${e.toString()}');
      return {};
    }
  }

  Map<String, dynamic> getValues() {
    try {
      final values = getRawValues();

      Map<String, dynamic> simplifiedValues = {};

      values.forEach((key, value) {
        simplifiedValues[key] = Map<String, dynamic>.from(value)['raw'];
      });

      return simplifiedValues;
    } catch (e) {
      print('Failed to get credential values: ${e.toString()}');
      return {};
    }
  }

  @override
  String toString() {
    return 'CredentialRecord{'
        'recordId: $recordId, '
        'credentialId: $credentialId, '
        'attributes: $attributes, '
        'createdAt: $createdAt, '
        'updatedAt: $updatedAt, '
        'revocationId: $revocationId, '
        'linkSecretId: $linkSecretId, '
        'schemaId: $schemaId, '
        'schemaName: $schemaName, '
        'schemaVersion: $schemaVersion, '
        'schemaIssuerId: $schemaIssuerId, '
        'issuerId: $issuerId, '
        'definitionId: $definitionId, '
        'revocationRegistryId: $revocationRegistryId, '
        'revocationNotification: $revocationNotification'
        '}';
  }
}
