import 'package:did_agent/agent/models/proof/proof_exchange_record.dart';

import '../agent/models/credential/credential_exchange_record.dart';

enum ConnectionHistoryType {
  connectionCredential('connectionCredential'),
  connectionProof('connectionProof');

  final String value;

  const ConnectionHistoryType(this.value);
}

class AriesConnectionHistory {
  final String id;
  final String title;
  final ConnectionHistoryType type;
  final DateTime createdAt;

  AriesConnectionHistory({
    required this.id,
    required this.title,
    required this.type,
    required this.createdAt,
  });

  factory AriesConnectionHistory.fromConnectionCredential(CredentialExchangeRecord cred) {
    return AriesConnectionHistory(
      id: cred.id,
      title: 'Credencial - ${cred.getStateInPortuguese()}',
      type: ConnectionHistoryType.connectionCredential,
      createdAt: cred.createdAt!,
    );
  }

  factory AriesConnectionHistory.fromConnectionProof(ProofExchangeRecord proof) {
    return AriesConnectionHistory(
      id: proof.id,
      title: 'Prova - ${proof.getStateInPortuguese()}',
      type: ConnectionHistoryType.connectionProof,
      createdAt: proof.createdAt!,
    );
  }
}
