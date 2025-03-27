enum CredentialState {
  proposalSent('ProposalSent'),
  proposalReceived('ProposalReceived'),
  offerSent('OfferSent'),
  offerReceived('OfferReceived'),
  declined('Declined'),
  requestSent('RequestSent'),
  requestReceived('RequestReceived'),
  credentialIssued('CredentialIssued'),
  credentialReceived('CredentialReceived'),
  done('Done');

  final String value;

  const CredentialState(this.value);

  bool equals(String otherValue) => value == otherValue;

  static bool isSent(String value) {
    final sentStates = {
      proposalSent,
      offerSent,
      declined,
      requestSent,
      credentialIssued,
      done
    };

    return sentStates.any((state) => state.value == value);
  }

  static const Map<String, String> portugueseTranslations = {
    'ProposalSent': 'Proposta Enviada',
    'ProposalReceived': 'Proposta Recebida',
    'OfferSent': 'Oferta Enviada',
    'OfferReceived': 'Oferta Recebida',
    'Declined': 'Recusada',
    'RequestSent': 'Solicitação Enviada',
    'RequestReceived': 'Solicitação Recebida',
    'CredentialIssued': 'Emitida',
    'CredentialReceived': 'Recebida',
    'Done': 'Concluída',
  };
}
