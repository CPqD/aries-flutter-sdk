import 'package:did_agent/global.dart';

import 'package:flutter/material.dart';

import '../util/aries_connection_history.dart';

import 'credential_history_page.dart';
import 'proof_history_page.dart';

final connectionHistoryKey = GlobalKey<_ConnectionHistoryPageState>();

class ConnectionHistoryPage extends StatefulWidget {
  final String? connectionId;
  final String title;

  const ConnectionHistoryPage({super.key, this.connectionId, this.title = 'Histórico'});

  @override
  State<ConnectionHistoryPage> createState() => _ConnectionHistoryPageState();
}

class _ConnectionHistoryPageState extends State<ConnectionHistoryPage> {
  void reload() {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _refreshHistory();
  }

  Future<void> _refreshHistory() async {
    if (widget.connectionId != null || widget.connectionId!.isNotEmpty) {
      await updateConnectionHistory(widget.connectionId!);
      reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Histórico'),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshHistory,
        child: FutureBuilder<List<AriesConnectionHistory>>(
          future: getConnectionHistoryList(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Erro: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Text('Nenhum histórico de conexão disponível.'));
            } else {
              final history = snapshot.data!;
              return Padding(
                padding: const EdgeInsets.only(bottom: 30.0),
                child: ListView.builder(
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final historyItem = history[index];
                    return Card(
                      child: Stack(
                        children: [
                          ListTile(
                            title: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(historyItem.title),
                                Text(historyItem.createdAt.toLocal().toString()),
                                SizedBox(height: 8),
                                Center(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) {
                                            if (historyItem.type ==
                                                ConnectionHistoryType.connectionProof) {
                                              return ProofHistoryPage(
                                                connectionHistory: historyItem,
                                              );
                                            }

                                            return CredentialHistoryPage(
                                              connectionHistory: historyItem,
                                            );
                                          },
                                        ),
                                      );
                                    },
                                    child: Text('Detalhes'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
