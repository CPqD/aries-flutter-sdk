enum ProofState {
  proposalSent('ProposalSent'),
  proposalReceived('ProposalReceived'),
  declined('Declined'),
  requestSent('RequestSent'),
  requestReceived('RequestReceived'),
  presentationSent('PresentationSent'),
  presentationReceived('PresentationReceived'),
  done('Done');

  final String value;

  const ProofState(this.value);

  bool equals(String otherValue) => value == otherValue;

  static bool isSent(String value) {
    final sentStates = {proposalSent, declined, requestSent, presentationSent, done};

    return sentStates.any((state) => state.value == value);
  }

  static const Map<String, String> portugueseTranslations = {
    'ProposalSent': 'Proposta Enviada',
    'ProposalReceived': 'Proposta Recebida',
    'Declined': 'Recusada',
    'RequestSent': 'Solicitação Enviada',
    'RequestReceived': 'Solicitação Recebida',
    'PresentationSent': 'Apresentação Enviada',
    'PresentationReceived': 'Apresentação Recebida',
    'Done': 'Concluída',
  };
}
