import 'dart:async';

import 'package:everywear/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the startup screen before services finish', (
    tester,
  ) async {
    final startup = Completer<void>();

    await tester.pumpWidget(
      ProviderScope(child: MyApp(startupServices: startup.future)),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
  });
}
