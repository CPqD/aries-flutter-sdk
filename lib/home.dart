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

                if (initResult == null) {
                  initResultDialog(initResult);
                } else {
                  final openResult = await openWallet();
                  print(openResult);

                  openWalletResultDialog(openResult);
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

                      invitationResultDialog(invitation);
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

                shutdownResultDialog(result);
              },
              child: Text('Desligar Agente'),
            ),
          ],
        ),
      ),
    );
  }

  void initResultDialog(Map<String, dynamic>? result) => showResultDialog(
      isSuccess: result != null,
      successText: "Agente iniciado com sucesso",
      errorText: "Não foi possível iniciar agente");

  void openWalletResultDialog(Map<String, dynamic>? result) => showResultDialog(
      isSuccess: result != null,
      successText: "Carteira aberta com sucesso",
      errorText: "Não foi possível abrir carteira");

  void invitationResultDialog(Map<String, dynamic>? result) => showResultDialog(
      isSuccess: result != null,
      successText: "Convite aceito com sucesso",
      errorText: "Não foi possível aceitar convite");

  void shutdownResultDialog(Map<String, dynamic>? result) => showResultDialog(
      isSuccess: result != null,
      successText: "Agente desligado com sucesso",
      errorText: "Não foi possível desligar agente");

  void showResultDialog({
    required bool isSuccess,
    required String successText,
    required String errorText,
  }) {
    if (mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(isSuccess ? "Sucesso" : "Erro"),
            content: Text(isSuccess ? successText : errorText),
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
  }
}
