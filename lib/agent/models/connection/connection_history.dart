import 'package:did_agent/agent/models/proof/basic_message_record.dart';

import '../credential/credential_exchange_record.dart';
import '../proof/proof_exchange_record.dart';

class ConnectionHistory {
  final List<CredentialExchangeRecord> credentials;
  final List<ProofExchangeRecord> proofs;
  final List<BasicMessageRecord> basicMessages;

  ConnectionHistory({
    required this.credentials,
    required this.proofs,
    required this.basicMessages,
  });

  factory ConnectionHistory.from(Map<String, dynamic> map) {
    return ConnectionHistory(
      credentials: CredentialExchangeRecord.fromJson(map["credentials"].toString()),
      proofs: ProofExchangeRecord.fromJson(map["proofs"].toString()),
      basicMessages: BasicMessageRecord.fromJson(map["basicMessages"].toString()),
    );
  }

  @override
  String toString() {
    return 'ConnectionHistory{'
        'credentials: $credentials, '
        'proofs: $proofs, '
        'basicMessages: $basicMessages'
        '}';
  }
}
