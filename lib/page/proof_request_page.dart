import 'package:did_agent/agent/enums/predicate_type.dart';
import 'package:did_agent/agent/models/proof/details/predicate.dart';
import 'package:did_agent/agent/models/proof/proof_attribute.dart';
import 'package:did_agent/agent/models/proof/proof_request.dart';
import 'package:did_agent/util/utils.dart';
import 'package:flutter/material.dart';

const defaultProofName = 'Requisição de Prova';

class PredicateController {
  TextEditingController name;
  String operator;
  TextEditingController value;

  PredicateController(
      {TextEditingController? name, this.operator = '>', TextEditingController? value})
      : name = name ?? TextEditingController(),
        value = value ?? TextEditingController();
}

class ProofRequestPage extends StatefulWidget {
  final String connectionId;

  const ProofRequestPage({super.key, required this.connectionId});

  @override
  ProofRequestPageState createState() => ProofRequestPageState();
}

class ProofRequestPageState extends State<ProofRequestPage> {
  final List<TextEditingController> _attrControllers = [];
  final List<PredicateController> _predControllers = [];

  final _proofNameController = TextEditingController(
    text: defaultProofName,
  );

  @override
  void initState() {
    super.initState();
    _addAttrInput();
    _addPredInput();
  }

  void _addAttrInput() {
    setState(() {
      _attrControllers.add(TextEditingController());
    });
  }

  void _addPredInput() {
    setState(() {
      _predControllers.add(PredicateController());
    });
  }

  void _removeAttrInput(int index) {
    setState(() {
      _attrControllers.removeAt(index);
    });
  }

  void _removePredInput(int index) {
    setState(() {
      _predControllers.removeAt(index);
    });
  }

  Future<void> _confirmInputs() async {
    List<ProofAttribute> attributes = [];
    List<Predicate> predicates = [];

    for (TextEditingController attrController in _attrControllers) {
      final attrName = attrController.text.trim();

      if (attrName.isNotEmpty) {
        attributes.add(ProofAttribute(name: attrName));
      }
    }

    for (PredicateController predController in _predControllers) {
      final predName = predController.name.text.trim();
      final predType = predController.operator.trim();
      final predValue = predController.value.text.trim();

      if (predName.isNotEmpty && predType.isNotEmpty && predValue.isNotEmpty) {
        predicates.add(Predicate(
          name: predName,
          type: PredicateType.from(predType),
          value: predValue,
        ));
      }
    }

    String proofName = _proofNameController.text.trim();

    final proofRequest = ProofRequest(
      name: proofName.isEmpty ? defaultProofName : proofName,
      attributes: attributes,
      predicates: predicates,
    );

    print('proofRequest: $proofRequest');

    final result = await requestProof(
      connectionId: widget.connectionId,
      proofRequest: proofRequest,
    );

    if (result.success) {
      print('Prova enviada com sucesso: $result');
    } else {
      print('Falha ao enviar prova: $result');
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Solicitar Prova'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: TextField(
                    controller: _proofNameController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Atributos solicitados',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _attrControllers.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _attrControllers[index],
                            decoration: InputDecoration(
                              hintText: 'Nome do atributo...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.remove_circle, color: Colors.red),
                          onPressed: () => _removeAttrInput(index),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Align(
              alignment: Alignment.center,
              child: ElevatedButton(
                onPressed: _addAttrInput,
                child: Text('+ Atributo'),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Predicados solicitados',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _predControllers.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: _predControllers[index].name,
                            decoration: InputDecoration(
                              hintText: 'Nome...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        // Middle DropdownButton
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            value: _predControllers[index].operator,
                            items: ['<', '≤', '≥', '>']
                                .map((operator) => DropdownMenuItem(
                                      value: operator,
                                      child: Text(operator),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _predControllers[index].operator = value!;
                              });
                            },
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        // Right TextField
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: _predControllers[index].value,
                            decoration: InputDecoration(
                              hintText: 'Valor...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.remove_circle, color: Colors.red),
                          onPressed: () => _removePredInput(index),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Align(
              alignment: Alignment.center,
              child: ElevatedButton(
                onPressed: _addPredInput,
                child: Text('+ Predicado'),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _confirmInputs,
                  child: Text('Confirmar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
