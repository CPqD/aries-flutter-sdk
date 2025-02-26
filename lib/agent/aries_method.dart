enum AriesMethod {
  init('init'),
  openWallet('openwallet'),
  invitation('receiveInvitation'),
  shutdown('shutdown');

  final String value;

  const AriesMethod(this.value);
}
