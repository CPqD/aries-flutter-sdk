import 'package:did_agent/util/aries_notification.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
      ),
      body: FutureBuilder<List<AriesNotification>>(
        future: getNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No notifications available.'));
          } else {
            final notifications = snapshot.data!;
            return ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return Card(
                  child: ListTile(
                    title: Text(notification.title),
                    subtitle: Text(notification.title),
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
            );
          }
        },
      ),
    );
  }
}
