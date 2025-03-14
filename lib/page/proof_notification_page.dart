import 'package:did_agent/agent/aries_result.dart';
import 'package:did_agent/agent/models/did_comm_message_record.dart';
import 'package:did_agent/util/aries_notification.dart';
import 'package:did_agent/util/dialogs.dart';
import 'package:did_agent/util/utils.dart';
import 'package:flutter/material.dart';

class ProofNotificationPage extends StatelessWidget {
  final AriesNotification notification;

  const ProofNotificationPage({super.key, required this.notification});

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
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || !snapshot.data!.success) {
              return Center(child: Text('No message available.'));
            } else {
              final DidCommMessageRecord message = snapshot.data!.value;

              final preview = message.getProofPreview();

              final subtitle = preview.requestedAttributes.length == 1
                  ? 'Você autoriza o compartilhamento de 1 credencial?'
                  : 'Você autoriza o compartilhamento de ${preview.requestedAttributes.length} credenciais?';

              print('message.getProofPreview: ${message.getProofPreview()}');

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 16),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: preview.requestedAttributes.length,
                      itemBuilder: (context, index) {
                        final schemaAttribute = preview.requestedAttributes[index];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Campos de \"${preview.requestedAttributes[index].schemaName}\" a serem compartilhados:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemCount: schemaAttribute.attributeNames.length,
                              itemBuilder: (context, attrIndex) {
                                final attributeName =
                                    schemaAttribute.attributeNames[attrIndex];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                                  child: Text(attributeName),
                                );
                              },
                            ),
                          ],
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

                              openNotificationResultDialog(result, context,
                                  isAccept: true);
                            }
                          },
                          child: Text('Aceitar'),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            final result = await notification.callOnRefuse();

                            if (context.mounted) {
                              Navigator.pop(context);

                              openNotificationResultDialog(result, context,
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

  void openNotificationResultDialog(AriesResult result, BuildContext context,
      {required bool isAccept}) {
    if (isAccept) {
      acceptProofDialog(result, context);
    } else {
      declineProofDialog(result, context);
    }
  }
}
