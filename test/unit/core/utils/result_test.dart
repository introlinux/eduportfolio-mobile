import 'package:eduportfolio/core/utils/result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Result', () {
    group('Success', () {
      test('should create success result with data', () {
        const data = 'test data';
        final result = Result<String>.success(data);

        expect(result.isSuccess, true);
        expect(result.isError, false);
        expect(result, isA<Success<String>>());
      });

      test('should execute success callback in when()', () {
        const data = 42;
        final result = Result<int>.success(data);

        final output = result.when(
          success: (value) => 'Success: $value',
          error: (message) => 'Error: $message',
        );

        expect(output, 'Success: 42');
      });
    });

    group('Error', () {
      test('should create error result with message', () {
        const message = 'Something went wrong';
        final result = Result<String>.error(message);

        expect(result.isSuccess, false);
        expect(result.isError, true);
        expect(result, isA<Error<String>>());
      });

      test('should execute error callback in when()', () {
        const message = 'Database error';
        final result = Result<int>.error(message);

        final output = result.when(
          success: (value) => 'Success: $value',
          error: (msg) => 'Error: $msg',
        );

        expect(output, 'Error: Database error');
      });
    });

    group('Type safety', () {
      test('should maintain type safety with different data types', () {
        final intResult = Result<int>.success(123);
        final stringResult = Result<String>.success('test');
        final boolResult = Result<bool>.error('failed');

        expect(intResult, isA<Result<int>>());
        expect(stringResult, isA<Result<String>>());
        expect(boolResult, isA<Result<bool>>());
      });
    });
  });
}
