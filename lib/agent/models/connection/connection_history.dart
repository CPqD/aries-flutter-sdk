import '../credential/credential_exchange_record.dart';
import '../proof/proof_exchange_record.dart';

class ConnectionHistory {
  final List<CredentialExchangeRecord> credentialsReceived;
  final List<ProofExchangeRecord> proofsReceived;

  ConnectionHistory({
    required this.credentialsReceived,
    required this.proofsReceived,
  });

  factory ConnectionHistory.from(Map<String, dynamic> map) {
    return ConnectionHistory(
      credentialsReceived:
          CredentialExchangeRecord.fromJson(map["credentialsReceived"].toString()),
      proofsReceived: ProofExchangeRecord.fromJson(map["proofsReceived"].toString()),
    );
  }

  @override
  String toString() {
    return 'ConnectionHistory{'
        'credentialsReceived: $credentialsReceived, '
        'proofsReceived: $proofsReceived'
        '}';
  }
}
