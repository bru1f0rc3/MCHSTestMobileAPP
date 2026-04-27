import 'package:mchs_mobile_app/core/errors/exceptions.dart';

class Result<T> {
  final T? data;
  final AppException? error;

  bool get isSuccess => error == null;
  bool get isFailure => error != null;

  const Result._({this.data, this.error});
  factory Result.success(T data) => Result._(data: data);
  factory Result.failure(AppException error) => Result._(error: error);
  Result<R> map<R>(R Function(T data) transform) {
    if (isSuccess) {
      try {
        return Result.success(transform(data as T));
      } catch (e) {
        return Result.failure(
          UnknownException(
            message: 'Ошибка преобразования данных',
            originalError: e,
          ),
        );
      }
    } else {
      return Result.failure(error!);
    }
  }

  R when<R>({
    required R Function(T data) success,
    required R Function(AppException error) failure,
  }) {
    if (isSuccess) {
      return success(data as T);
    } else {
      return failure(error!);
    }
  }

  T getOrElse(T defaultValue) => data ?? defaultValue;
  T getOrElseGet(T Function() defaultValue) => data ?? defaultValue();
  T getOrThrow() {
    if (isSuccess) {
      return data as T;
    } else {
      throw error!;
    }
  }

  @override
  String toString() {
    if (isSuccess) {
      return 'Result.success($data)';
    } else {
      return 'Result.failure($error)';
    }
  }
}

extension ResultExtensions<T> on Future<Result<T>> {
  Future<Result<R>> map<R>(R Function(T data) transform) async {
    final result = await this;
    return result.map(transform);
  }

  Future<Result<T>> onSuccess(void Function(T data) action) async {
    final result = await this;
    if (result.isSuccess) {
      action(result.data as T);
    }
    return result;
  }

  Future<Result<T>> onFailure(void Function(AppException error) action) async {
    final result = await this;
    if (result.isFailure) {
      action(result.error!);
    }
    return result;
  }
}
