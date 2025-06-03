import 'package:did_agent/agent/models/credential/credential_info.dart';
import 'package:did_agent/agent/models/proof/details/predicate.dart';

class RequestedProof {
  final List<String> requestedAttributes;
  final List<Predicate> requestedPredicates;
  final Map<String, dynamic> revealedValues;
  final List<CredentialInfo> associatedCredentials;

  RequestedProof({
    required this.requestedAttributes,
    required this.requestedPredicates,
    required this.revealedValues,
    required this.associatedCredentials,
  });

  factory RequestedProof.fromMap(Map<String, dynamic> map) {
    try {
      List<String> requestedAttributes = [];
      List<Predicate> requestedPredicates = [];

      final proof = map["proof"] ?? {"proofs": []};

      final proofs = List<Map<String, dynamic>>.from(proof["proofs"] ?? []);

      for (final currProof in proofs) {
        final primaryProof = Map<String, dynamic>.from(currProof["primary_proof"] ?? {});

        final attrNames = _getPrimaryProofRevealedAttrs(primaryProof);
        if (attrNames.isNotEmpty) {
          requestedAttributes.addAll(attrNames);
        }

        final predicates = _getPrimaryProofPredicates(primaryProof);
        if (predicates.isNotEmpty) {
          requestedPredicates.addAll(predicates);
        }
      }

      return RequestedProof(
        requestedAttributes: requestedAttributes,
        requestedPredicates: requestedPredicates,
        revealedValues: _getRevealedValues(map),
        associatedCredentials: _getAssociatedCredentials(map),
      );
    } catch (e) {
      throw Exception('Failed to create RequestedProof from map: $e');
    }
  }

  static List<String> _getPrimaryProofRevealedAttrs(Map<String, dynamic> primaryProof) {
    final eqProof = Map<String, dynamic>.from(primaryProof["eq_proof"] ?? {});

    final revealedAttrs = Map<String, dynamic>.from(eqProof["revealed_attrs"] ?? {});

    return revealedAttrs.keys.toList();
  }

  static List<Predicate> _getPrimaryProofPredicates(Map<String, dynamic> primaryProof) {
    List<Predicate> predicates = [];

    final geProofs = List<Map<String, dynamic>>.from(primaryProof["ge_proofs"] ?? []);

    for (final geProof in geProofs) {
      final predicateMap = Map<String, dynamic>.from(geProof["predicate"] ?? {});

      if (predicateMap.containsKey("attr_name")) {
        predicates.add(Predicate.fromMap(predicateMap));
      }
    }

    return predicates;
  }

  static Map<String, dynamic> _getRevealedValues(Map<String, dynamic> map) {
    Map<String, dynamic> revealedValues = {};

    final requestedProof = Map<String, dynamic>.from(map["requested_proof"] ?? {});

    final revealedAttrs =
        Map<String, dynamic>.from(requestedProof["revealed_attrs"] ?? {});

    revealedAttrs.forEach((key, value) {
      final rawValue = value["raw"].toString();

      revealedValues[key] = rawValue;
    });

    return revealedValues;
  }

  static List<CredentialInfo> _getAssociatedCredentials(Map<String, dynamic> map) {
    List<CredentialInfo> associatedCredentials = [];

    final identifiers = List<Map<String, dynamic>>.from(map["identifiers"] ?? []);

    for (final identifier in identifiers) {
      associatedCredentials.add(CredentialInfo.fromMap(identifier));
    }

    return associatedCredentials;
  }

  String asFormatedText() {
    List<String> msg = [];

    if (requestedAttributes.isNotEmpty) {
      msg.add("Atributos Solicitados: \n${requestedAttributes.join(", ")}");
    }

    if (requestedPredicates.isNotEmpty) {
      msg.add("Predicados Solicitados: \n${requestedPredicates.map((p) => p.asExpression()).join(", ")}\n");
    }

    if (revealedValues.isNotEmpty) {
      msg.add("Valores Revelados: \n$revealedValues\n");
    }

    return msg.join("\n\n");
  }

  @override
  String toString() {
    return 'RequestedProof{'
        'requestedAttributes: $requestedAttributes,'
        'requestedPredicates: $requestedPredicates,'
        'revealedValues: $revealedValues,'
        'associatedCredentials: $associatedCredentials'
        '}';
  }
}
