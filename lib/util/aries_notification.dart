import 'package:did_agent/agent/aries_result.dart';
import 'package:did_agent/agent/models/credential_exchange_record.dart';
import 'package:did_agent/agent/models/proof_exchange_record.dart';
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
  final String text;
  final NotificationType type;
  final DateTime receivedAt;
  final Future<AriesResult> Function() onAccept;
  final Future<AriesResult> Function() onRefuse;

  AriesNotification({
    required this.id,
    required this.title,
    required this.text,
    required this.type,
    required this.receivedAt,
    required this.onAccept,
    required this.onRefuse,
  });

  factory AriesNotification.fromCredentialOffer(CredentialExchangeRecord credOffer) {
    return AriesNotification(
      id: credOffer.id,
      title: 'Oferta de Credential Recebida',
      text: 'Deseja aceitar essa credencial?',
      type: NotificationType.credentialOffer,
      receivedAt: credOffer.createdAt ?? DateTime.now(),
      onAccept: () async {
        final acceptOfferResult = await acceptCredentialOffer(credOffer.id);

        if (acceptOfferResult.success) {
          print('Credential Accepted: ${credOffer.id}');
        }

        return acceptOfferResult;
      },
      onRefuse: () async {
        final declineOfferResult = await declineCredentialOffer(credOffer.id);

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
      title: 'Oferta de Prova Recebida',
      text: 'Você autoriza a realização dessa prova?',
      type: NotificationType.proofOffer,
      receivedAt: proofOffer.createdAt ?? DateTime.now(),
      onAccept: () async {
        final acceptOfferResult = await acceptProofOffer(proofOffer.id);

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

  Future<AriesResult> callOnAccept() async {
    try {
      return await onAccept.call();
    } catch (e) {
      return AriesResult(
          success: false, error: 'Notification Accept failed: $e', value: null);
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
