import 'package:did_agent/agent/models/did_comm_message_record.dart';
import 'package:did_agent/agent/models/proof/details/proof_details.dart';
import 'package:did_agent/agent/models/proof/details/requested_attribute.dart';
import 'package:did_agent/agent/models/proof/details/requested_predicate.dart';
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
  ProofOfferDetails? _proofDetails;

  String? _errorMessage;
  bool _isLoading = true;

  Map<String, RequestedAttribute> _selectedAttributeCredentials = {};
  Map<String, RequestedPredicate> _selectedPredicateCredentials = {};

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

      ProofPreview? proofPreview;

      for (final didCommMessage in didCommMessages) {
        if (didCommMessage.getProofPreview() != null) {
          proofPreview = didCommMessage.getProofPreview()!;
          break;
        }
      }

      print('--> proofPreview: ${proofPreview?.toString()}');

      final proofOfferResult = await getProofOfferDetails(widget.connectionHistory.id);

      print('proofOfferResult: ${proofOfferResult.value.toString()}');

      if (proofOfferResult.success) {
        Map<String, RequestedAttribute> initialAttrCredentials = {};
        Map<String, RequestedPredicate> initialPredCredentials = {};

        final proofOfferDetails = proofOfferResult.value;

        if (proofOfferDetails != null && proofOfferDetails.attributes.isNotEmpty) {
          for (final proofDetailsAttr in proofOfferDetails.attributes) {
            initialAttrCredentials[proofDetailsAttr.name] =
                proofDetailsAttr.availableCredentials.first;
          }
        }

        if (proofOfferDetails != null && proofOfferDetails.predicates.isNotEmpty) {
          for (final proofDetailsPred in proofOfferDetails.predicates) {
            initialPredCredentials[proofDetailsPred.name] =
                proofDetailsPred.availableCredentials.first;
          }
        }

        setState(() {
          _proofDetails = proofOfferResult.value;
          _isLoading = false;
          _selectedAttributeCredentials = initialAttrCredentials;
          _selectedPredicateCredentials = initialPredCredentials;
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

    if (_proofDetails == null) {
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
                          if (attribute.availableCredentials.isNotEmpty)
                            SizedBox(
                              width: double.infinity,
                              child: DropdownButton<dynamic>(
                                value: _selectedAttributeCredentials[attribute.name],
                                hint: Text('Selecione uma credencial'),
                                isExpanded: true,
                                items: attribute.availableCredentials.map((credential) {
                                  return DropdownMenuItem<dynamic>(
                                    value: credential,
                                    child: Text(credential.getListedName()),
                                  );
                                }).toList(),
                                onChanged: attribute.availableCredentials.length > 1
                                    ? (value) {
                                        setState(() {
                                          _selectedAttributeCredentials[attribute.name] =
                                              value;
                                        });
                                      }
                                    : null,
                              ),
                            ),
                          Text(
                            (_selectedAttributeCredentials[attribute.name]
                                    ?.attributes
                                    ?.toString() ??
                                ''),
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 32),
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
                          if (predicate.availableCredentials.isNotEmpty)
                            SizedBox(
                              width: double.infinity,
                              child: DropdownButton<dynamic>(
                                value: _selectedPredicateCredentials[predicate.name],
                                hint: Text('Selecione uma credencial'),
                                isExpanded: true,
                                items: predicate.availableCredentials.map((credential) {
                                  return DropdownMenuItem<dynamic>(
                                    value: credential,
                                    child: Text(credential.getListedName()),
                                  );
                                }).toList(),
                                onChanged: predicate.availableCredentials.length > 1
                                    ? (value) {
                                        setState(() {
                                          _selectedPredicateCredentials[predicate.name] =
                                              value;
                                        });
                                      }
                                    : null,
                              ),
                            ),
                          Text(
                            (_selectedPredicateCredentials[predicate.name]
                                    ?.attributes
                                    ?.toString() ??
                                ''),
                            style: TextStyle(fontWeight: FontWeight.bold),
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
