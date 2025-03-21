import 'package:did_agent/agent/aries_result.dart';
import 'package:did_agent/agent/models/credential/credential_exchange_record.dart';
import 'package:did_agent/agent/models/proof/proof_exchange_record.dart';
import 'package:did_agent/global.dart';
import 'package:did_agent/util/utils.dart';

enum NotificationType {
  credentialOffer('credentialOffer'),
  proofOffer('proofOffer');

  final String value;

  const NotificationType(this.value);
}

final class AriesNotification {
  final String id;
  final String title;
  final NotificationType type;
  final DateTime receivedAt;
  final Future<AriesResult> Function([dynamic params]) onAccept;
  final Future<AriesResult> Function() onRefuse;

  AriesNotification({
    required this.id,
    required this.title,
    required this.type,
    required this.receivedAt,
    required this.onAccept,
    required this.onRefuse,
  });

  factory AriesNotification.fromCredentialOffer(CredentialExchangeRecord credOffer) {
    return AriesNotification(
      id: credOffer.id,
      title: 'Oferta de Credential Recebida',
      type: NotificationType.credentialOffer,
      receivedAt: credOffer.createdAt ?? DateTime.now(),
      onAccept: ([params]) async {
        final acceptOfferResult =
            await acceptCredentialOffer(credOffer.id, credOffer.protocolVersion);

        if (acceptOfferResult.success) {
          print('Credential Accepted: ${credOffer.id}');
        }

        return acceptOfferResult;
      },
      onRefuse: () async {
        final declineOfferResult =
            await declineCredentialOffer(credOffer.id, credOffer.protocolVersion);

        if (declineOfferResult.success) {
          print('Credential Refused: ${credOffer.id}');
        }

        return declineOfferResult;
      },
    );
  }

  factory AriesNotification.fromProofOffer(ProofExchangeRecord proofOffer) {
    return AriesNotification(
      id: proofOffer.id,
      title: 'Pedido de Prova Recebido',
      type: NotificationType.proofOffer,
      receivedAt: proofOffer.createdAt ?? DateTime.now(),
      onAccept: ([params]) async {
        final acceptOfferResult = await acceptProofOffer(
          proofOffer.id,
          params['selectedAttributes'],
          params['selectedPredicates'],
        );

        if (acceptOfferResult.success) {
          print('Proof Accepted: ${proofOffer.id}');
        }

        return acceptOfferResult;
      },
      onRefuse: () async {
        final declineOfferResult = await declineProofOffer(proofOffer.id);

        if (declineOfferResult.success) {
          print('Proof Refused: ${proofOffer.id}');
        }

        return declineOfferResult;
      },
    );
  }

  Future<AriesResult> callOnAccept([dynamic params]) async {
    try {
      return await onAccept.call(params);
    } catch (e) {
      return AriesResult(
        success: false,
        error: 'Notification Accept failed: $e',
        value: null,
      );
    } finally {
      removeNotification(id);
    }
  }

  Future<AriesResult> callOnRefuse() async {
    try {
      removeNotification(id);
      return await onRefuse.call();
    } catch (e) {
      return AriesResult(
          success: false, error: 'Notification Refuse failed: $e', value: null);
    }
  }
}
