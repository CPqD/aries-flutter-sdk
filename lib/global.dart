import 'package:did_agent/agent/enums/history_type.dart';
import 'package:did_agent/agent/models/connection/connection_record.dart';
import 'package:did_agent/agent/models/history/history_record.dart';
import 'package:did_agent/page/home_page.dart';
import 'package:did_agent/page/notifications_page.dart';
import 'package:did_agent/util/aries_notification.dart';
import 'package:did_agent/util/utils.dart';

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

List<HistoryRecord> _connectionHistory = [];

Future<void> updateConnectionHistory(ConnectionRecord connection) async {
  try {
    List<HistoryRecord> updatedConnectionHistory = [startConnectionHistory(connection)];

    final connectionHistoryResult = await getConnectionHistory(connection.id);

    print("connectionHistoryResult");
    print(connectionHistoryResult.value.toString());

    if (!connectionHistoryResult.success || connectionHistoryResult.value == null) {
      return;
    }

    updatedConnectionHistory.addAll(connectionHistoryResult.value!);

    updatedConnectionHistory.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    _connectionHistory = updatedConnectionHistory;
  } catch (e) {
    print('Failed to update connection history: $e');
  }
}

Future<List<HistoryRecord>> getConnectionHistoryList() async {
  return _connectionHistory;
}

void addToHistory(HistoryRecord connHistoryRecord) {
  _connectionHistory.add(connHistoryRecord);
}

HistoryRecord startConnectionHistory(ConnectionRecord connection) {
  String message = 'Início da conexão';

  if (connection.theirLabel != null && connection.theirLabel!.isNotEmpty) {
    message = 'Você se conectou com ${connection.theirLabel}';
  }

  return HistoryRecord(
    id: 'basic-message-0',
    createdAt: connection.createdAt ?? DateTime.now(),
    historyType: HistoryType.basicMessageSent,
    associatedRecordId: 'basic-message-0',
    connectionId: connection.id,
    content: message,
  );
}
