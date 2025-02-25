import 'package:did_agent/util/utils.dart';
import 'package:flutter/material.dart';
import 'credentials_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  TextEditingController invitationController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () async {
                configureChannelSwift();

                final initResult = await init();
                print(initResult);

                final openResult = await openWallet();
                print(openResult);
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
              child: Text('Credentials'),
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
                    },
                    child: Text('Aceitar\nConvite!'),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final result = await shutdown();
                print(result);
              },
              child: Text('Desligar Agente'),
            ),
          ],
        ),
      ),
    );
  }
}
