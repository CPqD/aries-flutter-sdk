class DidDoc {
  final String id;
  final String context;
  final List<Map<String, dynamic>> publicKey;
  final List<String> authentication;
  final List<Map<String, dynamic>> service;

  DidDoc({
    required this.id,
    required this.context,
    required this.publicKey,
    required this.authentication,
    required this.service,
  });

  factory DidDoc.fromMap(Map<String, dynamic> map) {
    return DidDoc(
      id: map["id"].toString(),
      context: map["context"].toString(),
      publicKey: List<Map<String, dynamic>>.from(map["publicKey"] ?? []),
      authentication: List<String>.from(map["authentication"] ?? []),
      service: List<Map<String, dynamic>>.from(map["service"] ?? []),
    );
  }

  @override
  String toString() {
    return 'DidDoc{'
        'id: $id, '
        'context: $context, '
        'publicKey: $publicKey, '
        'authentication: ${authentication.toString()}, '
        'service: $service'
        '}';
  }
}
