class SchemaAttributes {
  final String schemaName;
  final List<String> attributeNames;
  final List<Map<String, dynamic>> restrictions;

  SchemaAttributes({
    required this.schemaName,
    required this.attributeNames,
    required this.restrictions,
  });

  factory SchemaAttributes.fromKeyAndMap(String key, Map<String, dynamic> map) {
    return SchemaAttributes(
      schemaName: key,
      attributeNames: List<String>.from(map[key]["names"]),
      restrictions: List<Map<String, dynamic>>.from(map[key]["restrictions"]),
    );
  }

  static List<SchemaAttributes> fromMap(Map<String, dynamic> map) {
    List<SchemaAttributes> schemaAttrsList = [];

    map.forEach((key, value) {
      schemaAttrsList.add(
        SchemaAttributes.fromKeyAndMap(key, map),
      );
    });

    return schemaAttrsList;
  }

  @override
  String toString() {
    return 'SchemaAttributes{'
        'schemaName: $schemaName, '
        'attributeNames: $attributeNames, '
        'restrictions: $restrictions'
        '}';
  }
}
