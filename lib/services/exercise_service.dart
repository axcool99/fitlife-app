import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/exercise.dart';
import 'cache_service.dart';
import 'network_service.dart';

/// Service for fetching exercises from ExerciseDB API via RapidAPI
class ExerciseService {
  final CacheService cacheService;
  final NetworkService _networkService;

  ExerciseService({required this.cacheService, required NetworkService networkService})
      : _networkService = networkService;

  static const String _baseUrl = 'https://exercisedb-api1.p.rapidapi.com/api/v1';
  static const String _searchEndpoint = '/exercises/search';
  static const String _exercisesEndpoint = '/exercises';

  // Cache keys
  static const String _exercisesCacheKey = 'exercise_list';

  /// Fetches exercises from cache if available, otherwise from ExerciseDB API.
  /// Automatically caches new data and avoids repeated network calls.
  ///
  /// [query] The search query string
  /// Returns a list of exercises matching the query
  Future<List<Exercise>> searchExercises(String query) async {
    try {
      // First check cache
      final cachedItem = await cacheService.get('exercise_cache_$query');
      if (cachedItem != null && cacheService.isCacheValid(cachedItem)) {
        final data = cachedItem['data'] as List<dynamic>?;
        if (data != null) {
          print('Loaded ${data.length} exercises from cache for query: $query');
          return data.map((json) => Exercise.fromJson(json)).toList();
        }
      }

      // Cache miss or expired, fetch from API
      print('Fetching exercises from API for query: $query');
      final exercises = await _fetchExercisesFromAPI(query: query);

      // Save to cache
      await cacheService.save('exercise_cache_$query', exercises.map((e) => e.toJson()).toList());

      return exercises;
    } catch (e) {
      print('Error fetching from API: $e');
      // On failure, try to return cached data even if expired
      final cachedItem = await cacheService.get('exercise_cache_$query');
      if (cachedItem != null) {
        final data = cachedItem['data'] as List<dynamic>?;
        if (data != null) {
          print('Returning ${data.length} cached exercises due to API failure');
          return data.map((json) => Exercise.fromJson(json)).toList();
        }
      }
      // If both cache and network fail, throw exception
      throw Exception('Failed to fetch exercises: $e');
    }
  }

  /// Get all exercises (with optional filters)
  Future<List<Exercise>> getExercises({
    String? bodyPart,
    String? targetMuscle,
    String? equipment,
  }) async {
    try {
      // Check cache first
      final cachedItem = await cacheService.get(_exercisesCacheKey);
      if (cachedItem != null && cacheService.isCacheValid(cachedItem)) {
        final data = cachedItem['data'] as List<dynamic>?;
        if (data != null) {
          final exercises = data.map((json) => Exercise.fromJson(json)).toList();
          return _filterExercises(exercises, bodyPart, targetMuscle, equipment);
        }
      }

      // Check if online
      final isOnline = await _networkService.isOnline();
      if (!isOnline) {
        return []; // Return empty if offline and no cache
      }

      // Fetch from API
      final exercises = await _fetchExercisesFromAPI();

      // Cache the results
      await cacheService.save(_exercisesCacheKey, exercises.map((e) => e.toJson()).toList());

      return _filterExercises(exercises, bodyPart, targetMuscle, equipment);
    } catch (e) {
      print('Error getting exercises: $e');
      // Return cached results if available, even if expired
      final cachedItem = await cacheService.get(_exercisesCacheKey);
      if (cachedItem != null) {
        final data = cachedItem['data'] as List<dynamic>?;
        if (data != null) {
          final exercises = data.map((json) => Exercise.fromJson(json)).toList();
          return _filterExercises(exercises, bodyPart, targetMuscle, equipment);
        }
      }
      return [];
    }
  }

  /// Get exercise by ID
  Future<Exercise?> getExerciseById(String id) async {
    try {
      final exercises = await getExercises();
      return exercises.where((exercise) => exercise.id == id).firstOrNull;
    } catch (e) {
      print('Error getting exercise by ID: $e');
      return null;
    }
  }

  /// Fetch exercises from ExerciseDB API
  Future<List<Exercise>> _fetchExercisesFromAPI({String? query}) async {
    final apiKey = dotenv.env['RAPIDAPI_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('RAPIDAPI_KEY not found in environment variables');
    }

    final headers = {
      'x-rapidapi-host': 'exercisedb-api1.p.rapidapi.com',
      'x-rapidapi-key': apiKey,
    };

    final url = query != null && query.isNotEmpty
        ? Uri.parse('$_baseUrl$_searchEndpoint?search=$query')
        : Uri.parse('$_baseUrl$_exercisesEndpoint');

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);

      // Handle different response formats
      List<dynamic> data;
      if (decoded is List) {
        data = decoded;
      } else if (decoded is Map && decoded.containsKey('exercises')) {
        // Some APIs return a map with 'exercises' key
        data = decoded['exercises'] as List<dynamic>;
      } else if (decoded is Map && decoded.containsKey('data')) {
        // Alternative format
        data = decoded['data'] as List<dynamic>;
      } else {
        // If it's a single exercise object, wrap it in a list
        data = [decoded];
      }

      return data.map((json) => Exercise.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch exercises: ${response.statusCode} ${response.body}');
    }
  }

  /// Filter exercises based on criteria
  List<Exercise> _filterExercises(
    List<Exercise> exercises,
    String? bodyPart,
    String? target,
    String? equipment,
  ) {
    return exercises.where((exercise) {
      if (bodyPart != null && bodyPart != 'all' && exercise.bodyPart != bodyPart) {
        return false;
      }
      if (target != null && target != 'all' && exercise.targetMuscle != target) {
        return false;
      }
      if (equipment != null && equipment != 'all' && exercise.equipment != equipment) {
        return false;
      }
      return true;
    }).toList();
  }



  /// Clear all cached exercise data
  Future<void> clearCache() async {
    try {
      await cacheService.clear(_exercisesCacheKey);
      // Note: To clear all exercise-related caches, we might need a pattern clear
      // For now, only clearing the main list
    } catch (e) {
      print('Error clearing exercise cache: $e');
    }
  }

  /// Get available body parts for filtering
  Future<List<String>> getAvailableBodyParts() async {
    try {
      final exercises = await getExercises();
      final bodyParts = exercises.map((e) => e.bodyPart).toSet().toList();
      bodyParts.sort();
      return bodyParts;
    } catch (e) {
      print('Error getting available body parts: $e');
      return [];
    }
  }

  /// Get available equipment for filtering
  Future<List<String>> getAvailableEquipment() async {
    try {
      final exercises = await getExercises();
      final equipment = exercises.map((e) => e.equipment).toSet().toList();
      equipment.sort();
      return equipment;
    } catch (e) {
      print('Error getting available equipment: $e');
      return [];
    }
  }

  /// Get available targets for filtering
  Future<List<String>> getAvailableTargets() async {
    try {
      final exercises = await getExercises();
      final targets = exercises.map((e) => e.targetMuscle).toSet().toList();
      targets.sort();
      return targets;
    } catch (e) {
      print('Error getting available targets: $e');
      return [];
    }
  }
}