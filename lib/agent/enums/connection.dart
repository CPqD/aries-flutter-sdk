enum ConnectionRole {
  inviter('Inviter'),
  invitee('Invitee');

  final String value;

  const ConnectionRole(this.value);

  factory ConnectionRole.from(String value) {
    return ConnectionRole.values.firstWhere(
      (e) => e.value == value,
      orElse: () => throw ArgumentError('Invalid ConnectionRole: $value'),
    );
  }
}

enum ConnectionState {
  invited('Invited'),
  requested('Requested'),
  responded('Responded'),
  complete('Complete');

  final String value;

  const ConnectionState(this.value);

  factory ConnectionState.from(String value) {
    return ConnectionState.values.firstWhere(
      (e) => e.value == value,
      orElse: () => throw ArgumentError('Invalid ConnectionState: $value'),
    );
  }
}

enum Connection {
  did('did'),
  didDoc('didDoc');

  final String value;

  const Connection(this.value);
}
