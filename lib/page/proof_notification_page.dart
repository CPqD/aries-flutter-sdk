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

    final preview = _proofDetails!.didCommMessageRecord.getProofPreview();

    final subtitle = preview.requestedAttributes.length == 1
        ? 'Você autoriza o compartilhamento de 1 credencial?'
        : 'Você autoriza o compartilhamento de ${preview.requestedAttributes.length} credenciais?';

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
              subtitle,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: preview.requestedAttributes.length,
              itemBuilder: (context, index) {
                final schemaAttribute = preview.requestedAttributes[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Campos de \"${schemaAttribute.schemaName}\" a serem compartilhados:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: schemaAttribute.attributeNames.length,
                      itemBuilder: (context, attrIndex) {
                        final attributeName = schemaAttribute.attributeNames[attrIndex];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Text(attributeName),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
            SizedBox(height: 16),
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
