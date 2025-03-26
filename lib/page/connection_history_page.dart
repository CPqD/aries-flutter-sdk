import 'package:did_agent/agent/enums/credential_state.dart';
import 'package:did_agent/agent/enums/proof_state.dart';
import 'package:did_agent/agent/models/credential/credential_exchange_record.dart';
import 'package:did_agent/agent/models/proof/proof_exchange_record.dart';
import 'package:did_agent/global.dart';
import 'package:did_agent/page/credential_history_page.dart';
import 'package:did_agent/page/credential_notification_page.dart';
import 'package:did_agent/page/proof_history_page.dart';
import 'package:did_agent/page/proof_notification_page.dart';
import 'package:flutter/material.dart';

import '../util/aries_connection_history.dart';

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
                                    onPressed: () async {
                                      Widget? newPage = null;

                                      print('historyItem: $historyItem');

                                      if (historyItem.type ==
                                          ConnectionHistoryType.connectionCredential) {
                                        final credExchangeRecord = historyItem.record
                                            as CredentialExchangeRecord;

                                        if (CredentialState.done
                                            .equals(credExchangeRecord.state)) {
                                          newPage = CredentialHistoryPage(
                                            connectionHistory: historyItem,
                                          );
                                        } else {
                                          final notifications = await getNotifications();

                                          final notification = notifications.firstWhere(
                                            (x) => x.id == historyItem.id,
                                          );

                                          newPage = CredentialNotificationPage(
                                            notification: notification,
                                          );
                                        }
                                      } else if (historyItem.type ==
                                          ConnectionHistoryType.connectionProof) {
                                        final proofExchangeRecord =
                                            historyItem.record as ProofExchangeRecord;

                                        if (ProofState.done
                                            .equals(proofExchangeRecord.state)) {
                                          newPage = ProofHistoryPage(
                                              connectionHistory: historyItem);
                                        } else {
                                          final notifications = await getNotifications();

                                          final notification = notifications.firstWhere(
                                            (x) => x.id == historyItem.id,
                                          );

                                          newPage = ProofNotificationPage(
                                            notification: notification,
                                          );
                                        }
                                      }

                                      if (newPage != null && mounted) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) {
                                              return newPage!;
                                            },
                                          ),
                                        );
                                      }
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
