import 'package:did_agent/agent/models/proof/details/predicate.dart';
import 'package:did_agent/agent/models/proof/proof_attribute.dart';

class ProofRequest {
  final String name;
  final List<ProofAttribute> attributes;
  final List<Predicate> predicates;

  ProofRequest({
    this.name = 'Proof Request',
    required this.attributes,
    required this.predicates,
  });

  Map<String, dynamic> toMap() {
    return {
      "name": name,
      "attributes": attributes.map((attribute) => attribute.toMap()).toList(),
      "predicates": predicates.map((predicate) => predicate.toMap()).toList(),
    };
  }

  @override
  String toString() {
    return 'ProofRequest{'
        'name: "$name", '
        'attributes: $attributes, '
        'predicates: $predicates'
        '}';
  }
}
