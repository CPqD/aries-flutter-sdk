import 'package:flutter/material.dart';
import 'package:did_agent/global.dart';

final notificationsKey = GlobalKey<NotificationsPageState>();

class NotificationsPage extends StatefulWidget {
  NotificationsPage() : super(key: notificationsKey);

  @override
  State<NotificationsPage> createState() => NotificationsPageState();
}

class NotificationsPageState extends State<NotificationsPage> {
  void reload() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final notifications = getNotifications();

    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
      ),
      body: notifications.isEmpty
          ? Center(
              child: Text('No notifications available.'),
            )
          : ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return Card(
                  child: ListTile(
                    title: Text(notification.title),
                    subtitle: Text(notification.text),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.check),
                          onPressed: notification.callOnAccept,
                        ),
                        IconButton(
                          icon: Icon(Icons.close),
                          onPressed: notification.callOnRefuse,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
