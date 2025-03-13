enum DidCommMessageRole {
  sender('Sender'),
  receiver('Receiver');

  final String value;

  const DidCommMessageRole(this.value);

  factory DidCommMessageRole.from(String value) {
    return DidCommMessageRole.values.firstWhere(
      (e) => e.value == value,
      orElse: () => throw ArgumentError('Invalid DidCommMessageRole: $value'),
    );
  }
}
