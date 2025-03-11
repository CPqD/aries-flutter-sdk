import 'package:did_agent/agent/aries_result.dart';
import 'package:did_agent/agent/enums/credential_state.dart';
import 'package:did_agent/page/connections_page.dart';
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
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ConnectionsPage()),
                );
              },
              child: Text('Conexões'),
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

  void acceptCredentialDialog(AriesResult result) => showResultDialog(
      result: result,
      successText: "Credencial recebida com sucesso",
      errorText: "Não foi possível aceitar credencial");

  void declineCredentialDialog(AriesResult result) => showResultDialog(
      result: result,
      successText: "Credencial recusada com sucesso",
      errorText: "Não foi possível recusar credencial");

  void acceptProofDialog(AriesResult result) => showResultDialog(
      result: result,
      successText: "Prova aceita com sucesso",
      errorText: "Não foi possível aceitar prova");

  void declineProofDialog(AriesResult result) => showResultDialog(
      result: result,
      successText: "Prova recusada com sucesso",
      errorText: "Não foi possível recusar prova");

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
                  Navigator.of(context).pop();

                  final acceptOfferResult = await acceptCredentialOffer(credentialId);

                  if (acceptOfferResult.success) {
                    print('Credential Accepted: $credentialId');
                  }

                  acceptCredentialDialog(acceptOfferResult);
                },
              ),
              TextButton(
                child: Text('Refuse'),
                onPressed: () async {
                  Navigator.of(context).pop();

                  final declineOfferResult = await declineCredentialOffer(credentialId);

                  if (declineOfferResult.success) {
                    print('Credential Refused: $credentialId');
                  }

                  declineCredentialDialog(declineOfferResult);
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

    if (CredentialState.requestReceived.equals(proofState)) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Oferta de Prova Recebida'),
            content: Text('ID da Prova: $proofId'),
            actions: <Widget>[
              TextButton(
                child: Text('Accept'),
                onPressed: () async {
                  Navigator.of(context).pop();

                  final acceptOfferResult = await acceptProofOffer(proofId);

                  if (acceptOfferResult.success) {
                    print('Proof Accepted: $proofId');
                  }

                  acceptProofDialog(acceptOfferResult);
                },
              ),
              TextButton(
                child: Text('Refuse'),
                onPressed: () async {
                  Navigator.of(context).pop();

                  final declineOfferResult = await declineProofOffer(proofId);

                  if (declineOfferResult.success) {
                    print('Proof Refused: $credentialId');
                  }

                  declineProofDialog(declineOfferResult);
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
