import 'package:did_agent/agent/models/credential/credential_attributes.dart';

class CredentialPreview {
  final String type;
  final List<CredentialAttribute> attributes;

  CredentialPreview({
    required this.type,
    required this.attributes,
  });

  factory CredentialPreview.fromMap(Map<String, dynamic> map) {
    return CredentialPreview(
      type: map["@type"].toString(),
      attributes: List<Map<String, dynamic>>.from(map["attributes"])
          .map((attribute) => CredentialAttribute.fromMap(attribute))
          .toList(),
    );
  }

  @override
  String toString() {
    return 'CredentialPreview{'
        'type: $type, '
        'attributes: $attributes'
        '}';
  }
}
