import 'package:did_agent/agent/models/schema_attributes.dart';

class ProofPreview {
  final String name;
  final String nonce;
  final String version;
  final Map<String, dynamic> nonRevoked;
  final Map<String, dynamic> requestedPredicates;
  final List<SchemaAttributes> requestedAttributes;

  ProofPreview({
    this.name = '',
    this.nonce = '',
    this.version = '',
    required this.nonRevoked,
    required this.requestedPredicates,
    required this.requestedAttributes,
  });

  factory ProofPreview.fromMap(Map<String, dynamic> map) {
    return ProofPreview(
      name: map["name"].toString(),
      nonce: map["nonce"].toString(),
      version: map["version"].toString(),
      nonRevoked: map["nonRevoked"] ?? {},
      requestedPredicates: map["requested_predicates"] ?? {},
      requestedAttributes: SchemaAttributes.fromMap(map["requested_attributes"] ?? {}),
    );
  }

  @override
  String toString() {
    return 'ProofPreview{'
        'name: $name, '
        'nonce: $nonce, '
        'version: $version, '
        'nonRevoked: $nonRevoked, '
        'requestedPredicates: $requestedPredicates, '
        'requestedAttributes: $requestedAttributes'
        '}';
  }
}
