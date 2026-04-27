import 'package:flutter_riverpod/flutter_riverpod.dart';

enum RefreshType { tests, lectures, users, testHistory, statistics, all }

class RefreshState {
  final int testsVersion;
  final int lecturesVersion;
  final int usersVersion;
  final int testHistoryVersion;
  final int statisticsVersion;

  const RefreshState({
    this.testsVersion = 0,
    this.lecturesVersion = 0,
    this.usersVersion = 0,
    this.testHistoryVersion = 0,
    this.statisticsVersion = 0,
  });

  RefreshState copyWith({
    int? testsVersion,
    int? lecturesVersion,
    int? usersVersion,
    int? testHistoryVersion,
    int? statisticsVersion,
  }) {
    return RefreshState(
      testsVersion: testsVersion ?? this.testsVersion,
      lecturesVersion: lecturesVersion ?? this.lecturesVersion,
      usersVersion: usersVersion ?? this.usersVersion,
      testHistoryVersion: testHistoryVersion ?? this.testHistoryVersion,
      statisticsVersion: statisticsVersion ?? this.statisticsVersion,
    );
  }
}

class RefreshNotifier extends StateNotifier<RefreshState> {
  RefreshNotifier() : super(const RefreshState());
  void refresh(RefreshType type) {
    switch (type) {
      case RefreshType.tests:
        state = state.copyWith(testsVersion: state.testsVersion + 1);
        break;
      case RefreshType.lectures:
        state = state.copyWith(lecturesVersion: state.lecturesVersion + 1);
        break;
      case RefreshType.users:
        state = state.copyWith(usersVersion: state.usersVersion + 1);
        break;
      case RefreshType.testHistory:
        state = state.copyWith(
          testHistoryVersion: state.testHistoryVersion + 1,
        );
        break;
      case RefreshType.statistics:
        state = state.copyWith(statisticsVersion: state.statisticsVersion + 1);
        break;
      case RefreshType.all:
        state = RefreshState(
          testsVersion: state.testsVersion + 1,
          lecturesVersion: state.lecturesVersion + 1,
          usersVersion: state.usersVersion + 1,
          testHistoryVersion: state.testHistoryVersion + 1,
          statisticsVersion: state.statisticsVersion + 1,
        );
        break;
    }
  }

  void refreshMultiple(List<RefreshType> types) {
    for (final type in types) {
      refresh(type);
    }
  }

  void refreshAll() {
    refresh(RefreshType.all);
  }

  void refreshTestsAndRelated() {
    refreshMultiple([
      RefreshType.tests,
      RefreshType.testHistory,
      RefreshType.statistics,
    ]);
  }

  void refreshLecturesAndRelated() {
    refreshMultiple([RefreshType.lectures, RefreshType.statistics]);
  }
}

final refreshProvider = StateNotifierProvider<RefreshNotifier, RefreshState>((
  ref,
) {
  return RefreshNotifier();
});
final testsVersionProvider = Provider<int>((ref) {
  return ref.watch(refreshProvider.select((state) => state.testsVersion));
});

final lecturesVersionProvider = Provider<int>((ref) {
  return ref.watch(refreshProvider.select((state) => state.lecturesVersion));
});

final usersVersionProvider = Provider<int>((ref) {
  return ref.watch(refreshProvider.select((state) => state.usersVersion));
});

final testHistoryVersionProvider = Provider<int>((ref) {
  return ref.watch(refreshProvider.select((state) => state.testHistoryVersion));
});

final statisticsVersionProvider = Provider<int>((ref) {
  return ref.watch(refreshProvider.select((state) => state.statisticsVersion));
});
