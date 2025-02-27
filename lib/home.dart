import 'package:did_agent/agent/aries_result.dart';
import 'package:did_agent/agent/credential_state.dart';
import 'package:did_agent/util/utils.dart';
import 'package:flutter/material.dart';

import 'credentials_page.dart';

final GlobalKey<HomePageState> homePageKey = GlobalKey<HomePageState>();

class HomePage extends StatefulWidget {
  HomePage({required this.title}) : super(key: homePageKey);

  final String title;

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  TextEditingController invitationController = TextEditingController();
  String? credentialId;
  String? proofId;

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
                configureChannelNative();

                final initResult = await init();
                print(initResult);

                if (!initResult.success) {
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
                final subscribeResult = await subscribe();
                print(subscribeResult);

                subscribeResultDialog(subscribeResult);
              },
              child: Text('Subscribe'),
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

  void initResultDialog(AriesResult result) => showResultDialog(
      result: result,
      successText: "Agente iniciado com sucesso",
      errorText: "Não foi possível iniciar agente");

  void openWalletResultDialog(AriesResult result) => showResultDialog(
      result: result,
      successText: "Carteira aberta com sucesso",
      errorText: "Não foi possível abrir carteira");

  void invitationResultDialog(AriesResult result) => showResultDialog(
      result: result,
      successText: "Convite aceito com sucesso",
      errorText: "Não foi possível aceitar convite");

  void subscribeResultDialog(AriesResult result) => showResultDialog(
      result: result,
      successText: "Ouvindo eventos...",
      errorText: "Não foi possível ouvir eventos");

  void shutdownResultDialog(AriesResult result) => showResultDialog(
      result: result,
      successText: "Agente desligado com sucesso",
      errorText: "Não foi possível desligar agente");

  void acceptOfferResultDialog(AriesResult result) => showResultDialog(
      result: result,
      successText: "Oferta aceita com sucesso",
      errorText: "Não foi possível aceitar oferta");

  void declineOfferResultDialog(AriesResult result) => showResultDialog(
      result: result,
      successText: "Oferta recusada com sucesso",
      errorText: "Não foi possível recusar oferta");

  void showResultDialog({
    required AriesResult result,
    required String successText,
    required String errorText,
  }) {
    String title = result.success ? "Sucesso" : "Erro";
    String content = result.success ? successText : '$errorText (${result.error})';

    if (mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(title),
            content: Text(content),
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

  void receivedCredential(String credentialId, String credentialState) {
    setState(() {
      this.credentialId = credentialId;
    });

    if (CredentialState.offerReceived.equals(credentialState)) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Oferta de Credential Recebida'),
            content: Text('ID da Credencial: $credentialId'),
            actions: <Widget>[
              TextButton(
                child: Text('Accept'),
                onPressed: () async {
                  final acceptOfferResult = await acceptOffer(credentialId);

                  //if (!acceptOfferResult.success) {
                  //} else {}
                  print('Credential Accepted: $credentialId');
                  print('Accept Offer Result: ${acceptOfferResult.result}');
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: Text('Refuse'),
                onPressed: () async {
                  final declineOfferResult = await declineOffer(credentialId);

                  print('Credential Refused: $credentialId');
                  print('Refused Offer Result: ${declineOfferResult.result}');
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    } else {
      print('credentialState: $credentialState');
    }
  }

  void receivedProof(String proofId, String proofState) {
    setState(() {
      this.proofId = proofId;
    });

    if (CredentialState.offerReceived.equals(proofState)) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Proof ID Updated'),
            content: Text('New Proof ID: $proofId'),
            actions: <Widget>[
              TextButton(
                child: Text('Accept'),
                onPressed: () {
                  print('Proof Accepted: $proofId');
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: Text('Refuse'),
                onPressed: () {
                  print('Proof Refused: $proofId');
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    } else {
      print('proofState: $proofState');
    }
  }
}
