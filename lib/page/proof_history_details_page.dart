import 'package:did_agent/agent/models/did_comm_message_record.dart';
import 'package:did_agent/agent/models/history/history_record.dart';
import 'package:did_agent/agent/models/proof/details/predicate.dart';
import 'package:did_agent/agent/models/proof/proof_preview.dart';
import 'package:did_agent/util/utils.dart';
import 'package:flutter/material.dart';

class ProofHistoryDetailsPage extends StatefulWidget {
  final HistoryRecord historyRecord;

  const ProofHistoryDetailsPage({super.key, required this.historyRecord});

  @override
  State<ProofHistoryDetailsPage> createState() => _ProofHistoryDetailsPageState();
}

class _ProofHistoryDetailsPageState extends State<ProofHistoryDetailsPage> {
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
          await getDidCommMessagesByRecord(widget.historyRecord.associatedRecordId);

      final didCommMessages =
          didCommMessagesResult.value ?? [] as List<DidCommMessageRecord>;

      ProofPreview? proofPreview;

      for (final didCommMessage in didCommMessages) {
        proofPreview = didCommMessage.getProofPreview();

        if (proofPreview != null) {
          setState(() {
            _proofPreview = proofPreview;
          });
          break;
        }
      }

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
          title: Text(widget.historyRecord.getTitle()),
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.historyRecord.getTitle()),
        ),
        body: Center(child: Text(_errorMessage!)),
      );
    }
    if (_proofPreview == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.historyRecord.getTitle()),
        ),
        body: Center(child: Text('Nenhum dado disponível.')),
      );
    }
    if (widget.historyRecord.proofRequestedCredentials == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.historyRecord.getTitle()),
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
    final proofRequestedCredentials = widget.historyRecord.proofRequestedCredentials!;
    final requestedAttributes = proofRequestedCredentials.requestedAttributes;
    final requestedPredicates = proofRequestedCredentials.requestedPredicates;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.historyRecord.getTitle()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Atributos Compartilhados:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...requestedAttributes.entries.map((entry) {
              final attribute = entry.value;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.key,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ...attribute.credentialInfo.attributes.entries.map((attrEntry) {
                    return Text(
                      '${attrEntry.key}: ${attrEntry.value}',
                      style: TextStyle(fontSize: 14),
                    );
                  }),
                  const SizedBox(height: 16),
                ],
              );
            }),
            const SizedBox(height: 32),
            Text(
              'Predicados Compartilhados:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...requestedPredicates.entries.map((entry) {
              final predicate = entry.value;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.key,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ...predicate.credentialInfo.attributes.entries.map((attrEntry) {
                    return Text(
                      '${attrEntry.key}: ${attrEntry.value}',
                      style: TextStyle(fontSize: 14),
                    );
                  }),
                  const SizedBox(height: 16),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}
