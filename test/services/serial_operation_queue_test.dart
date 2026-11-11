import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:everywear/services/serial_operation_queue.dart';

void main() {
  group('SerialOperationQueue', () {
    test('does not overlap identity-sensitive operations', () async {
      final queue = SerialOperationQueue();
      final order = <int>[];
      final started = Completer<void>();
      final releaseFirst = Completer<void>();

      final first = queue.run(() async {
        order.add(1);
        started.complete();
        await releaseFirst.future;
        order.add(2);
      });
      final second = queue.run(() async {
        order.add(3);
      });

      await started.future;
      expect(order, [1]);
      releaseFirst.complete();
      await Future.wait([first, second]);
      expect(order, [1, 2, 3]);
    });

    test('a failed operation releases the following operation', () async {
      final queue = SerialOperationQueue();
      final failed = queue.run<void>(() async {
        throw StateError('expected test failure');
      });

      await expectLater(failed, throwsStateError);
      expect(await queue.run(() async => 'next'), 'next');
    });
  });
}
