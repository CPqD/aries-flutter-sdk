class CredentialAttribute {
  final String name;
  final String value;

  CredentialAttribute({
    required this.name,
    required this.value,
  });

  factory CredentialAttribute.fromMap(Map<String, dynamic> map) {
    return CredentialAttribute(
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
