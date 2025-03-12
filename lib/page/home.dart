import 'package:did_agent/agent/enums/credential_state.dart';
import 'package:did_agent/global.dart';
import 'package:did_agent/util/aries_notification.dart';
import 'package:did_agent/util/dialogs.dart';
import 'package:did_agent/util/utils.dart';
import 'package:flutter/material.dart';

import 'notifications_page.dart';
import 'settings_page.dart';

final homePageKey = GlobalKey<HomePageState>();

class HomePage extends StatefulWidget {
  HomePage({required this.title}) : super(key: homePageKey);

  final String title;

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  int _selectedIndex = 1;
  int _notificationCount = 0;

  static final List<Widget> _pages = <Widget>[
    NotificationsPage(),
    SettingsPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void setNotificationCount(int notificationCount) {
    setState(() {
      _notificationCount = notificationCount;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: Text(widget.title),
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                Icon(Icons.notifications),
                if (_notificationCount > 0)
                  Positioned(
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      constraints: BoxConstraints(
                        minWidth: 12,
                        minHeight: 12,
                      ),
                      child: Text(
                        '$_notificationCount',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.secondary,
        onTap: _onItemTapped,
      ),
    );
  }

  void receivedCredential(String credentialId, String credentialState) {
    print('receivedCredential');

    if (CredentialState.offerReceived.equals(credentialState)) {
      final notification = AriesNotification(
        id: credentialId,
        title: 'Oferta de Credential Recebida',
        text: 'Você deseja aceitar a oferta de credencial?',
        type: NotificationType.credentialOffer,
        receivedAt: DateTime.now(),
        onAccept: () async {
          final acceptOfferResult = await acceptCredentialOffer(credentialId);

          if (acceptOfferResult.success) {
            print('Credential Accepted: $credentialId');
          }

          acceptCredentialDialog(acceptOfferResult, context);
        },
        onRefuse: () async {
          final declineOfferResult = await declineCredentialOffer(credentialId);

          if (declineOfferResult.success) {
            print('Credential Refused: $credentialId');
          }

          declineCredentialDialog(declineOfferResult, context);
        },
      );

      addNotification(notification);
    } else {
      print('credentialState: $credentialState');
    }
  }

  void receivedProof(String proofId, String proofState) {
    print('receivedProof');

    if (CredentialState.requestReceived.equals(proofState)) {
      final notification = AriesNotification(
        id: proofId,
        title: 'Oferta de Prova Recebida',
        text: 'Você deseja aceitar a oferta de prova?',
        type: NotificationType.credentialOffer,
        receivedAt: DateTime.now(),
        onAccept: () async {
          final acceptOfferResult = await acceptProofOffer(proofId);

          if (acceptOfferResult.success) {
            print('Proof Accepted: $proofId');
          }

          acceptProofDialog(acceptOfferResult, context);
        },
        onRefuse: () async {
          final declineOfferResult = await declineProofOffer(proofId);

          if (declineOfferResult.success) {
            print('Proof Refused: $proofId');
          }

          declineProofDialog(declineOfferResult, context);
        },
      );

      addNotification(notification);
    } else {
      print('proofState: $proofState');
    }
  }
}
