class RequestedAttribute {
  final String credentialId;
  final String? schemaId;
  final String? credentialDefinitionId;
  final Map<String, String>? attributes;
  final bool revoked;

  RequestedAttribute({
    required this.credentialId,
    required this.schemaId,
    required this.credentialDefinitionId,
    required this.attributes,
    this.revoked = false,
  });

  factory RequestedAttribute.fromMap(Map<String, dynamic> map) {
    try {
      final requestedAttribute = RequestedAttribute(
        credentialId: map["credentialId"].toString(),
        schemaId: map["schemaId"].toString(),
        credentialDefinitionId: map["credentialDefinitionId"].toString(),
        attributes: Map<String, String>.from(map["attributes"] ?? {}),
        revoked: (map["revoked"] == true),
      );

      return requestedAttribute;
    } catch (e) {
      throw Exception('Failed to create RequestedAttribute from map: $e');
    }
  }

  static List<RequestedAttribute> fromList(List<Map<String, dynamic>> list) {
    return list.map((e) => RequestedAttribute.fromMap(e)).toList();
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
    return 'RequestedAttribute{'
        'credentialId: $credentialId, '
        'schemaId: $schemaId, '
        'credentialDefinitionId: $credentialDefinitionId, '
        'attributes: $attributes, '
        'revoked: $revoked'
        '}';
  }
}
