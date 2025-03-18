import 'dart:convert';

import 'package:did_agent/agent/models/did_comm_message_record.dart';
import 'package:did_agent/agent/models/proof/details/proof_details_attribute.dart';
import 'package:did_agent/agent/models/proof/details/proof_details_predicate.dart';

class ProofOfferDetails {
  final List<ProofDetailsAttribute> attributes;
  final List<ProofDetailsPredicate> predicates;
  final DidCommMessageRecord didCommMessageRecord;

  ProofOfferDetails({
    required this.attributes,
    required this.predicates,
    required this.didCommMessageRecord,
  });

  factory ProofOfferDetails.from(
      Map<String, dynamic> map, DidCommMessageRecord didCommMessageRecord) {
    final attributesList = List<Map<String, dynamic>>.from(jsonDecode(map["attributes"]));
    final predicatesList = List<Map<String, dynamic>>.from(jsonDecode(map["predicates"]));

    return ProofOfferDetails(
      attributes: ProofDetailsAttribute.fromList(attributesList),
      predicates: ProofDetailsPredicate.fromList(predicatesList),
      didCommMessageRecord: didCommMessageRecord,
    );
  }

  @override
  String toString() {
    return 'ProofOfferDetails{'
        'attributes: $attributes, '
        'predicates: $predicates'
        '}';
  }
}
