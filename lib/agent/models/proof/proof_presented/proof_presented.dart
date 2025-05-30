class ProofPresented {
  final List<Map<String, dynamic>> revealedAttributes;
  final List<String> predicates;
  final List<Map<String, dynamic>> credentials;

  ProofPresented({
    required this.revealedAttributes,
    required this.predicates,
    required this.credentials,
  });

  factory ProofPresented.fromMap(Map<String, dynamic> map) {
    try {
      return ProofPresented(
        revealedAttributes: List<Map<String, dynamic>>.from(map["revealed_attrs"] ?? []),
        predicates: List<String>.from(map["predicates"] ?? []),
        credentials: List<Map<String, dynamic>>.from(map["credentials"] ?? []),
      );
    } catch (e) {
      throw Exception('Failed to create ProofPresented from map: $e');
    }
  }

  String content() {
    return 'Atributos: $revealedAttributes.\n\nCredenciais: $credentials';
  }

  @override
  String toString() {
    return 'ProofPresented{'
        'revealed_attrs: $revealedAttributes, '
        'predicates: $predicates, '
        'credentials: $credentials'
        '}';
  }
}
