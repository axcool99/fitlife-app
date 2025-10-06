import 'dart:async';

/// Stream transformers for handling offline fallbacks in Firestore streams
class StreamTransformers {
  /// Creates a stream transformer that falls back to cached data when Firestore emits an error.
  /// This ensures streams continue to emit data even when offline or when Firestore permissions fail.
  ///
  /// Usage: stream.transform(fallbackToCache(() => cacheService.loadData()))
  static StreamTransformer<T, T> fallbackToCache<T>(
    Future<T> Function() loadCache,
  ) {
    return StreamTransformer.fromHandlers(
      handleError: (error, stackTrace, sink) async {
        print('Stream error, falling back to cache: $error');
        try {
          final cachedValue = await loadCache();
          sink.add(cachedValue);
        } catch (cacheError) {
          print('Failed to load cached data: $cacheError');
          // For List types, emit empty list; for other types, rethrow
          if (T.toString().startsWith('List<')) {
            // Create an empty list - the type will be inferred correctly in practice
            sink.add(<Never>[] as T);
          } else {
            // For non-list types, rethrow the error since we can't provide a default
            sink.addError(cacheError, stackTrace);
          }
        }
      },
    );
  }

  /// Creates a stream transformer for nullable types that falls back to cached data.
  /// Similar to fallbackToCache but explicitly handles nullable types.
  static StreamTransformer<T?, T?> fallbackToCacheNullable<T>(
    Future<T?> Function() loadCache,
  ) {
    return StreamTransformer.fromHandlers(
      handleError: (error, stackTrace, sink) async {
        print('Stream error, falling back to cached nullable data: $error');
        try {
          final cachedValue = await loadCache();
          sink.add(cachedValue);
        } catch (cacheError) {
          print('Failed to load cached nullable data: $cacheError');
          sink.add(null);
        }
      },
    );
  }
}