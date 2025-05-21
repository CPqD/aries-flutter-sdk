class Predicate {
  final String name;
  final String type;
  final dynamic value;
  final List<Map<String, dynamic>>? restrictions;

  Predicate({
    required this.name,
    required this.type,
    required this.value,
    this.restrictions,
  });

  factory Predicate.fromMap(Map<String, dynamic> map) {
    final restrictions = (map["restrictions"] == null) ? null : map["restrictions"];

    return Predicate(
      name: map["name"].toString(),
      type: map["p_type"].toString(),
      value: map["p_value"].toString(),
      restrictions: List<Map<String, dynamic>>.from(restrictions),
    );
  }

  String asExpression() {
    return '$name $type $value';
  }

  Map<String, String> toMap() {
    return {"name": name, "type": type, "value": value.toString()};
  }

  @override
  String toString() {
    return 'Predicate{name: $name, type: $type, value: $value}';
  }
}
