enum AriesMethod {
  init('init'),
  openWallet('openwallet'),
  invitation('receiveInvitation'),
  subscribe('subscribe'),
  shutdown('shutdown'),
  acceptOffer('acceptOffer'),
  declineOffer('declineOffer');

  final String value;

  const AriesMethod(this.value);
}
