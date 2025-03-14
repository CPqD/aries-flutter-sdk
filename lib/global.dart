import 'package:did_agent/page/home.dart';
import 'package:did_agent/page/notifications_page.dart';
import 'package:did_agent/util/aries_notification.dart';
import 'package:did_agent/util/utils.dart';

List<AriesNotification> _notifications = [];

Future<void> updateNotifications() async {
  try {
    List<AriesNotification> updatedNotifications = [];

    final getCredentialsOffersResult = await getCredentialsOffers();

    if (getCredentialsOffersResult.success && getCredentialsOffersResult.value != null) {
      getCredentialsOffersResult.value?.forEach((credentialOffer) {
        updatedNotifications.add(AriesNotification.fromCredentialOffer(credentialOffer));
      });
    }

    final getProofOffersResult = await getProofOffers();

    if (getProofOffersResult.success && getProofOffersResult.value != null) {
      getProofOffersResult.value?.forEach((proofOffer) {
        updatedNotifications.add(AriesNotification.fromProofOffer(proofOffer));
      });
    }

    updatedNotifications.sort((a, b) => b.receivedAt.compareTo(a.receivedAt));

    _notifications = updatedNotifications;

    _updateNotificationCount();
    _refreshNotificationsPage();
  } catch (e) {
    print('Failed to update notifications: $e');
  }
}

void removeNotification(String id) {
  _notifications.removeWhere((notification) => notification.id == id);
  _updateNotificationCount();
  _refreshNotificationsPage();
}

Future<List<AriesNotification>> getNotifications() async {
  return _notifications;
}

void _updateNotificationCount() =>
    homePageKey.currentState?.setNotificationCount(_notifications.length);

void _refreshNotificationsPage() => notificationsKey.currentState?.reload();
