class DidDoc {
  final String id;
  final String context;
  final List<Map<String, dynamic>> publicKey;
  final List<dynamic> authentication;
  final List<Map<String, dynamic>> service;

  DidDoc({
    required this.id,
    required this.context,
    required this.publicKey,
    required this.authentication,
    required this.service,
  });

  factory DidDoc.fromMap(Map<String, dynamic> map) {
    try {
      return DidDoc(
        id: map["id"].toString(),
        context: map["context"].toString(),
        publicKey: List<Map<String, dynamic>>.from(map["publicKey"] ?? []),
        authentication: List<dynamic>.from(map["authentication"] ?? []),
        service: List<Map<String, dynamic>>.from(map["service"] ?? []),
      );
    } catch (e) {
      throw Exception('Failed to create DidDoc from map: $e');
    }
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
