import 'package:did_agent/page/home_page.dart';
import 'package:did_agent/page/notifications_page.dart';
import 'package:did_agent/util/aries_connection_history.dart';
import 'package:did_agent/util/aries_notification.dart';
import 'package:did_agent/util/utils.dart';

import 'page/connection_history_page.dart';

// Notification
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

// ConnectionHistory

List<AriesConnectionHistory> _connectionHistory = [];

Future<void> updateConnectionHistory(String connectionId) async {
  try {
    List<AriesConnectionHistory> updatedConnectionHistory = [];

    final connectionHistoryResult = await getConnectionHistory(connectionId);

    print("connectionHistoryResult");
    print(connectionHistoryResult.value.toString());
    if (connectionHistoryResult.success && connectionHistoryResult.value != null) {
      if (connectionHistoryResult.value!.credentialsReceived.isNotEmpty) {
        for (var credential in connectionHistoryResult.value!.credentialsReceived) {
          updatedConnectionHistory
              .add(AriesConnectionHistory.fromConnectionCredential(credential));
        }
        for (var proof in connectionHistoryResult.value!.proofsReceived) {
          updatedConnectionHistory.add(AriesConnectionHistory.fromConnectionProof(proof));
        }
      }
    }

    updatedConnectionHistory.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    _connectionHistory = updatedConnectionHistory;

    _refreshConnectionHistoryPage();
  } catch (e) {
    print('Failed to update connection history: $e');
  }
}

Future<List<AriesConnectionHistory>> getConnectionHistoryList() async {
  return _connectionHistory;
}

void _refreshConnectionHistoryPage() => connectionHistoryKey.currentState?.reload();
