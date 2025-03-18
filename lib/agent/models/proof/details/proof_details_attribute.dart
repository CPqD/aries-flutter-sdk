import 'package:did_agent/agent/models/proof/details/requested_attribute.dart';

class ProofDetailsAttribute {
  final String error;
  final String schemaName;
  final List<RequestedAttribute> availableCredentials;

  ProofDetailsAttribute({
    required this.error,
    required this.schemaName,
    required this.availableCredentials,
  });

  factory ProofDetailsAttribute.fromMap(Map<String, dynamic> map) {
    return ProofDetailsAttribute(
      error: map["error"],
      schemaName: map["schemaName"],
      availableCredentials: List<RequestedAttribute>.from(map["availableCredentials"]),
    );
  }

  static List<ProofDetailsAttribute> fromList(List<Map<String, dynamic>> list) {
    return list.map((e) => ProofDetailsAttribute.fromMap(e)).toList();
  }

  @override
  String toString() {
    return 'ProofDetailsAttribute{'
        'error: $error, '
        'schemaName: $schemaName, '
        'availableCredentials: $availableCredentials'
        '}';
  }
}
