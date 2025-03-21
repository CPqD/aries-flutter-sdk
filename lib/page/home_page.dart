import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';

import '../agent/enums/credential_state.dart';
import '../global.dart';

import '../util/dialogs.dart';
import '../util/utils.dart';
import 'notifications_page.dart';

import 'settings_page.dart';
import 'widgets/nav_bar.dart';
import 'widgets/nav_model.dart';
import 'widgets/tab_page.dart';

final homePageKey = GlobalKey<HomePageState>();

class HomePage extends StatefulWidget {
  HomePage({required this.title}) : super(key: homePageKey);

  final String title;

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final _notificationNavKey = GlobalKey<NavigatorState>();
  final _settingsNavKey = GlobalKey<NavigatorState>();

  int _selectedTab = 0;
  List<NavModel> _items = [];
  int _notificationCount = 0;

  void setNotificationCount(int notificationCount) {
    setState(() {
      _notificationCount = notificationCount;
    });
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

  void receivedInvitation(String qrCode) async {
    final invitation = await receiveInvitation(qrCode);

    print('receivedInvitation - state: $invitation');

    invitationResultDialog(invitation, context);
  }

  void credentialRevocationReceived(String credentialId) {
    print('credentialRevocationReceived - $credentialId');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Credencial Revogada!'),
          content: Text('A sua credencial de id $credentialId foi revogada!'),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _onItemTapped() async {
    String qrCode = await FlutterBarcodeScanner.scanBarcode(
      '#ff6666',
      'Cancelar',
      false,
      ScanMode.QR,
    );
    receivedInvitation(qrCode);
  }

  @override
  void initState() {
    super.initState();
    _items = [
      NavModel(
        page: TabPage(tab: 1, page: NotificationsPage()),
        navKey: _notificationNavKey,
      ),
      NavModel(
        page: TabPage(tab: 2, page: SettingsPage()),
        navKey: _settingsNavKey,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) => () {
        if (_items[_selectedTab].navKey.currentState?.canPop() ?? false) {
          _items[_selectedTab].navKey.currentState?.pop();
          return Future.value(false);
        } else {
          return Future.value(true);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.title,
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
        body: IndexedStack(
          index: _selectedTab,
          children: _items
              .map((page) => Navigator(
                    key: page.navKey,
                    onGenerateInitialRoutes: (navigator, initialRoute) {
                      return [
                        MaterialPageRoute(builder: (context) => page.page),
                      ];
                    },
                  ))
              .toList(),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: Container(
          margin: const EdgeInsets.only(top: 10),
          height: 64,
          width: 64,
          child: FloatingActionButton(
            backgroundColor: Theme.of(context).colorScheme.tertiary,
            elevation: 0,
            onPressed: () => _onItemTapped(),
            shape: RoundedRectangleBorder(
              side: BorderSide(
                width: 3,
                color: Theme.of(context).colorScheme.secondary,
              ),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  children: [
                    Icon(
                      Icons.qr_code,
                      color: Colors.white,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: NavBar(
          notificationCount: _notificationCount,
          pageIndex: _selectedTab,
          onTap: (index) {
            if (index == _selectedTab) {
              _items[index].navKey.currentState?.popUntil((route) => route.isFirst);
            } else {
              setState(() {
                _selectedTab = index;
              });
            }
          },
        ),
      ),
    );
  }
}
