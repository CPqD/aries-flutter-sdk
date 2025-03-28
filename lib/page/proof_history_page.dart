import 'package:did_agent/agent/models/did_comm_message_record.dart';
import 'package:did_agent/agent/models/proof/details/predicate.dart';
import 'package:did_agent/agent/models/proof/proof_preview.dart';
import 'package:did_agent/util/aries_connection_history.dart';
import 'package:did_agent/util/utils.dart';
import 'package:flutter/material.dart';

class ProofHistoryPage extends StatefulWidget {
  final AriesConnectionHistory connectionHistory;

  const ProofHistoryPage({super.key, required this.connectionHistory});

  @override
  State<ProofHistoryPage> createState() => _ProofHistoryPageState();
}

class _ProofHistoryPageState extends State<ProofHistoryPage> {
  ProofPreview? _proofPreview;
  String? _errorMessage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final didCommMessagesResult =
          await getDidCommMessagesByRecord(widget.connectionHistory.id);
      final didCommMessages =
          didCommMessagesResult.value ?? [] as List<DidCommMessageRecord>;

      for (final didCommMessage in didCommMessages) {
        if (didCommMessage.getProofPreview() != null) {
          _proofPreview = didCommMessage.getProofPreview()!;
          break;
        }
      }
      print('--> proofPreview: ${_proofPreview?.toString()}');

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro: $e';
        _isLoading = false;
      });
    }
  }

  Widget textH2(String text) => Text(
        text,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      );

  Widget textH3(String text) => Text(
        text,
        style: TextStyle(fontSize: 14),
      );

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.connectionHistory.title),
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.connectionHistory.title),
        ),
        body: Center(child: Text(_errorMessage!)),
      );
    }
    if (_proofPreview == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.connectionHistory.title),
        ),
        body: Center(child: Text('Nenhum dado disponível.')),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.connectionHistory.title),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Detalhes da Prova',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 32),
                  if (_proofPreview!.requestedAttributes.isNotEmpty)
                    ..._proofPreview!.requestedAttributes.map((attribute) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          textH2(
                            'Atributos de "${attribute.schemaName}" solicitados:',
                          ),
                          ...attribute.attributeNames.map((attrName) {
                            return textH3(
                              attrName,
                            );
                          }),
                          SizedBox(height: 32),
                        ],
                      );
                    }),
                  if (_proofPreview!.requestedPredicates.isNotEmpty)
                    ..._proofPreview!.requestedPredicates.entries.map((entry) {
                      final p = Predicate.fromMap(entry.value);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          textH2(
                            'Predicado solicitado:',
                          ),
                          textH3(
                            p.asExpression(),
                          ),
                          SizedBox(height: 32),
                        ],
                      );
                    }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
