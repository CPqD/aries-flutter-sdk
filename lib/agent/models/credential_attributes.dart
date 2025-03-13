class CredentialAttributes {
  final String name;
  final String value;

  CredentialAttributes({
    required this.name,
    required this.value,
  });

  factory CredentialAttributes.fromMap(Map<String, dynamic> map) {
    return CredentialAttributes(
      name: map["name"].toString(),
      value: map["value"].toString(),
    );
  }

  @override
  String toString() {
    return 'CredentialAttributes{'
        'name: $name, '
        'value: $value'
        '}';
  }
}
