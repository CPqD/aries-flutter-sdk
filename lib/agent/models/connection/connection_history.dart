import '../credential/credential_exchange_record.dart';
import '../proof/proof_exchange_record.dart';

class ConnectionHistory {
  final List<CredentialExchangeRecord> credentials;
  final List<ProofExchangeRecord> proofs;

  ConnectionHistory({
    required this.credentials,
    required this.proofs,
  });

  factory ConnectionHistory.from(Map<String, dynamic> map) {
    return ConnectionHistory(
      credentials: CredentialExchangeRecord.fromJson(map["credentials"].toString()),
      proofs: ProofExchangeRecord.fromJson(map["proofs"].toString()),
    );
  }

  @override
  String toString() {
    return 'ConnectionHistory{'
        'credentials: $credentials, '
        'proofs: $proofs'
        '}';
  }
}
