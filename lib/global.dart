import 'package:did_agent/page/home.dart';
import 'package:did_agent/page/notifications_page.dart';
import 'package:did_agent/util/aries_notification.dart';

List<AriesNotification> _notifications = [];

void addNotification(AriesNotification notification) {
  _notifications.add(notification);
  _updateNotificationsState();
}

void removeNotification(String id) {
  _notifications.removeWhere((notification) => notification.id == id);
  _updateNotificationsState();
}

List<AriesNotification> getNotifications() {
  return _notifications;
}

void _updateNotificationsState() {
  homePageKey.currentState?.setNotificationCount(_notifications.length);
  notificationsKey.currentState?.reload();
}
