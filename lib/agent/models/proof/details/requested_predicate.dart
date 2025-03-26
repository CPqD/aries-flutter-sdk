class RequestedPredicate {
  final String credentialId;
  final String? schemaId;
  final String? credentialDefinitionId;
  final Map<String, String>? attributes;
  final String predicateError;
  final bool revoked;

  RequestedPredicate({
    required this.credentialId,
    required this.schemaId,
    required this.credentialDefinitionId,
    required this.attributes,
    required this.predicateError,
    this.revoked = false,
  });

  factory RequestedPredicate.fromMap(Map<String, dynamic> map) {
    return RequestedPredicate(
      credentialId: map["credentialId"].toString(),
      schemaId: map["schemaId"].toString(),
      credentialDefinitionId: map["credentialDefinitionId"].toString(),
      attributes: Map<String, String>.from(map["attributes"] ?? {}),
      predicateError: map["predicateError"] ?? "",
      revoked: map["revoked"] == true,
    );
  }

  static List<RequestedPredicate> fromList(List<Map<String, dynamic>> list) {
    return list.map((e) => RequestedPredicate.fromMap(e)).toList();
  }

  String getListedName() {
    if (schemaId == null) {
      return "Credencial '$credentialId'";
    }

    final splitSchemaId = schemaId!.split(':');

    if (splitSchemaId.length < 2) {
      return "Credencial '$schemaId'";
    }

    final schemaName = splitSchemaId[splitSchemaId.length - 2];
    final schemaVersion = splitSchemaId[splitSchemaId.length - 1];

    return "Credencial '$schemaName' $schemaVersion";
  }

  @override
  String toString() {
    return 'RequestedPredicate{'
        'credentialId: $credentialId, '
        'schemaId: $schemaId, '
        'credentialDefinitionId: $credentialDefinitionId, '
        'attributes: $attributes, '
        'revoked: $revoked'
        '}';
  }
}
