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

  static List<CredentialAttribute> fromList(List<Map<String, dynamic>> list) {
    return list.map((e) => CredentialAttribute.fromMap(e)).toList();
  }

  @override
  String toString() {
    return 'CredentialAttribute{'
        'name: $name, '
        'value: $value'
        '}';
  }
}
