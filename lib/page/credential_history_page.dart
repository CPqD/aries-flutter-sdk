import 'package:did_agent/agent/aries_result.dart';
import 'package:did_agent/agent/models/did_comm_message_record.dart';
import 'package:did_agent/util/aries_connection_history.dart';
import 'package:did_agent/util/utils.dart';
import 'package:flutter/material.dart';

class CredentialHistoryPage extends StatelessWidget {
  final AriesConnectionHistory connectionHistory;

  const CredentialHistoryPage({super.key, required this.connectionHistory});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(connectionHistory.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<AriesResult>(
          future: getDidCommMessage(connectionHistory.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Erro: ${snapshot.error}'));
            } else if (!snapshot.hasData || !snapshot.data!.success) {
              return Center(child: Text('Nenhum dado disponível.'));
            } else {
              final DidCommMessageRecord message = snapshot.data!.value;
              final attributes = message.getCredentialPreview().attributes;

              print('message.getProofPreview: ${message.getProofPreview()}');

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
}
