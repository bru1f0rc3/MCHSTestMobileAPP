import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mchs_mobile_app/providers/refresh_provider.dart';
import 'package:mchs_mobile_app/services/test_service.dart';
import 'package:mchs_mobile_app/models/test_model.dart';
import 'package:mchs_mobile_app/models/testing_model.dart';

class TestListState {
  final List<TestModel> tests;
  final bool isLoading;
  final String? error;
  final int currentPage;
  final bool hasMore;

  const TestListState({
    this.tests = const [],
    this.isLoading = false,
    this.error,
    this.currentPage = 1,
    this.hasMore = true,
  });

  TestListState copyWith({
    List<TestModel>? tests,
    bool? isLoading,
    String? error,
    int? currentPage,
    bool? hasMore,
  }) {
    return TestListState(
      tests: tests ?? this.tests,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class TestListNotifier extends StateNotifier<TestListState> {
  final TestService _testService;

  TestListNotifier(this._testService) : super(const TestListState()) {
    loadTests();
  }

  Future<void> loadTests({bool refresh = false}) async {
    if (refresh) {
      state = const TestListState(isLoading: true);
    } else if (state.isLoading || !state.hasMore) {
      return;
    } else {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      final page = refresh ? 1 : state.currentPage;
      final newTests = await _testService.getTests(page: page);

      state = state.copyWith(
        tests: refresh ? newTests : [...state.tests, ...newTests],
        isLoading: false,
        currentPage: page + 1,
        hasMore: newTests.isNotEmpty,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() => loadTests(refresh: true);
}

class AllTestListNotifier extends StateNotifier<TestListState> {
  final TestService _testService;

  AllTestListNotifier(this._testService) : super(const TestListState()) {
    loadTests();
  }

  Future<void> loadTests({bool refresh = false}) async {
    if (refresh) {
      state = const TestListState(isLoading: true);
    } else if (state.isLoading || !state.hasMore) {
      return;
    } else {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      final page = refresh ? 1 : state.currentPage;
      final newTests = await _testService.getAllTests(page: page);

      state = state.copyWith(
        tests: refresh ? newTests : [...state.tests, ...newTests],
        isLoading: false,
        currentPage: page + 1,
        hasMore: newTests.isNotEmpty,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() => loadTests(refresh: true);
}

final testListProvider = StateNotifierProvider<TestListNotifier, TestListState>(
  (ref) {
    final testService = ref.watch(testServiceProvider);
    ref.watch(testsVersionProvider);
    return TestListNotifier(testService);
  },
);
final allTestListProvider =
    StateNotifierProvider<AllTestListNotifier, TestListState>((ref) {
      final testService = ref.watch(testServiceProvider);
      ref.watch(testsVersionProvider);
      return AllTestListNotifier(testService);
    });
final testsProvider = FutureProvider.autoDispose<List<TestModel>>((ref) async {
  final testService = ref.watch(testServiceProvider);
  ref.watch(testsVersionProvider);
  return await testService.getTests();
});
final testDetailProvider = FutureProvider.family
    .autoDispose<TestDetailModel?, int>((ref, id) async {
      final testService = ref.watch(testServiceProvider);
      return await testService.getTestDetail(id);
    });
final testHistoryProvider = FutureProvider.autoDispose<List<TestResultModel>>((
  ref,
) async {
  final testService = ref.watch(testServiceProvider);
  ref.watch(testHistoryVersionProvider);
  return await testService.getTestHistory();
});
void refreshAllTestProviders(WidgetRef ref) {
  ref.read(refreshProvider.notifier).refreshTestsAndRelated();
  ref.invalidate(testListProvider);
  ref.invalidate(allTestListProvider);
  ref.invalidate(testsProvider);
  ref.invalidate(testHistoryProvider);
}
