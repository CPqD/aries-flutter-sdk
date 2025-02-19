import 'package:aries_flutter_sdk/aries_flutter_sdk.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Askar Version', () {
    final version = Askar.version();
    expect(version, equals('0.3.2'));
  });
}
