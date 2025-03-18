import 'package:did_agent/global.dart';
import 'package:did_agent/page/credential_notification_page.dart';
import 'package:did_agent/page/proof_notification_page.dart';
import 'package:did_agent/util/aries_notification.dart';
import 'package:flutter/material.dart';

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

  Future<void> _refreshNotifications() async {
    await updateNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notificações'),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshNotifications,
        child: FutureBuilder<List<AriesNotification>>(
          future: getNotifications(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return ListView(
                children: [
                  Center(child: Text('Erro: ${snapshot.error}')),
                ],
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return ListView(
                children: [
                  Center(child: Text('Nenhuma notificação disponível.')),
                ],
              );
            } else {
              final notifications = snapshot.data!;
              return ListView.builder(
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  return Card(
                    child: Stack(
                      children: [
                        ListTile(
                          title: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(notification.title),
                              Text(notification.receivedAt.toLocal().toString()),
                              SizedBox(height: 8),
                              Center(
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) {
                                          if (notification.type ==
                                              NotificationType.proofOffer) {
                                            return ProofNotificationPage(
                                              notification: notification,
                                            );
                                          }

                                          return CredentialNotificationPage(
                                            notification: notification,
                                          );
                                        },
                                      ),
                                    );
                                  },
                                  child: Text('Detalhes'),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          right: 0,
                          child: IconButton(
                            icon: Icon(Icons.close),
                            onPressed: notification.callOnRefuse,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            }
          },
        ),
      ),
    );
  }
}
