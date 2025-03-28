import 'package:did_agent/agent/enums/credential_state.dart';
import 'package:did_agent/agent/enums/proof_state.dart';
import 'package:did_agent/agent/models/connection/connection_record.dart';
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
  final ConnectionRecord? connection;
  final String title;

  ConnectionHistoryPage({
    this.connection,
    this.title = 'Histórico',
  }) : super(key: connectionHistoryKey);

  @override
  State<ConnectionHistoryPage> createState() => _ConnectionHistoryPageState();
}

class _ConnectionHistoryPageState extends State<ConnectionHistoryPage> {
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<AriesConnectionHistory> _history = [];

  @override
  void initState() {
    super.initState();
    refreshHistory();
  }

  Future<void> refreshHistory() async {
    if (widget.connection != null && mounted) {
      await updateConnectionHistory(widget.connection!);
    }

    reloadHistory();
  }

  Future<void> reloadHistory() async {
    if (mounted) {
      final history = await getConnectionHistoryList();
      setState(() {
        _history = history;
      });
    }
  }

  void _onMessageTap(AriesConnectionHistory historyItem) async {
    Widget? newPage;

    if (historyItem.type == ConnectionHistoryType.connectionCredential) {
      final credExchangeRecord = historyItem.record as CredentialExchangeRecord?;

      if (credExchangeRecord != null &&
          (CredentialState.done.equals(credExchangeRecord.state) ||
              CredentialState.declined.equals(credExchangeRecord.state))) {
        newPage = CredentialHistoryPage(connectionHistory: historyItem);
      } else {
        final notifications = await getNotifications();
        final notification = notifications.firstWhere((x) => x.id == historyItem.id);

        newPage = CredentialNotificationPage(notification: notification);
      }
    } else if (historyItem.type == ConnectionHistoryType.connectionProof) {
      final proofExchangeRecord = historyItem.record as ProofExchangeRecord?;

      if (proofExchangeRecord != null &&
          (ProofState.done.equals(proofExchangeRecord.state) ||
              ProofState.declined.equals(proofExchangeRecord.state))) {
        newPage = ProofHistoryPage(connectionHistory: historyItem);
      } else {
        final notifications = await getNotifications();
        final notification = notifications.firstWhere((x) => x.id == historyItem.id);

        newPage = ProofNotificationPage(notification: notification);
      }
    }

    if (newPage != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => newPage!),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _history.length,
              reverse: true,
              itemBuilder: (context, index) {
                final historyItem = _history[index];
                return GestureDetector(
                  onTap: () => _onMessageTap(historyItem),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                    child: Align(
                      alignment: historyItem.wasSent()
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color:
                              historyItem.wasSent() ? Colors.blue[200] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              historyItem.title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            Text(
                              historyItem.createdAt.toLocal().toString(),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                            if (historyItem.type ==
                                    ConnectionHistoryType.connectionCredential ||
                                historyItem.type == ConnectionHistoryType.connectionProof)
                              SizedBox(
                                width: 200,
                                child: ElevatedButton(
                                  onPressed: () => _onMessageTap(historyItem),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    minimumSize: const Size(80, 36),
                                  ),
                                  child: const Text('Detalhes'),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Divider(height: 1),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
