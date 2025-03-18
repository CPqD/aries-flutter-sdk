import 'package:did_agent/agent/models/proof/details/requested_predicate.dart';

class ProofDetailsPredicate {
  final String error;
  final String schemaName;
  final List<RequestedPredicate> availableCredentials;

  ProofDetailsPredicate({
    required this.error,
    required this.schemaName,
    required this.availableCredentials,
  });

  factory ProofDetailsPredicate.fromMap(Map<String, dynamic> map) {
    return ProofDetailsPredicate(
      error: map["error"],
      schemaName: map["schemaName"],
      availableCredentials: List<RequestedPredicate>.from(map["availableCredentials"]),
    );
  }

  static List<ProofDetailsPredicate> fromList(List<Map<String, dynamic>> list) {
    return list.map((e) => ProofDetailsPredicate.fromMap(e)).toList();
  }

  @override
  String toString() {
    return 'ProofDetailsPredicate{'
        'error: $error, '
        'schemaName: $schemaName, '
        'availableCredentials: $availableCredentials'
        '}';
  }
}
