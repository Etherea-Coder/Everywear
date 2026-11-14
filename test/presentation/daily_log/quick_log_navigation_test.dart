import 'dart:async';

import 'package:everywear/presentation/daily_log/quick_log_navigation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('refreshes Daily Log after the Quick Log route returns', () async {
    final routeResult = Completer<Object?>();
    var refreshCount = 0;

    final navigation = pushRouteAndRefresh<Object?>(
      pushRoute: () => routeResult.future,
      refresh: () async => refreshCount++,
    );

    expect(refreshCount, 0);
    routeResult.complete(null); // The route was dismissed without a result.

    expect(await navigation, isNull);
    expect(refreshCount, 1);
  });
}
