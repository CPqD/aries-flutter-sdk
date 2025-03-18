import 'package:did_agent/agent/models/credential_record.dart';
import 'package:did_agent/util/utils.dart';
import 'package:flutter/material.dart';

class CredentialDetailsPage extends StatelessWidget {
  final CredentialRecord credential;

  const CredentialDetailsPage({super.key, required this.credential});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalhes da Credencial'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildDetailRow('ID:', credential.id),
                  buildDetailRow('Created At:', credential.createdAt.toString()),
                  buildDetailRow('Revocation ID:', credential.revocationId),
                  buildDetailRow('Link Secret ID:', credential.linkSecretId),
                  buildDetailRow('Schema ID:', credential.schemaId),
                  buildDetailRow('Schema Name:', credential.schemaName),
                  buildDetailRow('Schema Version:', credential.schemaVersion),
                  buildDetailRow('Issuer ID:', credential.issuerId),
                  buildDetailRow('Definition ID:', credential.definitionId),
                  buildDetailRow(
                      'Revocation Registry ID:', credential.revocationRegistryId ?? ''),
                  buildDetailRow(
                      'Credential Values:', credential.getRawValues().toString()),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      print('Share');
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: Text('Compartilhar Dados'),
                  ),
                ),
                SizedBox(width: 16), // Add some space between the buttons
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _confirmDelete(context),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: Text('Deletar'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    bool? confirmDelete = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmar exclusão'),
          content: Text('Tem certeza de que deseja excluir esta credencial?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // Return false
              },
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // Return true
              },
              child: Text('Deletar'),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      final deleteResult = await removeCredential(credential.id);
      print('Delete Result: $deleteResult');

      if (deleteResult.success) {
        Navigator.pop(context, true);
      }
    }
  }

  Widget buildDetailRow(String fieldName, String fieldValue) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: fieldName,
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
