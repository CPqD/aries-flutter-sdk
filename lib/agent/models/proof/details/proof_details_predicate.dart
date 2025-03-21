import 'dart:convert';

import 'package:did_agent/agent/models/proof/details/requested_predicate.dart';

class ProofDetailsPredicate {
  final String error;
  final String name;
  final List<RequestedPredicate> availableCredentials;

  ProofDetailsPredicate({
    required this.error,
    required this.name,
    required this.availableCredentials,
  });

  factory ProofDetailsPredicate.fromMap(Map<String, dynamic> map) {
    try {
      final availableCredentials =
          List<Map<String, dynamic>>.from(map["availableCredentials"]);

      return ProofDetailsPredicate(
        error: map["error"].toString(),
        name: map["name"].toString(),
        availableCredentials: RequestedPredicate.fromList(availableCredentials),
      );
    } catch (e) {
      throw Exception('Failed to create ProofDetailsPredicate from map: $e');
    }
  }

  static List<ProofDetailsPredicate> fromList(List<Map<String, dynamic>> list) {
    return list.map((e) => ProofDetailsPredicate.fromMap(e)).toList();
  }

  static List<ProofDetailsPredicate> fromJson(String predicatesJson) {
    try {
      final predicatesList = List<Map<String, dynamic>>.from(jsonDecode(predicatesJson));
      return fromList(predicatesList);
    } catch (e) {
      throw Exception('Failed to create ProofDetailsPredicate from json: $e');
    }
  }

  @override
  String toString() {
    return 'ProofDetailsPredicate{'
        'error: $error, '
        'name: $name, '
        'availableCredentials: $availableCredentials'
        '}';
  }
}
