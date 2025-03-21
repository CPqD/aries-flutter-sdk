enum AriesMethod {
  init('init'),
  acceptCredentialOffer('acceptCredentialOffer'),
  acceptProofOffer('acceptProofOffer'),
  declineCredentialOffer('declineCredentialOffer'),
  declineProofOffer('declineProofOffer'),
  getConnections('getConnections'),
  getCredentials('getCredentials'),
  getCredential('getCredential'),
  getCredentialsOffers('getCredentialsOffers'),
  getDidCommMessage('getDidCommMessage'),
  getProofOffers('getProofOffers'),
  getProofOfferDetails('getProofOfferDetails'),
  invitation('receiveInvitation'),
  openWallet('openwallet'),
  removeConnection('removeConnection'),
  removeCredential('removeCredential'),
  subscribe('subscribe'),
  shutdown('shutdown');

  final String value;

  const AriesMethod(this.value);
}
