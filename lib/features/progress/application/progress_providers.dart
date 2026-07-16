import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mision_admision/app/dependencies.dart';
import 'package:mision_admision/core/time/local_date.dart';
import 'package:mision_admision/domain/models/daily_attempt.dart';
import 'package:mision_admision/domain/models/learner_progress.dart';
import 'package:mision_admision/domain/models/rank.dart';

final learnerProgressProvider = FutureProvider.autoDispose<LearnerProgress>((ref) async {
  final repository = ref.read(progressRepositoryProvider);
  final progress = await repository.load();
  final today = localDateKey(ref.read(appClockProvider).now());
  final reconciliation = ref.read(streakEngineProvider).reconcile(
        progress: progress,
        todayDateKey: today,
      );
  await repository.save(reconciliation.progress);
  return reconciliation.progress;
});

final pendingDailyAttemptProvider = FutureProvider.autoDispose<DailyAttempt?>((ref) {
  return ref.read(dailyAttemptRepositoryProvider).load();
});

final rankCatalogProvider = FutureProvider.autoDispose<List<Rank>>((ref) {
  return ref.read(rankRepositoryProvider).loadRanks();
});
