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
    return ProofOfferDetails(
      attributes: ProofDetailsAttribute.fromJson(map["attributes"].toString()),
      predicates: ProofDetailsPredicate.fromJson(map["predicates"].toString()),
      didCommMessageRecord: didCommMessageRecord,
    );
  }

  List<String> getAttributeNamesForSchema(String schemaName) {
    final requestedAttributes =
        didCommMessageRecord.getProofPreview().requestedAttributes;

    for (final schemaAttributes in requestedAttributes) {
      if (schemaAttributes.schemaName == schemaName) {
        return schemaAttributes.attributeNames;
      }
    }

    return [];
  }

  @override
  String toString() {
    return 'ProofOfferDetails{'
        'attributes: $attributes, '
        'predicates: $predicates'
        '}';
  }
}
