import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_fonts/src/google_fonts_base.dart' as google_fonts_base;

void main() {
  testWidgets('Inter and Google Sans load from bundled assets offline', (
    tester,
  ) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    google_fonts_base.clearCache();
    google_fonts_base.assetManifest = null;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              Text('Inter regular', style: GoogleFonts.inter()),
              Text(
                'Inter medium',
                style: GoogleFonts.inter(fontWeight: FontWeight.w500),
              ),
              Text(
                'Inter semibold',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              Text(
                'Google Sans medium',
                style: GoogleFonts.googleSans(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );

    await GoogleFonts.pendingFonts();
    await tester.pumpAndSettle();

    expect(GoogleFonts.config.allowRuntimeFetching, isFalse);
    final bundledAssets = google_fonts_base.assetManifest!.listAssets();
    expect(bundledAssets, contains('assets/fonts/Inter-Regular.ttf'));
    expect(bundledAssets, contains('assets/fonts/Inter-Medium.ttf'));
    expect(bundledAssets, contains('assets/fonts/Inter-SemiBold.ttf'));
    expect(bundledAssets, contains('assets/fonts/GoogleSans-Medium.ttf'));
    expect(tester.takeException(), isNull);
  });
}
