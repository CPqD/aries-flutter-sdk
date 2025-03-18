class RequestedAttribute {
  final String credentialId;
  final String? schemaId;
  final String? credentialDefinitionId;
  final bool revoked;

  RequestedAttribute({
    required this.credentialId,
    required this.schemaId,
    required this.credentialDefinitionId,
    this.revoked = false,
  });

  factory RequestedAttribute.fromMap(Map<String, dynamic> map) {
    return RequestedAttribute(
      credentialId: map["credentialId"],
      schemaId: map["schemaId"],
      credentialDefinitionId: map["credentialDefinitionId"],
      revoked: map["revoked"],
    );
  }

  @override
  String toString() {
    return 'RequestedAttribute{'
        'credentialId: $credentialId, '
        'schemaId: $schemaId, '
        'credentialDefinitionId: $credentialDefinitionId, '
        'revoked: $revoked'
        '}';
  }
}
