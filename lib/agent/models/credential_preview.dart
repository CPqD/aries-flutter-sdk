import 'package:did_agent/agent/models/credential_attributes.dart';

class CredentialPreview {
  final String type;
  final List<CredentialAttribute> attributes;

  CredentialPreview({
    required this.type,
    required this.attributes,
  });

  factory CredentialPreview.fromMap(Map<String, dynamic> map,
      {bool removeCredRevUuid = false}) {
    var attributes = List<Map<String, dynamic>>.from(map["attributes"])
        .map((attribute) => CredentialAttribute.fromMap(attribute));

    if (removeCredRevUuid) {
      attributes = attributes.where((attribute) => attribute.name != "cred_rev_uuid");
    }

    return CredentialPreview(
      type: map["@type"].toString(),
      attributes: attributes.toList(),
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
