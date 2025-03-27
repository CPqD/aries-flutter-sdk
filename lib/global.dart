import 'package:did_agent/agent/models/connection/connection_record.dart';
import 'package:did_agent/page/home_page.dart';
import 'package:did_agent/page/notifications_page.dart';
import 'package:did_agent/util/aries_connection_history.dart';
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

List<AriesConnectionHistory> _connectionHistory = [];
Map<String, List<AriesConnectionHistory>> _chatHistory = {};

Future<void> updateConnectionHistory(ConnectionRecord connection) async {
  try {
    List<AriesConnectionHistory> updatedConnectionHistory = [];

    final connectionHistoryResult = await getConnectionHistory(connection.id);

    print("connectionHistoryResult");
    print(connectionHistoryResult.value.toString());

    if (!connectionHistoryResult.success || connectionHistoryResult.value == null) {
      return;
    }

    for (var credential in connectionHistoryResult.value!.credentials) {
      updatedConnectionHistory
          .add(AriesConnectionHistory.fromConnectionCredential(credential));
    }

    for (var proof in connectionHistoryResult.value!.proofs) {
      updatedConnectionHistory.add(AriesConnectionHistory.fromConnectionProof(proof));
    }

    updatedConnectionHistory.addAll(getChatHistory(connection));

    updatedConnectionHistory.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    _connectionHistory = updatedConnectionHistory;
  } catch (e) {
    print('Failed to update connection history: $e');
  }
}

Future<List<AriesConnectionHistory>> getConnectionHistoryList() async {
  return _connectionHistory;
}

List<AriesConnectionHistory> getChatHistory(ConnectionRecord connection) {
  if (_chatHistory[connection.id] == null) {
    startChatHistoryForConnection(
      connectionId: connection.id,
      connectionDate: connection.createdAt,
      connectionName: connection.theirLabel,
    );
  }

  return _chatHistory[connection.id] ?? [];
}

void addToChatHistory(
    {required String connectionId,
    required String message,
    required bool wasSent,
    required String? theirLabel,
    required DateTime? createdAt}) {
  if (_chatHistory[connectionId] == null) {
    startChatHistoryForConnection(
      connectionId: connectionId,
      connectionDate: createdAt,
      connectionName: theirLabel,
    );
  }

  _chatHistory[connectionId]?.add(AriesConnectionHistory(
    id: 'basic-message-${_chatHistory.length}',
    title: message,
    createdAt: createdAt ?? DateTime.now(),
    type: wasSent
        ? ConnectionHistoryType.messageSent
        : ConnectionHistoryType.messageReceived,
    record: null,
  ));
}

void startChatHistoryForConnection(
    {required String connectionId, String? connectionName, DateTime? connectionDate}) {
  String message = 'Início da conexão';

  if (connectionName != null && connectionName.isNotEmpty) {
    message = 'Você se conectou com $connectionName';
  }

  _chatHistory[connectionId] = [
    AriesConnectionHistory(
      id: 'basic-message-0',
      title: message,
      createdAt: connectionDate ?? DateTime.now(),
      type: ConnectionHistoryType.messageSent,
      record: null,
    )
  ];
}
