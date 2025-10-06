import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/checkin.dart';
import 'cache_service.dart';

/// Service for managing CheckIn data in Firestore
/// CheckIns are stored under users/{userId}/checkins collection
class CheckInService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CacheService _cacheService = CacheService();

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Collection reference for check-ins
  // Structure: users/{userId}/checkins
  CollectionReference get _checkInsCollection {
    if (currentUserId == null) throw Exception('User not authenticated');
    return _firestore.collection('users').doc(currentUserId).collection('checkins');
  }

  /// Get all check-ins for current user, ordered by timestamp descending (newest first)
  /// With offline support - returns cached data when offline
  Stream<List<CheckIn>> getCheckIns() {
    if (currentUserId == null) return Stream.value([]);

    return _checkInsCollection
        .orderBy('timestamp', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          final checkIns = snapshot.docs.map((doc) => CheckIn.fromFirestore(doc)).toList();

          // Cache the check-ins for offline use
          try {
            await _cacheService.saveCheckIns(checkIns);
          } catch (e) {
            print('Warning: Failed to cache check-ins: $e');
          }

          return checkIns;
        })
        .handleError((error) async* {
          print('Error loading check-ins from Firestore: $error');
          // Return cached data on error (offline mode)
          try {
            final cachedCheckIns = await _cacheService.loadCheckIns();
            yield cachedCheckIns..sort((a, b) => b.date.compareTo(a.date));
          } catch (cacheError) {
            print('Error loading cached check-ins: $cacheError');
            yield [];
          }
        });
  }

  /// Get the most recent check-in for current user
  Future<CheckIn?> getLastCheckIn() async {
    if (currentUserId == null) return null;

    final snapshot = await _checkInsCollection
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return CheckIn.fromFirestore(snapshot.docs.first);
  }

  /// Stream the most recent check-in for current user (real-time updates)
  /// Firestore query: users/{userId}/checkins.orderBy("timestamp", descending: true).limit(1)
  /// This ensures we get the most recent check-in by timestamp in descending order (newest first)
  /// and limit to just 1 document for performance
  /// With offline support - returns cached data when offline
  Stream<CheckIn?> getLastCheckInStream() {
    if (currentUserId == null) return Stream.value(null);

    return _checkInsCollection
        .orderBy('timestamp', descending: true) // Most recent first (descending order)
        .limit(1) // Only get the most recent check-in
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          final checkIn = CheckIn.fromFirestore(snapshot.docs.first);
          // Debug print for verification - shows retrieved check-in data
          debugPrint('HomeScreen: Retrieved last check-in - Weight: ${checkIn.weight}kg, Mood: ${checkIn.mood}, Date: ${checkIn.date.toLocal()}');
          return checkIn;
        })
        .handleError((error) async* {
          print('Error loading last check-in from Firestore: $error');
          // Return most recent cached check-in
          try {
            final cachedCheckIns = await _cacheService.loadCheckIns();
            if (cachedCheckIns.isNotEmpty) {
              cachedCheckIns.sort((a, b) => b.date.compareTo(a.date));
              yield cachedCheckIns.first;
            } else {
              yield null;
            }
          } catch (cacheError) {
            print('Error loading cached last check-in: $cacheError');
            yield null;
          }
        });
  }  /// Get check-ins for the last N days for trend analysis
  /// With offline support - returns cached data when offline
  Future<List<CheckIn>> getRecentCheckIns({int days = 30}) async {
    if (currentUserId == null) return [];

    final cutoffDate = DateTime.now().subtract(Duration(days: days));

    try {
      final snapshot = await _checkInsCollection
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(cutoffDate))
          .orderBy('timestamp', descending: false) // Oldest first for trend charts
          .get();

      final recentCheckIns = snapshot.docs.map((doc) => CheckIn.fromFirestore(doc)).toList();

      // Update cache with recent check-ins
      try {
        final allCachedCheckIns = await _cacheService.loadCheckIns();
        final updatedCheckIns = allCachedCheckIns.where((c) =>
          !recentCheckIns.any((rc) => rc.id == c.id)).toList() + recentCheckIns;
        await _cacheService.saveCheckIns(updatedCheckIns);
      } catch (e) {
        print('Warning: Failed to cache recent check-ins: $e');
      }

      return recentCheckIns;
    } catch (e) {
      print('Error loading recent check-ins from Firestore: $e');
      // Return cached check-ins filtered for the date range
      try {
        final allCachedCheckIns = await _cacheService.loadCheckIns();
        final recentCachedCheckIns = allCachedCheckIns
            .where((checkIn) => checkIn.date.isAfter(cutoffDate))
            .toList()
            ..sort((a, b) => a.date.compareTo(b.date)); // Oldest first for trend charts

        return recentCachedCheckIns;
      } catch (cacheError) {
        print('Error loading cached recent check-ins: $cacheError');
        return [];
      }
    }
  }

  /// Add a new check-in
  /// With offline support - saves to cache when offline
  Future<void> addCheckIn({
    required double weight,
    required String mood,
    required int energyLevel,
    String? notes,
    DateTime? date, // Optional, defaults to now
  }) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    // Validate inputs
    if (weight <= 0) throw Exception('Weight must be greater than 0');
    if (!CheckIn.moodOptions.contains(mood)) {
      throw Exception('Invalid mood. Must be one of: ${CheckIn.moodOptions.join(', ')}');
    }
    if (energyLevel < 1 || energyLevel > 5) {
      throw Exception('Energy level must be between 1 and 5');
    }

    final checkInDate = date ?? DateTime.now();

    final checkIn = CheckIn(
      id: DateTime.now().millisecondsSinceEpoch.toString(), // Generate ID for offline
      userId: currentUserId!,
      date: checkInDate,
      weight: weight,
      mood: mood,
      energyLevel: energyLevel,
      notes: notes,
    );

    try {
      // Try to save to Firestore first
      final docRef = await _checkInsCollection.add(checkIn.toFirestore());
      // Update with Firestore-generated ID
      final firestoreCheckIn = checkIn.copyWith(id: docRef.id);
      await docRef.update({'id': docRef.id});

      // Cache the check-in
      await _cacheService.saveCheckIn(firestoreCheckIn);
    } catch (e) {
      print('Failed to save check-in to Firestore, saving to cache: $e');
      // Save to cache for offline sync later
      await _cacheService.saveCheckIn(checkIn);
    }
  }

  /// Update an existing check-in
  /// With offline support - updates cache when offline
  Future<void> updateCheckIn(String checkInId, {
    double? weight,
    String? mood,
    int? energyLevel,
    String? notes,
  }) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    // Validate inputs if provided
    if (weight != null && weight <= 0) throw Exception('Weight must be greater than 0');
    if (mood != null && !CheckIn.moodOptions.contains(mood)) {
      throw Exception('Invalid mood. Must be one of: ${CheckIn.moodOptions.join(', ')}');
    }
    if (energyLevel != null && (energyLevel < 1 || energyLevel > 5)) {
      throw Exception('Energy level must be between 1 and 5');
    }

    final updates = <String, dynamic>{};
    if (weight != null) updates['weight'] = weight;
    if (mood != null) updates['mood'] = mood;
    if (energyLevel != null) updates['energyLevel'] = energyLevel;
    if (notes != null) updates['notes'] = notes;

    try {
      // Try to update in Firestore
      await _checkInsCollection.doc(checkInId).update(updates);

      // Update in cache - need to load current check-in and update it
      final allCheckIns = await _cacheService.loadCheckIns();
      final checkInIndex = allCheckIns.indexWhere((c) => c.id == checkInId);
      if (checkInIndex != -1) {
        final updatedCheckIn = allCheckIns[checkInIndex].copyWith(
          weight: weight ?? allCheckIns[checkInIndex].weight,
          mood: mood ?? allCheckIns[checkInIndex].mood,
          energyLevel: energyLevel ?? allCheckIns[checkInIndex].energyLevel,
          notes: notes ?? allCheckIns[checkInIndex].notes,
        );
        await _cacheService.saveCheckIn(updatedCheckIn);
      }
    } catch (e) {
      print('Failed to update check-in in Firestore, updating cache: $e');
      // Update in cache for offline sync later
      final allCheckIns = await _cacheService.loadCheckIns();
      final checkInIndex = allCheckIns.indexWhere((c) => c.id == checkInId);
      if (checkInIndex != -1) {
        final updatedCheckIn = allCheckIns[checkInIndex].copyWith(
          weight: weight ?? allCheckIns[checkInIndex].weight,
          mood: mood ?? allCheckIns[checkInIndex].mood,
          energyLevel: energyLevel ?? allCheckIns[checkInIndex].energyLevel,
          notes: notes ?? allCheckIns[checkInIndex].notes,
        );
        await _cacheService.saveCheckIn(updatedCheckIn);
      }
    }
  }

  /// Delete a check-in
  /// With offline support - removes from cache when offline
  Future<void> deleteCheckIn(String checkInId) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    try {
      // Try to delete from Firestore
      await _checkInsCollection.doc(checkInId).delete();

      // Remove from cache
      await _cacheService.removeCheckIn(checkInId);
    } catch (e) {
      print('Failed to delete check-in from Firestore, removing from cache: $e');
      // Remove from cache for offline sync
      await _cacheService.removeCheckIn(checkInId);
    }
  }
}