import 'dart:io';

import 'package:did_agent/global.dart';
import 'package:flutter/material.dart';

import 'package:did_agent/util/utils.dart';

import 'home_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() {
      _isLoading = true;
    });

    await configureChannelNative();

    var initResult = await init();
    print(initResult);

    if (initResult.success) {
      var openResult = await openWallet();
      print(openResult);

      if (openResult.success || openResult.error == "Wallet is already open") {
        if (Platform.isAndroid) {
          final subscribeResult = await subscribe();
          print(subscribeResult);
        }

        updateNotifications();

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage(title: 'Aries Flutter Demo')),
        );
      } else {
        _handleError('Falha ao abrir a carteira');
        print(openResult.error);
      }
    } else {
      _handleError('A inicialização do agente falhou');
      print(initResult.error);
    }
  }

  void _handleError(String message) {
    setState(() {
      _isLoading = false;
    });
    _showErrorSnackbar(message);
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _isLoading
            ? CircularProgressIndicator()
            : ElevatedButton(
                onPressed: _initialize,
                child: Text('Abrir carteira novamente'),
              ),
      ),
    );
  }
}
