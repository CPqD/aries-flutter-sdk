class RequestedPredicate {
  final String credentialId;
  final String? schemaId;
  final String? credentialDefinitionId;
  final bool revoked;

  RequestedPredicate({
    required this.credentialId,
    required this.schemaId,
    required this.credentialDefinitionId,
    this.revoked = false,
  });

  factory RequestedPredicate.fromMap(Map<String, dynamic> map) {
    return RequestedPredicate(
      credentialId: map["credentialId"],
      schemaId: map["schemaId"],
      credentialDefinitionId: map["credentialDefinitionId"],
      revoked: map["revoked"],
    );
  }

  @override
  String toString() {
    return 'RequestedPredicate{'
        'credentialId: $credentialId, '
        'schemaId: $schemaId, '
        'credentialDefinitionId: $credentialDefinitionId, '
        'revoked: $revoked'
        '}';
  }
}
