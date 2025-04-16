class CredentialInfo {
  final String referent;
  final String schemaId;
  final String credDefId;
  final Map<String, String> attributes;

  CredentialInfo({
    required this.referent,
    required this.schemaId,
    required this.credDefId,
    required this.attributes,
  });

  factory CredentialInfo.fromMap(Map<String, dynamic> map) {
    return CredentialInfo(
      referent: map["referent"].toString(),
      schemaId: map["schema_id"].toString(),
      credDefId: map["cred_def_id"].toString(),
      attributes: Map<String, String>.from(map["attrs"] ?? {}),
    );
  }

  @override
  String toString() {
    return 'CredentialInfo{'
        'referent: $referent, '
        'schemaId: $schemaId, '
        'credDefId: $credDefId, '
        'attributes: $attributes'
        '}';
  }
}
