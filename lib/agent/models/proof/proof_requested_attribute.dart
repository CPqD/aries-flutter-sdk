import 'package:did_agent/agent/models/credential/credential_info.dart';

class ProofRequestedAttribute {
  final String credentialId;
  final CredentialInfo credentialInfo;
  final bool revealed;

  ProofRequestedAttribute({
    required this.credentialId,
    required this.credentialInfo,
    required this.revealed,
  });

  factory ProofRequestedAttribute.fromMap(Map<String, dynamic> map) {
    try {
      return ProofRequestedAttribute(
        credentialId: map["cred_id"] ?? {},
        credentialInfo: CredentialInfo.fromMap(map["credentialInfo"] ?? {}),
        revealed: (map["revealed"] == true),
      );
    } catch (e) {
      throw Exception(
          "Failed to create ProofRequestedAttribute from map: ${e.toString()}");
    }
  }

  @override
  String toString() {
    return 'ProofRequestedAttribute{'
        'credentialId: $credentialId, '
        'credentialInfo: $credentialInfo, '
        'revealed: $revealed'
        '}';
  }
}
