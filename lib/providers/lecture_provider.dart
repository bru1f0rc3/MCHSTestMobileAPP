import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mchs_mobile_app/providers/refresh_provider.dart';
import 'package:mchs_mobile_app/services/lecture_service.dart';
import 'package:mchs_mobile_app/models/lecture_model.dart';

class LectureListState {
  final List<LectureModel> lectures;
  final bool isLoading;
  final String? error;
  final int currentPage;
  final bool hasMore;

  const LectureListState({
    this.lectures = const [],
    this.isLoading = false,
    this.error,
    this.currentPage = 1,
    this.hasMore = true,
  });

  LectureListState copyWith({
    List<LectureModel>? lectures,
    bool? isLoading,
    String? error,
    int? currentPage,
    bool? hasMore,
  }) {
    return LectureListState(
      lectures: lectures ?? this.lectures,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class LectureListNotifier extends StateNotifier<LectureListState> {
  static const int _pageSize = 20;
  final LectureService _lectureService;

  LectureListNotifier(this._lectureService) : super(const LectureListState()) {
    loadLectures();
  }

  Future<void> loadLectures({bool refresh = false}) async {
    if (refresh) {
      state = const LectureListState(isLoading: true);
    } else if (state.isLoading || !state.hasMore) {
      return;
    } else {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      final page = refresh ? 1 : state.currentPage;
      final newLectures = await _lectureService.getLectures(
        page: page,
        pageSize: _pageSize,
      );

      state = state.copyWith(
        lectures: refresh ? newLectures : [...state.lectures, ...newLectures],
        isLoading: false,
        currentPage: page + 1,
        hasMore: newLectures.length >= _pageSize,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() => loadLectures(refresh: true);
}

final lectureListProvider =
    StateNotifierProvider<LectureListNotifier, LectureListState>((ref) {
      final lectureService = ref.watch(lectureServiceProvider);
      ref.watch(lecturesVersionProvider);
      return LectureListNotifier(lectureService);
    });
final lecturesProvider = FutureProvider.autoDispose<List<LectureModel>>((
  ref,
) async {
  final lectureService = ref.watch(lectureServiceProvider);
  ref.watch(lecturesVersionProvider);
  return await lectureService.getLectures();
});
final lectureDetailProvider = FutureProvider.family
    .autoDispose<LectureModel?, int>((ref, id) async {
      final lectureService = ref.watch(lectureServiceProvider);
      return await lectureService.getLectureById(id);
    });
void refreshAllLectureProviders(WidgetRef ref) {
  ref.read(refreshProvider.notifier).refreshLecturesAndRelated();
  ref.invalidate(lectureListProvider);
  ref.invalidate(lecturesProvider);
}
