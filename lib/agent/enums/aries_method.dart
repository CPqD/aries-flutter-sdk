enum AriesMethod {
  init('init'),
  openWallet('openwallet'),
  getConnections('getConnections'),
  getCredentials('getCredentials'),
  getCredentialsOffers('getCredentialsOffers'),
  getDidCommMessage('getDidCommMessage'),
  invitation('receiveInvitation'),
  subscribe('subscribe'),
  shutdown('shutdown'),
  acceptCredentialOffer('acceptCredentialOffer'),
  acceptProofOffer('acceptProofOffer'),
  declineCredentialOffer('declineCredentialOffer'),
  declineProofOffer('declineProofOffer'),
  removeConnection('removeConnection'),
  removeCredential('removeCredential');

  final String value;

  const AriesMethod(this.value);
}
