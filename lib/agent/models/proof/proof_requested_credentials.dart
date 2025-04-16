import 'package:did_agent/agent/models/proof/proof_requested_attribute.dart';
import 'package:did_agent/agent/models/proof/proof_requested_predicate.dart';

class ProofRequestedCredentials {
  final Map<String, ProofRequestedAttribute> requestedAttributes;
  final Map<String, ProofRequestedPredicate> requestedPredicates;
  final Map<String, dynamic> selfAttestedAttributes;

  ProofRequestedCredentials({
    required this.requestedAttributes,
    required this.requestedPredicates,
    required this.selfAttestedAttributes,
  });

  factory ProofRequestedCredentials.fromMap(Map<String, dynamic> map) {
    try {
      final requestedAttributesMap = map["requested_attributes"] ?? {};
      final requestedPredicatesMap = map["requested_predicates"] ?? {};

      Map<String, ProofRequestedAttribute> requestedAttributes = {};

      requestedAttributesMap.forEach((key, value) {
        final valueMap = Map<String, dynamic>.from(value);
        requestedAttributes[key] = ProofRequestedAttribute.fromMap(valueMap);
      });

      Map<String, ProofRequestedPredicate> requestedPredicates = {};

      requestedPredicatesMap.forEach((key, value) {
        final valueMap = Map<String, dynamic>.from(value);
        requestedPredicates[key] = ProofRequestedPredicate.fromMap(valueMap);
      });

      return ProofRequestedCredentials(
        requestedAttributes: requestedAttributes,
        requestedPredicates: requestedPredicates,
        selfAttestedAttributes: map["self_attested_attributes"] ?? {},
      );
    } catch (e) {
      throw Exception(
          "Failed to create ProofRequestedCredentials from map: ${e.toString()}");
    }
  }

  @override
  String toString() {
    return 'ProofRequestedCredentials{'
        'requestedAttributes: $requestedAttributes, '
        'requestedPredicates: $requestedPredicates, '
        'selfAttestedAttributes: $selfAttestedAttributes'
        '}';
  }
}
