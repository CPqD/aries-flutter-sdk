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
}
