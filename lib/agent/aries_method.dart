enum AriesMethod {
  init('init'),
  openWallet('openwallet'),
  getCredentials('getCredentials'),
  invitation('receiveInvitation'),
  subscribe('subscribe'),
  shutdown('shutdown');

  final String value;

  const AriesMethod(this.value);
}
