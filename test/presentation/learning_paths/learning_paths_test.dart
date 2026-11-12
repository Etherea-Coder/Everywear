import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sizer/sizer.dart';

import 'package:everywear/core/utils/app_localizations.dart';
import 'package:everywear/presentation/learning_paths/learning_paths.dart';
import 'package:everywear/services/learning_service.dart';

class _FakeLearningService extends LearningService {
  _FakeLearningService({this.failLoad = false, this.progressSaveResult = true});

  final bool failLoad;
  final bool progressSaveResult;
  int progressWriteCount = 0;
  double? lastSavedProgress;
  bool completed = false;

  @override
  Future<List<Map<String, dynamic>>> fetchModulesWithProgress() async {
    if (failLoad) throw Exception('offline');
    return [
      {
        'id': 'module-1',
        'title': 'Color basics',
        'description': 'Learn how colors work together.',
        'difficulty': 'Beginner',
        'estimated_time': '10 min',
        'order_index': 1,
        'unlock_required_outfits': 0,
        'unlock_requirement_label': '',
        'key_learnings': ['Use complementary colors.'],
        'image_url': '',
        'semantic_label': '',
        'progress': completed ? 1.0 : 0.0,
        'is_completed': completed,
      },
    ];
  }

  @override
  Future<Map<String, dynamic>> getUserLearningStats() async => {
    'outfits_logged': 0,
    'wardrobe_items': 0,
    'completed_modules': completed ? 1 : 0,
    'level': 1,
  };

  @override
  Future<bool> updateModuleProgress(String moduleId, double progress) async {
    progressWriteCount++;
    lastSavedProgress = progress;
    if (progressSaveResult && progress >= 1.0) completed = true;
    return progressSaveResult;
  }
}

Widget _testApp(LearningService service) {
  return Sizer(
    builder: (context, orientation, screenType) => MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: LearningPaths(learningService: service),
    ),
  );
}

void main() {
  testWidgets('shows a retry state when learning data cannot load', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp(_FakeLearningService(failLoad: true)));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Could not load your learning progress. Check your connection and try again.',
      ),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('0/0 completed'), findsNothing);
  });

  testWidgets('does not claim completion when the progress save fails', (
    tester,
  ) async {
    final service = _FakeLearningService(progressSaveResult: false);
    await tester.pumpWidget(_testApp(service));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Color basics').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mark Module Complete'));
    await tester.pumpAndSettle();

    expect(service.progressWriteCount, 1);
    expect(
      find.text('Could not save module progress. Please try again.'),
      findsOneWidget,
    );
    expect(
      find.text('Module completed and your progress was saved.'),
      findsNothing,
    );
  });

  testWidgets('shows completion only after the progress save succeeds', (
    tester,
  ) async {
    final service = _FakeLearningService();
    await tester.pumpWidget(_testApp(service));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Color basics').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mark Module Complete'));
    await tester.pumpAndSettle();

    expect(service.lastSavedProgress, 1.0);
    expect(
      find.text('Module completed and your progress was saved.'),
      findsOneWidget,
    );
    expect(find.text('1/1 completed'), findsOneWidget);
  });
}
