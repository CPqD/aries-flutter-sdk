enum PredicateType {
  lessThan('<'),
  lessThanOrEqualTo('<='),
  greaterThan('>'),
  greaterThanOrEqualTo('>=');

  final String value;

  const PredicateType(this.value);

  factory PredicateType.from(String symbol) {
    switch (symbol) {
      case '<':
      case 'LT':
      case 'LessThan':
        return PredicateType.lessThan;
      case '<=':
      case '≤':
      case 'LE':
      case 'LessThanOrEqualTo':
        return PredicateType.lessThanOrEqualTo;
      case '>':
      case 'GT':
      case 'GreaterThan':
        return PredicateType.greaterThan;
      case '>=':
      case '≥':
      case 'GE':
      case 'GreaterThanOrEqualTo':
        return PredicateType.greaterThanOrEqualTo;
      default:
        throw ArgumentError('Invalid symbol: $symbol');
    }
  }
}
