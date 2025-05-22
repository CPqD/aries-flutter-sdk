class ProofAttribute {
  final String name;
  final List<String> names;
  final String credDefId;
  final String schemaName;

  ProofAttribute({
    this.name = '',
    this.names = const [],
    this.credDefId = '',
    this.schemaName = '',
  });

  Map<String, dynamic> toMap() {
    return {
      "name": name,
      "names": names,
      "credDefId": credDefId,
      "schemaName": schemaName
    };
  }

  @override
  String toString() {
    return 'ProofAttribute{'
        'name: "$name", '
        'names: $names, '
        'credDefId: "$credDefId", '
        'schemaName: "$schemaName"'
        '}';
  }
}
