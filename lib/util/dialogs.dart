import 'package:did_agent/agent/aries_result.dart';
import 'package:flutter/material.dart';

void initResultDialog(AriesResult result, BuildContext context) => showResultDialog(
      result: result,
      successText: "Agente iniciado com sucesso",
      errorText: "Não foi possível iniciar agente",
      context: context,
    );

void openWalletResultDialog(AriesResult result, BuildContext context) => showResultDialog(
      result: result,
      successText: "Carteira aberta com sucesso",
      errorText: "Não foi possível abrir carteira",
      context: context,
    );

void invitationResultDialog(AriesResult result, BuildContext context) => showResultDialog(
      result: result,
      successText: "Convite aceito com sucesso",
      errorText: "Não foi possível aceitar convite",
      context: context,
    );

void subscribeResultDialog(AriesResult result, BuildContext context) => showResultDialog(
      result: result,
      successText: "Ouvindo eventos...",
      errorText: "Não foi possível ouvir eventos",
      context: context,
    );

void shutdownResultDialog(AriesResult result, BuildContext context) => showResultDialog(
      result: result,
      successText: "Agente desligado com sucesso",
      errorText: "Não foi possível desligar agente",
      context: context,
    );

void acceptCredentialDialog(AriesResult result, BuildContext context) => showResultDialog(
      result: result,
      successText: "Credencial recebida com sucesso",
      errorText: "Não foi possível aceitar credencial",
      context: context,
    );

void declineCredentialDialog(AriesResult result, BuildContext context) =>
    showResultDialog(
      result: result,
      successText: "Credencial recusada com sucesso",
      errorText: "Não foi possível recusar credencial",
      context: context,
    );

void acceptProofDialog(AriesResult result, BuildContext context) => showResultDialog(
      result: result,
      successText: "Prova aceita com sucesso",
      errorText: "Não foi possível aceitar prova",
      context: context,
    );

void declineProofDialog(AriesResult result, BuildContext context) => showResultDialog(
      result: result,
      successText: "Prova recusada com sucesso",
      errorText: "Não foi possível recusar prova",
      context: context,
    );

void showResultDialog({
  required AriesResult result,
  required String successText,
  required String errorText,
  required BuildContext context,
}) {
  String title = result.success ? "Sucesso" : "Erro";
  String content = result.success ? successText : '$errorText (${result.error})';

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
