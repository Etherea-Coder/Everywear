typedef OutfitLogIdPageLoader =
    Future<List<String>> Function(int offset, int limit);
typedef OutfitItemLinkDeleter = Future<void> Function(List<String> outfitIds);

/// Removes outfit junction rows without depending on a server's default page
/// size or sending an unbounded `IN` filter to PostgREST.
Future<void> deleteOutfitLinksInPages({
  required OutfitLogIdPageLoader loadLogIds,
  required OutfitItemLinkDeleter deleteLinks,
  int pageSize = 500,
  int deleteBatchSize = 100,
}) async {
  if (pageSize <= 0 || deleteBatchSize <= 0) {
    throw ArgumentError('Page and delete batch sizes must be positive');
  }

  var offset = 0;
  while (true) {
    final outfitIds = await loadLogIds(offset, pageSize);
    for (var start = 0; start < outfitIds.length; start += deleteBatchSize) {
      final end = start + deleteBatchSize < outfitIds.length
          ? start + deleteBatchSize
          : outfitIds.length;
      await deleteLinks(outfitIds.sublist(start, end));
    }

    if (outfitIds.length < pageSize) return;
    offset += outfitIds.length;
  }
}
