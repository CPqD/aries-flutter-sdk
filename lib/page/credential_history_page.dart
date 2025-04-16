import 'package:did_agent/agent/enums/history_type.dart';
import 'package:did_agent/agent/models/history/history_record.dart';
import 'package:did_agent/page/credential_history_details_page.dart';
import 'package:did_agent/page/proof_history_page.dart';
import 'package:did_agent/util/utils.dart';
import 'package:flutter/material.dart';

final credentialHistoryKey = GlobalKey<_CredentialHistoryPageState>();

class CredentialHistoryPage extends StatefulWidget {
  final String credentialId;
  final String title;

  CredentialHistoryPage({
    required this.credentialId,
    this.title = 'Histórico da Credencial',
  }) : super(key: credentialHistoryKey);

  @override
  State<CredentialHistoryPage> createState() => _CredentialHistoryPageState();
}

class _CredentialHistoryPageState extends State<CredentialHistoryPage> {
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<HistoryRecord> _history = [];

  @override
  void initState() {
    super.initState();
    refreshHistory();
  }

  Future<void> refreshHistory() async {
    print('CredentialHistoryPage - refreshHistory - mounted: $mounted');
    if (mounted) {
      final getHistoryResult = await getCredentialHistory(
        widget.credentialId,
      );

      print('CredentialHistoryPage - getHistoryResult: $getHistoryResult');

      if (getHistoryResult.success && getHistoryResult.value != null) {
        setState(() {
          _history = getHistoryResult.value!;
        });
      }
    }
  }

  void _onMessageTap(HistoryRecord historyItem) async {
    Widget? newPage;

    switch (historyItem.historyType) {
      case HistoryType.basicMessageReceived:
      case HistoryType.basicMessageSent:
      case HistoryType.credentialRevoked:
        break;
      case HistoryType.credentialOfferReceived:
      case HistoryType.credentialOfferAccepted:
      case HistoryType.credentialOfferDeclined:
        newPage = CredentialHistoryDetailsPage(historyRecord: historyItem);
        break;

      case HistoryType.proofRequestReceived:
      case HistoryType.proofRequestAccepted:
      case HistoryType.proofRequestDeclined:
        newPage = ProofHistoryPage(connectionHistory: historyItem);
        break;
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
                              historyItem.getTitle(),
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
                            if (HistoryType.isFromCredentialOffer(
                                    historyItem.historyType.value) ||
                                HistoryType.isFromProof(historyItem.historyType.value))
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
