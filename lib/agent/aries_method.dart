enum AriesMethod {
  init('init'),
  openWallet('openwallet'),
  invitation('receiveInvitation'),
  subscribe('subscribe'),
  shutdown('shutdown');

  final String value;

  const AriesMethod(this.value);
}
