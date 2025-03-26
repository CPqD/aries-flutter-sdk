import 'package:did_agent/agent/aries_result.dart';
import 'package:did_agent/agent/models/did_comm_message_record.dart';
import 'package:did_agent/util/aries_notification.dart';
import 'package:did_agent/util/dialogs.dart';
import 'package:did_agent/util/utils.dart';
import 'package:flutter/material.dart';

class CredentialNotificationPage extends StatelessWidget {
  final AriesNotification notification;

  const CredentialNotificationPage({super.key, required this.notification});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(notification.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<AriesResult>(
          future: getDidCommMessage(notification.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Erro: ${snapshot.error}'));
            } else if (!snapshot.hasData || !snapshot.data!.success) {
              return Center(child: Text('Nenhuma mensagem disponível.'));
            } else {
              final DidCommMessageRecord message = snapshot.data!.value;
              final attributes = message.getCredentialPreview()?.attributes ?? [];

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Deseja aceitar essa credencial?',
                      style: TextStyle(fontSize: 18),
                    ),
                    SizedBox(height: 16),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: attributes.length,
                      itemBuilder: (context, index) {
                        final attribute = attributes[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: buildAttributeDetail(attribute.name, attribute.value),
                        );
                      },
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () async {
                            final result = await notification.callOnAccept();

                            if (context.mounted) {
                              Navigator.pop(context);

                              openCredentialResultDialog(result, context, isAccept: true);
                            }
                          },
                          child: Text('Aceitar'),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            final result = await notification.callOnRefuse();

                            if (context.mounted) {
                              Navigator.pop(context);

                              openCredentialResultDialog(result, context,
                                  isAccept: false);
                            }
                          },
                          child: Text('Recusar'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }
          },
        ),
      ),
    );
  }

  Widget buildAttributeDetail(String fieldName, String fieldValue) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$fieldName:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontSize: 16,
              ),
            ),
            TextSpan(
              text: ' $fieldValue',
              style: TextStyle(
                fontWeight: FontWeight.normal,
                color: Colors.black87,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void openCredentialResultDialog(AriesResult result, BuildContext context,
      {required bool isAccept}) {
    if (isAccept) {
      acceptCredentialDialog(result, context);
    } else {
      declineCredentialDialog(result, context);
    }
  }
}
