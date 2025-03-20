import 'package:did_agent/agent/aries_result.dart';
import 'package:did_agent/agent/models/proof/details/proof_details.dart';
import 'package:did_agent/util/aries_notification.dart';
import 'package:did_agent/util/dialogs.dart';
import 'package:did_agent/util/utils.dart';
import 'package:flutter/material.dart';

class ProofNotificationPage extends StatefulWidget {
  final AriesNotification notification;

  const ProofNotificationPage({super.key, required this.notification});

  @override
  State<ProofNotificationPage> createState() => _ProofNotificationPageState();
}

class _ProofNotificationPageState extends State<ProofNotificationPage> {
  ProofOfferDetails? _proofDetails;
  String? _errorMessage;
  bool _isLoading = true;

  // Map to store selected credentials for each attribute or predicate
  final Map<String, dynamic> _selectedCredentials = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final proofOfferResult = await getProofOfferDetails(widget.notification.id);

      if (proofOfferResult.success) {
        setState(() {
          _proofDetails = proofOfferResult.value;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Não foi possível obter detalhes da prova.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.notification.title),
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.notification.title),
        ),
        body: Center(child: Text(_errorMessage!)),
      );
    }

    if (_proofDetails == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.notification.title),
        ),
        body: Center(child: Text('Nenhum dado disponível.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.notification.title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detalhes da Prova',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            if (_proofDetails!.attributes.isNotEmpty)
              ..._proofDetails!.attributes.map((attribute) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Atributos de "${attribute.name}" solicitados: ${_proofDetails!.getAttributeNamesForSchema(attribute.name).toString()}',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (attribute.error.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Text(
                          attribute.error.toString(),
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    if (attribute.availableCredentials.length == 1)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Text(
                          'Credencial selecionada automaticamente: ${attribute.availableCredentials.first.getListedName()}',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    if (attribute.availableCredentials.length > 1)
                      SizedBox(
                        width: double.infinity,
                        child: DropdownButton<dynamic>(
                          value: _selectedCredentials[attribute.name],
                          hint: Text('Selecione uma credencial'),
                          isExpanded: true,
                          items: attribute.availableCredentials.map((credential) {
                            return DropdownMenuItem<dynamic>(
                              value: credential,
                              child: Text(credential.getListedName()),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedCredentials[attribute.name] = value;
                            });
                          },
                        ),
                      ),
                    SizedBox(height: 16),
                  ],
                );
              }),
            if (_proofDetails!.predicates.isNotEmpty)
              ..._proofDetails!.predicates.map((predicate) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Predicados de "${predicate.name}" solicitados:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (predicate.error.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Text(
                          predicate.error.toString(),
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    if (predicate.availableCredentials.length == 1)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Text(
                          'Credencial selecionada automaticamente: ${predicate.availableCredentials.first.getListedName()}',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    if (predicate.availableCredentials.length > 1)
                      SizedBox(
                        width: double.infinity,
                        child: DropdownButton<dynamic>(
                          value: _selectedCredentials[predicate.name],
                          hint: Text('Selecione uma credencial'),
                          isExpanded: true,
                          items: predicate.availableCredentials.map((credential) {
                            return DropdownMenuItem<dynamic>(
                              value: credential,
                              child: Text(credential.getListedName()),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedCredentials[predicate.name] = value;
                            });
                          },
                        ),
                      ),
                    SizedBox(height: 16),
                  ],
                );
              }),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    final result = await widget.notification.callOnAccept();

                    if (context.mounted) {
                      Navigator.pop(context);

                      openNotificationResultDialog(result, context, isAccept: true);
                    }
                  },
                  child: Text('Aceitar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final result = await widget.notification.callOnRefuse();

                    if (context.mounted) {
                      Navigator.pop(context);

                      openNotificationResultDialog(result, context, isAccept: false);
                    }
                  },
                  child: Text('Recusar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void openNotificationResultDialog(AriesResult result, BuildContext context,
      {required bool isAccept}) {
    if (isAccept) {
      acceptProofDialog(result, context);
    } else {
      declineProofDialog(result, context);
    }
  }
}
