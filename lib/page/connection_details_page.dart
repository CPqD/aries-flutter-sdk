import 'package:did_agent/agent/models/connection_record.dart';
import 'package:did_agent/util/utils.dart';
import 'package:flutter/material.dart';

class ConnectionDetailsPage extends StatelessWidget {
  final ConnectionRecord connection;

  const ConnectionDetailsPage({super.key, required this.connection});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Connection Details'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  connection.getName(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontSize: 18,
                  ),
                ),
                buildDetailRow('ID:', connection.id),
                buildDetailRow('Created At:', connection.createdAt.toString()),
                buildDetailRow('Updated At:', connection.updatedAt.toString()),
                buildDetailRow('State:', connection.state.value),
                buildDetailRow('Role:', connection.role.value),
                buildDetailRow('DID:', connection.did),
                buildDetailRow('Their DID:', connection.theirDid.toString()),
                buildDetailRow('VerKey:', connection.verkey),
                buildDetailRow('Auto Accept Connection:',
                    connection.autoAcceptConnection.toString()),
                buildDetailRow(
                    'Multi Use Invitation:', connection.multiUseInvitation.toString()),
                buildDetailRow('Mediator ID:', connection.mediatorId.toString()),
              ]),
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
                      print('History');
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: Text('History'),
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
                    child: Text('Delete'),
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
          title: Text('Confirm Delete'),
          content: Text('Are you sure you want to delete this connection?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // Return false
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // Return true
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      final deleteResult = await removeConnection(connection.id);
      print('Delete Result: ${deleteResult}');

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
              text: '$fieldName',
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
