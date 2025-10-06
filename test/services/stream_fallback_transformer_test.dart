import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import '../../lib/services/stream_transformers.dart';

void main() {
  group('StreamTransformers', () {
    test('fallbackToCache emits cached value on stream error', () async {
      // Create a stream controller to simulate Firestore stream
      final controller = StreamController<List<int>>();
      final cachedValues = [1, 2, 3, 4, 5];

      // Transform the stream with fallback
      final transformedStream = controller.stream.transform(
        StreamTransformers.fallbackToCache<List<int>>(() async => cachedValues),
      );

      // Collect emitted values
      final emittedValues = <List<int>>[];
      final subscription = transformedStream.listen((value) => emittedValues.add(value as List<int>));

      // Emit a successful value first
      controller.add([10, 20, 30]);
      await Future.delayed(Duration.zero);

      // Then emit an error
      controller.addError(Exception('Firestore offline'));
      await Future.delayed(Duration.zero);

      // Close the controller
      await controller.close();
      await subscription.cancel();

      // Verify the sequence: first the successful value, then the cached fallback
      expect(emittedValues.length, 2);
      expect(emittedValues[0], [10, 20, 30]);
      expect(emittedValues[1], cachedValues);
    });

    test('fallbackToCache emits empty list when cache fails', () async {
      final controller = StreamController<List<String>>();

      // Transform with a cache function that throws
      final transformedStream = controller.stream.transform(
        StreamTransformers.fallbackToCache<List<String>>(() async {
          throw Exception('Cache unavailable');
        }),
      );

      final emittedValues = <dynamic>[];
      final errors = <dynamic>[];
      final subscription = transformedStream.listen(
        (value) => emittedValues.add(value),
        onError: (error) => errors.add(error),
      );

      // Emit an error
      controller.addError(Exception('Firestore error'));
      await Future.delayed(Duration.zero);

      await controller.close();
      await subscription.cancel();

      // Should emit empty list as fallback for List types
      expect(emittedValues.length, 1);
      expect(emittedValues[0], isEmpty);
      expect(errors.length, 0);
    });

    test('fallbackToCacheNullable handles nullable types', () async {
      final controller = StreamController<String?>();

      final transformedStream = controller.stream.transform(
        StreamTransformers.fallbackToCacheNullable<String>(() async => 'cached_value'),
      );

      final emittedValues = <String?>[];
      final subscription = transformedStream.listen((value) => emittedValues.add(value as String?));

      // Emit an error
      controller.addError(Exception('Error'));
      await Future.delayed(Duration.zero);

      await controller.close();
      await subscription.cancel();

      expect(emittedValues.length, 1);
      expect(emittedValues[0], 'cached_value');
    });
  });
}