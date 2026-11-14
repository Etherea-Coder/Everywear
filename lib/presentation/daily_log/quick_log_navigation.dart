/// Awaits a pushed route and refreshes the caller when that route returns,
/// including when the route is dismissed without a result.
Future<T?> pushRouteAndRefresh<T>({
  required Future<T?> Function() pushRoute,
  required Future<void> Function() refresh,
}) async {
  final result = await pushRoute();
  await refresh();
  return result;
}
