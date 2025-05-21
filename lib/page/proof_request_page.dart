import 'package:did_agent/agent/models/proof/proof_attribute.dart';
import 'package:did_agent/agent/models/proof/proof_request.dart';
import 'package:did_agent/util/utils.dart';
import 'package:flutter/material.dart';

const defaultProofName = 'Requisição de Prova';

class ProofRequestPage extends StatefulWidget {
  final String connectionId;

  const ProofRequestPage({super.key, required this.connectionId});

  @override
  ProofRequestPageState createState() => ProofRequestPageState();
}

class ProofRequestPageState extends State<ProofRequestPage> {
  final List<TextEditingController> _attrControllers = [];

  final _proofNameController = TextEditingController(
    text: defaultProofName,
  );

  @override
  void initState() {
    super.initState();
    _addInput();
  }

  void _addInput() {
    setState(() {
      _attrControllers.add(TextEditingController());
    });
  }

  void _removeInput(int index) {
    setState(() {
      _attrControllers.removeAt(index);
    });
  }

  Future<void> _confirmInputs() async {
    List<ProofAttribute> attributes = [];

    for (TextEditingController controller in _attrControllers) {
      final attrName = controller.text.trim();

      if (attrName.isNotEmpty) {
        attributes.add(ProofAttribute(name: attrName));
      }
    }

    String proofName = _proofNameController.text.trim();

    final proofRequest = ProofRequest(
      name: proofName.isEmpty ? defaultProofName : proofName,
      attributes: attributes,
      predicates: [],
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
                          onPressed: () => _removeInput(index),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: _addInput,
                  child: Text('Adicionar Campo'),
                ),
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
