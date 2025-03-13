import 'package:did_agent/agent/models/credential_exchange_record.dart';
import 'package:did_agent/global.dart';
import 'package:did_agent/page/notifications_page.dart';
import 'package:did_agent/util/dialogs.dart';
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
  final Function onAccept;
  final Function onRefuse;

  AriesNotification({
    required this.id,
    required this.title,
    required this.type,
    required this.receivedAt,
    required this.onAccept,
    required this.onRefuse,
  });

  factory AriesNotification.fromCredentialOffer(
      CredentialExchangeRecord credentialOffer) {
    return AriesNotification(
      id: credentialOffer.id,
      title: 'Oferta de Credential Recebida',
      type: NotificationType.credentialOffer,
      receivedAt: DateTime.now(),
      onAccept: () async {
        final acceptOfferResult = await acceptCredentialOffer(credentialOffer.id);

        if (acceptOfferResult.success) {
          print('Credential Accepted: ${credentialOffer.id}');
        }

        if (notificationsKey.currentContext != null) {
          acceptCredentialDialog(acceptOfferResult, notificationsKey.currentContext!);
        }
      },
      onRefuse: () async {
        final declineOfferResult = await declineCredentialOffer(credentialOffer.id);

        if (declineOfferResult.success) {
          print('Credential Refused: ${credentialOffer.id}');
        }

        if (notificationsKey.currentContext != null) {
          declineCredentialDialog(declineOfferResult, notificationsKey.currentContext!);
        }
      },
    );
  }

  factory AriesNotification.fromProofOffer(CredentialExchangeRecord proofOffer) {
    return AriesNotification(
      id: proofOffer.id,
      title: 'Oferta de Prova Recebida',
      type: NotificationType.proofOffer,
      receivedAt: DateTime.now(),
      onAccept: () async {
        final acceptOfferResult = await acceptProofOffer(proofOffer.id);

        if (acceptOfferResult.success) {
          print('Proof Accepted: ${proofOffer.id}');
        }

        if (notificationsKey.currentContext != null) {
          acceptProofDialog(acceptOfferResult, notificationsKey.currentContext!);
        }
      },
      onRefuse: () async {
        final declineOfferResult = await declineProofOffer(proofOffer.id);

        if (declineOfferResult.success) {
          print('Proof Refused: ${proofOffer.id}');
        }

        if (notificationsKey.currentContext != null) {
          declineProofDialog(declineOfferResult, notificationsKey.currentContext!);
        }
      },
    );
  }

  Future<void> callOnAccept() async {
    await onAccept.call();
    removeNotification(id);
  }

  Future<void> callOnRefuse() async {
    await onRefuse.call();
    removeNotification(id);
  }
}
