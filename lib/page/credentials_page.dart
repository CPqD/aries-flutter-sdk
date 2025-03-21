import 'package:did_agent/agent/aries_result.dart';
import 'package:did_agent/agent/models/credential/credential_record.dart';
import 'package:did_agent/util/utils.dart';
import 'package:flutter/material.dart';

import 'credential_details_page.dart';

class CredentialsPage extends StatefulWidget {
  const CredentialsPage({super.key});

  @override
  State<CredentialsPage> createState() => _CredentialsPageState();
}

class _CredentialsPageState extends State<CredentialsPage> {
  Future<AriesResult<List<CredentialRecord>>>? _credentialsFuture;

  @override
  void initState() {
    super.initState();
    _credentialsFuture = getCredentials();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Credenciais'),
      ),
      body: FutureBuilder<AriesResult<List<CredentialRecord>>>(
        future: _credentialsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.success == false) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child:
                  Center(child: Text('Erro: ${snapshot.error ?? snapshot.data?.error}')),
            );
          }

          if (snapshot.data!.value!.isEmpty) {
            return Center(child: Text('Nenhuma credencial encontrada.'));
          }

          final credentials = snapshot.data!.value as List<CredentialRecord>;

          return ListView.builder(
            itemCount: credentials.length,
            itemBuilder: (context, index) {
              final credential = credentials[index];

              return ListTile(
                title: Row(
                  children: [
                    Text(credential.credentialId),
                    if (credential.revocationNotification != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Container(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          child: Text(
                            'REVOGADA',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                subtitle: Text(credential.getSubtitle()),
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CredentialDetailsPage(credential: credential),
                    ),
                  );

                  if (result == true) {
                    setState(() {
                      _credentialsFuture = getCredentials();
                    });
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
