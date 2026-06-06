import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dashboard_repository.dart';

final dashboardRepositoryProvider = Provider((ref) => DashboardRepository());

final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  return ref.watch(dashboardRepositoryProvider).getStats();
});
