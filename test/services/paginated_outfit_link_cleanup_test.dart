import 'package:flutter_test/flutter_test.dart';
import 'package:everywear/services/paginated_outfit_link_cleanup.dart';

void main() {
  group('deleteOutfitLinksInPages', () {
    test(
      'pages deterministically and bounds junction delete batches',
      () async {
        final pages = <int>[];
        final deletedBatches = <List<String>>[];

        await deleteOutfitLinksInPages(
          pageSize: 500,
          deleteBatchSize: 100,
          loadLogIds: (offset, limit) async {
            pages.add(offset);
            expect(limit, 500);
            final count = offset == 0 ? 500 : 1;
            return List.generate(count, (index) => 'outfit-${offset + index}');
          },
          deleteLinks: (ids) async => deletedBatches.add(ids),
        );

        expect(pages, [0, 500]);
        expect(deletedBatches, hasLength(6));
        expect(deletedBatches.map((batch) => batch.length), [
          100,
          100,
          100,
          100,
          100,
          1,
        ]);
        expect(deletedBatches.expand((batch) => batch), hasLength(501));
      },
    );

    test(
      'propagates listing failures instead of reporting reset success',
      () async {
        await expectLater(
          deleteOutfitLinksInPages(
            loadLogIds: (_, _) async => throw StateError('listing failed'),
            deleteLinks: (_) async {},
          ),
          throwsA(isA<StateError>()),
        );
      },
    );

    test('rejects invalid batch sizes', () async {
      await expectLater(
        deleteOutfitLinksInPages(
          loadLogIds: (_, _) async => const [],
          deleteLinks: (_) async {},
          pageSize: 0,
        ),
        throwsArgumentError,
      );
    });
  });
}
