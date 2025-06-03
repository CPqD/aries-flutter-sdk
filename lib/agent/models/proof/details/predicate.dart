import 'package:did_agent/agent/enums/predicate_type.dart';

class Predicate {
  final String name;
  final PredicateType type;
  final dynamic value;
  final List<Map<String, dynamic>>? restrictions;

  Predicate({
    required this.name,
    required this.type,
    required this.value,
    this.restrictions,
  });

  factory Predicate.fromMap(Map<String, dynamic> map) {
    final restrictions = (map["restrictions"] == null) ? [] : map["restrictions"];

    return Predicate(
      name: map["name"] ?? map["attr_name"].toString(),
      type: PredicateType.from(map["p_type"].toString()),
      value: map["p_value"] ?? map["value"].toString(),
      restrictions: List<Map<String, dynamic>>.from(restrictions),
    );
  }

  String asExpression() {
    return '$name ${type.value} $value';
  }

  Map<String, String> toMap() {
    return {"name": name, "type": type.value, "value": value.toString()};
  }

  @override
  String toString() {
    return 'Predicate{name: $name, type: ${type.value}, value: $value}';
  }
}
