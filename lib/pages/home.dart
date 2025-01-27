import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../askar/askar_callbacks.dart';
import '../askar/askar_wrapper.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _version = '';

  void getVersion() {
    setState(() {
      _version = askarVersion();
    });
  }

  Future<CallbackResult> storeProvision() async {
    final String specUri = Platform.isIOS
        ? 'sqlite:/${(await getApplicationDocumentsDirectory()).path}/storage.db'
        : 'sqlite://storage.db';
    final String keyMethod = 'kdf:argon2i:mod';
    final String passKey = 'mySecretKey';
    final String profile = 'rekey';
    final int recreate = 1; // 1 para recriar, 0 para manter

    final result = await askarStoreProvision(
        specUri, keyMethod, passKey, profile, recreate);
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () {
                getVersion();
              },
              child: Text('Buscar Versão do Askar'),
            ),
            Text(
              _version,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            ElevatedButton(
              onPressed: () async {
                final callback = await storeProvision();
                print(callback.errorCode);
              },
              child: Text('Chamar storeProvision'),
            ),
          ],
        ),
      ),
      // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
