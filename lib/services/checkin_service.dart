import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/checkin.dart';

/// Service for managing CheckIn data in Firestore
/// CheckIns are stored under users/{userId}/checkins collection
class CheckInService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Collection reference for check-ins
  // Structure: users/{userId}/checkins
  CollectionReference get _checkInsCollection {
    if (currentUserId == null) throw Exception('User not authenticated');
    return _firestore.collection('users').doc(currentUserId).collection('checkins');
  }

  /// Get all check-ins for current user, ordered by date (oldest first for chart trends)
  Stream<List<CheckIn>> getCheckIns() {
    if (currentUserId == null) return Stream.value([]);

    return _checkInsCollection
        .orderBy('date', descending: false)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => CheckIn.fromFirestore(doc)).toList());
  }

  /// Get the most recent check-in for current user
  Future<CheckIn?> getLastCheckIn() async {
    if (currentUserId == null) return null;

    final snapshot = await _checkInsCollection
        .orderBy('date', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return CheckIn.fromFirestore(snapshot.docs.first);
  }

  /// Stream the most recent check-in for current user (real-time updates)
  /// Firestore query: users/{userId}/checkins.orderBy("date", descending: true).limit(1)
  /// This ensures we get the most recent check-in by date in descending order (newest first)
  /// and limit to just 1 document for performance
  Stream<CheckIn?> getLastCheckInStream() {
    if (currentUserId == null) return Stream.value(null);

    return _checkInsCollection
        .orderBy('date', descending: true) // Most recent first (descending order)
        .limit(1) // Only get the most recent check-in
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          final checkIn = CheckIn.fromFirestore(snapshot.docs.first);
          // Debug print for verification - shows retrieved check-in data
          debugPrint('HomeScreen: Retrieved last check-in - Weight: ${checkIn.weight}kg, Mood: ${checkIn.mood}, Date: ${checkIn.date.toLocal()}');
          return checkIn;
        });
  }

  /// Get check-ins for the last N days for trend analysis
  Future<List<CheckIn>> getRecentCheckIns({int days = 30}) async {
    if (currentUserId == null) return [];

    final cutoffDate = DateTime.now().subtract(Duration(days: days));

    final snapshot = await _checkInsCollection
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(cutoffDate))
        .orderBy('date', descending: false) // Oldest first for trend charts
        .get();

    return snapshot.docs.map((doc) => CheckIn.fromFirestore(doc)).toList();
  }

  /// Add a new check-in
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
      id: '', // Will be set by Firestore
      userId: currentUserId!,
      date: checkInDate,
      weight: weight,
      mood: mood,
      energyLevel: energyLevel,
      notes: notes,
    );

    await _checkInsCollection.add(checkIn.toFirestore());
  }

  /// Update an existing check-in
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

    await _checkInsCollection.doc(checkInId).update(updates);
  }

  /// Delete a check-in
  Future<void> deleteCheckIn(String checkInId) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    await _checkInsCollection.doc(checkInId).delete();
  }
}