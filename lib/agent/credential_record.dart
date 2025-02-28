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

  factory CredentialRecord.fromMap(Map<String, String?> map) {
    return CredentialRecord(
      id: map["id"] ?? '',
      revocationId: map["revocationId"] ?? '',
      linkSecretId: map["linkSecretId"] ?? '',
      credential: map["credential"] ?? '',
      schemaId: map["schemaId"] ?? '',
      schemaName: map["schemaName"] ?? '',
      schemaVersion: map["schemaVersion"] ?? '',
      schemaIssuerId: map["schemaIssuerId"] ?? '',
      issuerId: map["issuerId"] ?? '',
      definitionId: map["definitionId"] ?? '',
      revocationRegistryId: map["revocationRegistryId"] ?? '',
    );
  }

  @override
  String toString() {
    return 'CredentialRecord{id: $id, revocationId: $revocationId, linkSecretId: $linkSecretId, schemaId: $schemaId}';
  }
}
