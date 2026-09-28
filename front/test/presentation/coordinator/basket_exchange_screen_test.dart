// The coordinator basket_exchange_screen.dart is a re-export of the member
// presentation layer. Full widget tests live in:
//   test/presentation/member/basket_exchange/basket_exchange_screen_test.dart
//
// This file is kept as a smoke test to ensure the re-export compiles and the
// class is reachable from the coordinator import path.
import 'package:amap_en_ligne/presentation/coordinator/basket_exchange_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('BasketExchangeScreen is exported from coordinator path', () {
    // Simply referencing the type confirms the re-export compiles correctly.
    expect(BasketExchangeScreen, isNotNull);
  });
}
