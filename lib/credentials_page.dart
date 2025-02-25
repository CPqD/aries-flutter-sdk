import 'package:flutter/material.dart';

class CredentialsPage extends StatelessWidget {
  const CredentialsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Credentials Page'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Credential 1'),
            Text('Credential 2'),
            Text('Credential 3'),
          ],
        ),
      ),
    );
  }
}
