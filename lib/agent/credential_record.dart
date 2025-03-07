import 'dart:convert';

class CredentialRecord {
  final String id;
  final String revocationId;
  final String linkSecretId;
  final String credential;
  final String schemaId;
  final String schemaName;
  final String schemaVersion;
  final String schemaIssuerId;
  final String issuerId;
  final String definitionId;

  String? revocationRegistryId;

  CredentialRecord({
    required this.id,
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
  });

  factory CredentialRecord.fromMap(Map<String, dynamic> map) {
    return CredentialRecord(
      id: map["id"].toString(),
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
    );
  }

  String getSubtitle() {
    return 'revocationId: $revocationId\n'
        'schemaName: $schemaName\n'
        'schemaVersion: $schemaVersion';
  }

  Map<String, dynamic> getValues() {
    try {
      final decodedCredential = Map<String, dynamic>.from(jsonDecode(credential));
      return Map<String, dynamic>.from(decodedCredential["values"]);
    } catch (e) {
      print('Failed to get credential values: ${e.toString()}');
      return {};
    }
  }

  Map<String, dynamic> getRawValues() {
    try {
      final values = getValues();

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
        'id: $id, '
        'revocationId: $revocationId, '
        'linkSecretId: $linkSecretId, '
        'schemaId: $schemaId, '
        'schemaName: $schemaName, '
        'schemaVersion: $schemaVersion, '
        'schemaIssuerId: $schemaIssuerId, '
        'issuerId: $issuerId, '
        'definitionId: $definitionId, '
        'revocationRegistryId: $revocationRegistryId'
        '}';
  }
}
