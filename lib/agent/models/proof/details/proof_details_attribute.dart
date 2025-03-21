import 'dart:convert';

import 'package:did_agent/agent/models/proof/details/requested_attribute.dart';

class ProofDetailsAttribute {
  final String error;
  final String name;
  final List<RequestedAttribute> availableCredentials;

  ProofDetailsAttribute({
    required this.error,
    required this.name,
    required this.availableCredentials,
  });

  factory ProofDetailsAttribute.fromMap(Map<String, dynamic> map) {
    try {
      final availableCredentials =
          List<Map<String, dynamic>>.from(map["availableCredentials"]);

      return ProofDetailsAttribute(
        error: map["error"].toString(),
        name: map["name"].toString(),
        availableCredentials: RequestedAttribute.fromList(availableCredentials),
      );
    } catch (e) {
      throw Exception('Failed to create ProofDetailsAttribute from map: $e');
    }
  }

  static List<ProofDetailsAttribute> fromList(List<Map<String, dynamic>> list) {
    return list.map((e) => ProofDetailsAttribute.fromMap(e)).toList();
  }

  static List<ProofDetailsAttribute> fromJson(String attributesJson) {
    try {
      final attributesList = List<Map<String, dynamic>>.from(jsonDecode(attributesJson));
      return fromList(attributesList);
    } catch (e) {
      throw Exception('Failed to create ProofDetailsAttribute from json: $e');
    }
  }

  @override
  String toString() {
    return 'ProofDetailsAttribute{'
        'error: $error, '
        'name: $name, '
        'availableCredentials: $availableCredentials'
        '}';
  }
}
