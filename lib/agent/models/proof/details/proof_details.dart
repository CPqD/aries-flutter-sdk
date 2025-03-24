import 'dart:convert';

import 'package:did_agent/agent/models/proof/details/predicate.dart';
import 'package:did_agent/agent/models/proof/details/proof_details_attribute.dart';
import 'package:did_agent/agent/models/proof/details/proof_details_predicate.dart';

class ProofOfferDetails {
  final List<ProofDetailsAttribute> attributes;
  final List<ProofDetailsPredicate> predicates;
  final Map<String, dynamic> proofRequest;

  ProofOfferDetails({
    required this.attributes,
    required this.predicates,
    required this.proofRequest,
  });

  factory ProofOfferDetails.fromMap(Map<String, dynamic> map) {
    return ProofOfferDetails(
      attributes: ProofDetailsAttribute.fromJson(map["attributes"].toString()),
      predicates: ProofDetailsPredicate.fromJson(map["predicates"].toString()),
      proofRequest: jsonDecode(map["proofRequest"].toString()),
    );
  }

  Map<String, dynamic> getRequestedAttributesMap() {
    try {
      return Map<String, dynamic>.from(proofRequest["requested_attributes"]);
    } catch (e) {
      print('Failed to get map of requested_attributes: $e');
      return {};
    }
  }

  Map<String, dynamic> getRequestedPredicatesMap() {
    try {
      return Map<String, dynamic>.from(proofRequest["requested_predicates"]);
    } catch (e) {
      print('Failed to get map of requested_predicates: $e');
      return {};
    }
  }

  List<String> getAttributeNamesForSchema(String schemaName) {
    final requestedAttributes = getRequestedAttributesMap();

    for (final entry in requestedAttributes.entries) {
      if (entry.key == schemaName) {
        return List<String>.from(entry.value["names"]);
      }
    }

    return [];
  }

  Predicate? getPredicateForName(String attributeName) {
    final requestedPredicates = getRequestedPredicatesMap();

    for (final entry in requestedPredicates.entries) {
      if (entry.key == attributeName) {
        return Predicate.fromMap(entry.value);
      }
    }

    return null;
  }

  @override
  String toString() {
    return 'ProofOfferDetails{'
        'attributes: $attributes, '
        'predicates: $predicates'
        '}';
  }
}
