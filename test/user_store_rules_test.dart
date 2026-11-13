import 'package:flutter_test/flutter_test.dart';
import 'dart:io';

void main() {
  test('las reglas de Firestore cubren users y subscriptions', () {
    final rules = File('firebase/firestore.rules').readAsStringSync();
    expect(rules, contains('match /users/{uid} {'));
    expect(rules, contains('match /subscriptions/{uid} {'));
    expect(rules, contains('owner(uid)'));
  });
}
