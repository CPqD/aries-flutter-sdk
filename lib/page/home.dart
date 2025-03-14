import 'package:did_agent/agent/enums/credential_state.dart';
import 'package:did_agent/global.dart';
import 'package:did_agent/util/dialogs.dart';
import 'package:did_agent/util/utils.dart';
import 'package:flutter/material.dart';

import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';

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
  int _selectedIndex = 2;
  int _notificationCount = 0;

  static final List<Widget> _pages = <Widget>[
    NotificationsPage(),
    Container(),
    SettingsPage(),
  ];

  void _onItemTapped(int index) async {
    if (index == 1) {
      String qrCode = await FlutterBarcodeScanner.scanBarcode(
        '#ff6666',
        'Cancel',
        true,
        ScanMode.QR,
      );
      print('QR Code: $qrCode');
      if (qrCode != '-1') {
        final invitation = await receiveInvitation(qrCode);
        print(invitation);

        invitationResultDialog(invitation, context);
      }
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
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
            icon: Icon(Icons.qr_code),
            label: 'Ler QR Code',
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
    print('receivedCredential - state: $credentialState');

    if (CredentialState.offerReceived.equals(credentialState)) {
      updateNotifications();
    }
  }

  void receivedProof(String proofId, String proofState) {
    print('receivedProof  - state: $proofState');

    if (CredentialState.requestReceived.equals(proofState)) {
      updateNotifications();
    }
  }
}
