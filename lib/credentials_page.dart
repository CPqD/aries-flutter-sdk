import 'package:did_agent/agent/aries_result.dart';
import 'package:flutter/material.dart';
import 'package:did_agent/util/utils.dart';
import 'package:did_agent/agent/credential_record.dart';

class CredentialsPage extends StatelessWidget {
  const CredentialsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Credentials Page'),
      ),
      body: FutureBuilder<AriesResult<List<CredentialRecord>>>(
        future: getCredentials(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.success == false) {
            return Center(child: Text('Error: ${snapshot.error ?? snapshot.data?.error}'));
          }

          if (snapshot.data!.value!.isEmpty) {
            return Center(child: Text('No credentials found.'));
          }

          final credentials = snapshot.data!.value as List<CredentialRecord>;

          return ListView.builder(
            itemCount: credentials.length,
            itemBuilder: (context, index) {
              final credential = credentials[index];
              return ListTile(
                title: Text('Credential ID: "${credential.id}"'),
                subtitle: Text('Schema Name: "${credential.schemaName}"'),
              );
            },
          );
        },
      ),
    );
  }
}
