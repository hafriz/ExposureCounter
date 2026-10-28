import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/app_repository.dart';

final repositoryProvider = Provider<AppRepository>((ref) => AppRepository());

final checkInsProvider = FutureProvider((ref) async {
  return ref.watch(repositoryProvider).getCheckIns();
});

final exposureItemsProvider = FutureProvider((ref) async {
  return ref.watch(repositoryProvider).getExposureItems();
});

final activeSessionProvider = FutureProvider((ref) async {
  return ref.watch(repositoryProvider).getActiveSession();
});

final sessionsProvider = FutureProvider((ref) async {
  return ref.watch(repositoryProvider).getSessions();
});

final urgesProvider = FutureProvider((ref) async {
  return ref.watch(repositoryProvider).getUrges();
});

final measurementsProvider =
    FutureProvider.family((ref, String sessionId) async {
  return ref.watch(repositoryProvider).getMeasurements(sessionId);
});

final activeDelayProvider = FutureProvider((ref) async {
  return ref.watch(repositoryProvider).getActiveDelay();
});
