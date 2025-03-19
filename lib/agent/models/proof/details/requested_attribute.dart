import 'package:did_agent/agent/models/credential/credential_record.dart';
import 'package:did_agent/util/utils.dart';

class RequestedAttribute {
  final String credentialId;
  final String? schemaId;
  final String? credentialDefinitionId;
  final bool revoked;

  CredentialRecord? record;

  RequestedAttribute({
    required this.credentialId,
    required this.schemaId,
    required this.credentialDefinitionId,
    this.revoked = false,
  });

  factory RequestedAttribute.fromMap(Map<String, dynamic> map) {
    try {
      final requestedAttribute = RequestedAttribute(
        credentialId: map["credentialId"].toString(),
        schemaId: map["schemaId"].toString(),
        credentialDefinitionId: map["credentialDefinitionId"].toString(),
        revoked: (map["revoked"] == true),
      );

      requestedAttribute.getRecord();

      return requestedAttribute;
    } catch (e) {
      throw Exception('Failed to create RequestedAttribute from map: $e');
    }
  }

  static List<RequestedAttribute> fromList(List<Map<String, dynamic>> list) {
    return list.map((e) => RequestedAttribute.fromMap(e)).toList();
  }

  Future<CredentialRecord?> getRecord() async {
    if (record == null) {
      final result = await getCredential(credentialId);

      if (result.success) record = result.value;
    }

    return record;
  }

  String getListedName() {
    return "Credencial '${record?.schemaName ?? credentialId}'";
  }

  @override
  String toString() {
    return 'RequestedAttribute{'
        'credentialId: $credentialId, '
        'schemaId: $schemaId, '
        'credentialDefinitionId: $credentialDefinitionId, '
        'revoked: $revoked'
        '}';
  }
}
