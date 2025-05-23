import 'package:did_agent/agent/models/proof/details/proof_details.dart';
import 'package:did_agent/agent/models/proof/details/requested_attribute.dart';
import 'package:did_agent/agent/models/proof/details/requested_predicate.dart';
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
  bool _canBeApproved = true;
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
      final proofOfferResult = await getProofOfferDetails(widget.notification.id);
      bool canBeApproved = true;

      print('proofOfferResult: ${proofOfferResult.value.toString()}');

      if (proofOfferResult.success) {
        Map<String, RequestedAttribute> initialAttrCredentials = {};
        Map<String, RequestedPredicate> initialPredCredentials = {};

        final proofOfferDetails = proofOfferResult.value;

        if (proofOfferDetails != null && proofOfferDetails.attributes.isNotEmpty) {
          for (final proofDetailsAttr in proofOfferDetails.attributes) {
            if (proofDetailsAttr.error.isNotEmpty ||
                proofDetailsAttr.availableCredentials.isEmpty) {
              canBeApproved = false;
              continue;
            }

            initialAttrCredentials[proofDetailsAttr.name] =
                proofDetailsAttr.availableCredentials.first;
          }
        }

        if (proofOfferDetails != null && proofOfferDetails.predicates.isNotEmpty) {
          for (final proofDetailsPred in proofOfferDetails.predicates) {
            if (proofDetailsPred.error.isNotEmpty ||
                proofDetailsPred.availableCredentials.isEmpty) {
              canBeApproved = false;
              continue;
            }

            initialPredCredentials[proofDetailsPred.name] =
                proofDetailsPred.availableCredentials.first;
          }
        }

        setState(() {
          _proofDetails = proofOfferResult.value;
          _isLoading = false;
          _selectedAttributeCredentials = initialAttrCredentials;
          _selectedPredicateCredentials = initialPredCredentials;
          _canBeApproved = _canBeApproved && canBeApproved;
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

  Widget textH2(String text) => Text(
        text,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      );

  Widget textH3(String text) => Text(
        text,
        style: TextStyle(fontSize: 14),
      );

  Widget resultMessage({
    required bool isSuccess,
    String successText = "",
    String errorText = "",
    String generalText = "",
  }) {
    String text = generalText;

    if (generalText.isEmpty) {
      text = isSuccess ? successText : errorText;
    }

    return Row(children: [
      SizedBox(width: 4),
      Icon(
        isSuccess ? Icons.check : Icons.close,
        color: isSuccess ? Colors.green : Colors.red,
      ),
      SizedBox(width: 4),
      Expanded(
        child: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isSuccess ? Colors.green : Colors.red,
            overflow: TextOverflow.visible,
          ),
        ),
      ),
    ]);
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
            SizedBox(height: 32),
            if (_proofDetails!.attributes.isNotEmpty)
              ..._proofDetails!.attributes.map((attribute) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    textH2(
                      _proofDetails!.getAttributeNamesForSchema(attribute.name).isEmpty
                          ? 'Atributo solicitado: "${attribute.name}"'
                          : 'Atributos de "${attribute.name}" solicitados: ${_proofDetails!.getAttributeNamesForSchema(attribute.name).toString()}',
                    ),
                    if (attribute.error.isNotEmpty)
                      resultMessage(
                        isSuccess: false,
                        errorText: attribute.error.toString(),
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
                              child: textH3(credential.getListedName()),
                            );
                          }).toList(),
                          onChanged: attribute.availableCredentials.length > 1
                              ? (value) {
                                  setState(() {
                                    _selectedAttributeCredentials[attribute.name] = value;
                                  });
                                }
                              : null,
                        ),
                      ),
                    Text(
                      (_proofDetails!.getAttributeNamesForSchema(attribute.name).isEmpty
                          ? _selectedAttributeCredentials[attribute.name]
                                  ?.getAttributesFromNames(_proofDetails!
                                      .getExistingAttributeNames(attribute.name))
                                  .toString() ??
                              ''
                          : _selectedAttributeCredentials[attribute.name]
                                  ?.getAttributesFromNames(_proofDetails!
                                      .getAttributeNamesForSchema(attribute.name))
                                  .toString() ??
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
                    textH2(
                      'Predicado solicitado: "${_proofDetails!.getPredicateForName(predicate.name)?.asExpression()}"',
                    ),
                    if (predicate.error.isNotEmpty)
                      resultMessage(
                        isSuccess: false,
                        errorText: predicate.error.toString(),
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
                              child: textH3(credential.getListedName()),
                            );
                          }).toList(),
                          onChanged: predicate.availableCredentials.length > 1
                              ? (value) {
                                  setState(() {
                                    _selectedPredicateCredentials[predicate.name] = value;
                                  });
                                }
                              : null,
                        ),
                      ),
                    if (predicate.availableCredentials.isNotEmpty)
                      resultMessage(
                        isSuccess: _selectedPredicateCredentials[predicate.name]
                                ?.predicateError
                                .isEmpty ??
                            false,
                        successText: "Requisito atendido",
                        errorText: "Requisito não atendido",
                      ),
                    SizedBox(height: 32),
                  ],
                );
              }),
            if (canBeApproved())
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      final result = await widget.notification.callOnAccept({
                        'selectedAttributes': _selectedAttributeCredentials,
                        'selectedPredicates': _selectedPredicateCredentials,
                      });

                      if (context.mounted) {
                        Navigator.pop(context);

                        acceptProofDialog(result, context);
                      }
                    },
                    child: Text('Aceitar'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final result = await widget.notification.callOnRefuse();

                      if (context.mounted) {
                        Navigator.pop(context);

                        declineProofDialog(result, context);
                      }
                    },
                    child: Text('Recusar'),
                  ),
                ],
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      final result = await widget.notification.callOnRefuse();

                      if (context.mounted) {
                        Navigator.pop(context);

                        declineProofDialog(result, context);
                      }
                    },
                    child: Text('Cancelar'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  bool canBeApproved() {
    return (_canBeApproved &&
        !_selectedPredicateCredentials.values
            .any((predicate) => predicate.predicateError.isNotEmpty));
  }
}
