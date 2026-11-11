import 'package:flutter_test/flutter_test.dart';
import 'package:everywear/main.dart';

void main() {
  test(
    'the application entry point and transitively imported screens compile',
    () {
      expect(const MyApp(), isA<MyApp>());
    },
  );
}
