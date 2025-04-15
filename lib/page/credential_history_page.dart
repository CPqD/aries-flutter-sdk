import 'package:did_agent/agent/aries_result.dart';
import 'package:did_agent/agent/models/credential/credential_preview.dart';
import 'package:did_agent/agent/models/did_comm_message_record.dart';
import 'package:did_agent/agent/models/history/history_record.dart';
import 'package:did_agent/util/utils.dart';
import 'package:flutter/material.dart';

class CredentialHistoryPage extends StatelessWidget {
  final HistoryRecord historyRecord;

  const CredentialHistoryPage({super.key, required this.historyRecord});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(historyRecord.getTitle()),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<AriesResult>(
          future: getDidCommMessagesByRecord(historyRecord.associatedRecordId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Erro: ${snapshot.error}'));
            } else if (!snapshot.hasData || !snapshot.data!.success) {
              return Center(child: Text('Nenhum dado disponível.'));
            } else {
              final List<DidCommMessageRecord> messages = snapshot.data!.value;

              CredentialPreview? credentialPreview;

              for (final currentMessage in messages) {
                if (currentMessage.getCredentialPreview() != null) {
                  credentialPreview = currentMessage.getCredentialPreview();
                  break;
                }
              }

              final attributes = credentialPreview?.attributes ?? [];

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
