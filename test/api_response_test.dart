import 'package:flutter_test/flutter_test.dart';
import 'package:mchs_mobile_app/models/api_response.dart';

void main() {
  group('ApiResponse.fromJson', () {
    test('parses success response', () {
      final response = ApiResponse<int>.fromJson(
        {'success': true, 'message': 'ok', 'data': 42},
        (json) => json as int,
      );

      expect(response.success, isTrue);
      expect(response.message, 'ok');
      expect(response.data, 42);
      expect(response.isSuccess, isTrue);
      expect(response.isFailure, isFalse);
    });

    test('parses failure response', () {
      final response = ApiResponse<int>.fromJson(
        {
          'success': false,
          'message': 'Validation failed',
          'errors': ['field is required']
        },
        (json) => json as int,
      );

      expect(response.success, isFalse);
      expect(response.errors, ['field is required']);
      expect(response.isSuccess, isFalse);
      expect(response.isFailure, isTrue);
    });

    test('handles missing data', () {
      final response = ApiResponse<int>.fromJson(
        {'success': true},
        (json) => json as int,
      );

      expect(response.success, isTrue);
      expect(response.data, isNull);
      expect(response.isSuccess, isFalse);
    });
  });

  group('PagedResponse.fromJson', () {
    test('parses items', () {
      final paged = PagedResponse<Map<String, dynamic>>.fromJson(
        {
          'items': [
            {'id': 1},
            {'id': 2}
          ],
          'totalCount': 2,
          'page': 1,
          'pageSize': 20,
          'totalPages': 1,
          'hasNextPage': false,
          'hasPreviousPage': false,
        },
        (json) => json,
      );

      expect(paged.items.length, 2);
      expect(paged.totalCount, 2);
      expect(paged.page, 1);
      expect(paged.isEmpty, isFalse);
      expect(paged.isNotEmpty, isTrue);
    });

    test('handles empty items', () {
      final paged = PagedResponse<Map<String, dynamic>>.fromJson(
        {
          'items': [],
          'totalCount': 0,
          'page': 1,
          'pageSize': 20,
          'totalPages': 0,
          'hasNextPage': false,
          'hasPreviousPage': false,
        },
        (json) => json,
      );

      expect(paged.items, isEmpty);
      expect(paged.isEmpty, isTrue);
    });

    test('uses defaults for missing fields', () {
      final paged = PagedResponse<Map<String, dynamic>>.fromJson(
        {},
        (json) => json,
      );

      expect(paged.items, isEmpty);
      expect(paged.totalCount, 0);
      expect(paged.page, 1);
      expect(paged.pageSize, 20);
    });
  });
}
