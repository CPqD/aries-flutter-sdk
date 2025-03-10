enum AriesMethod {
  init('init'),
  openWallet('openwallet'),
  getConnections('getConnections'),
  getCredentials('getCredentials'),
  invitation('receiveInvitation'),
  subscribe('subscribe'),
  shutdown('shutdown'),
  acceptCredentialOffer('acceptCredentialOffer'),
  acceptProofOffer('acceptProofOffer'),
  declineCredentialOffer('declineCredentialOffer'),
  declineProofOffer('declineProofOffer'),
  removeCredential('removeCredential');

  final String value;

  const AriesMethod(this.value);
}
