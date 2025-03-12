import 'package:did_agent/global.dart';

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
  final Function onAccept;
  final Function onRefuse;

  AriesNotification({
    required this.id,
    required this.title,
    required this.text,
    required this.type,
    required this.receivedAt,
    required this.onAccept,
    required this.onRefuse,
  });

  Future<void> callOnAccept() async {
    await onAccept.call();
    removeNotification(id);
  }

  Future<void> callOnRefuse() async {
    await onRefuse.call();
    removeNotification(id);
  }
}
