import 'package:did_agent/agent/models/credential/credential_info.dart';

class ProofRequestedPredicate {
  final String credentialId;
  final CredentialInfo credentialInfo;

  ProofRequestedPredicate({
    required this.credentialId,
    required this.credentialInfo,
  });

  factory ProofRequestedPredicate.fromMap(Map<String, dynamic> map) {
    try {
      return ProofRequestedPredicate(
        credentialId: map["cred_id"] ?? {},
        credentialInfo: CredentialInfo.fromMap(map["credentialInfo"] ?? {}),
      );
    } catch (e) {
      throw Exception(
          "Failed to create ProofRequestedPredicate from map: ${e.toString()}");
    }
  }

  @override
  String toString() {
    return 'ProofRequestedPredicate{'
        'credentialId: $credentialId, '
        'credentialInfo: $credentialInfo'
        '}';
  }
}
