enum AriesMethod {
  init('init'),
  openWallet('openwallet'),
  getCredentials('getCredentials'),
  invitation('receiveInvitation'),
  subscribe('subscribe'),
  shutdown('shutdown'),
  acceptOffer('acceptOffer'),
  declineOffer('declineOffer'),
  removeCredential('removeCredential');

  final String value;

  const AriesMethod(this.value);
}
