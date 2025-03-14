import 'package:did_agent/global.dart';
import 'package:did_agent/page/connections_page.dart';
import 'package:did_agent/util/dialogs.dart';
import 'package:did_agent/util/utils.dart';
import 'package:flutter/material.dart';

import 'credentials_page.dart';

class SettingsPage extends StatelessWidget {
  final TextEditingController invitationController = TextEditingController();

  SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Settings"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () async {
                configureChannelNative();

                final initResult = await init();
                print(initResult);

                if (initResult.success) {
                  final openResult = await openWallet();
                  print(openResult);

                  updateNotifications();

                  openWalletResultDialog(openResult, context);
                } else {
                  initResultDialog(initResult, context);
                }
              },
              child: Text('Open Wallet'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CredentialsPage()),
                );
              },
              child: Text('Credenciais'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ConnectionsPage()),
                );
              },
              child: Text('Conexões'),
            ),
            ElevatedButton(
              onPressed: () async {
                updateNotifications();
              },
              child: Text('update notifications'),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: invitationController,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final invitation =
                          await receiveInvitation(invitationController.text);
                      print(invitation);

                      invitationResultDialog(invitation, context);
                    },
                    child: Text('Aceitar\nConvite!'),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final subscribeResult = await subscribe();
                print(subscribeResult);

                subscribeResultDialog(subscribeResult, context);
              },
              child: Text('Subscribe'),
            ),
            ElevatedButton(
              onPressed: () async {
                final result = await shutdown();
                print(result);

                shutdownResultDialog(result, context);
              },
              child: Text('Desligar Agente'),
            ),
          ],
        ),
      ),
    );
  }
}
