import 'package:did_agent/agent/aries_result.dart';
import 'package:flutter/material.dart';
import 'package:did_agent/util/utils.dart';
import 'package:did_agent/agent/models/credential_record.dart';
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
                title: Text(credential.id),
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
