import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/models.dart';

/// ProfileService - Manages user profile data in Firestore
class ProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Profile document reference
  DocumentReference<Map<String, dynamic>>? get _profileRef {
    final userId = currentUserId;
    if (userId == null) return null;
    return _firestore.collection('users').doc(userId).collection('profile').doc('data');
  }

  /// Get user profile stream for real-time updates
  Stream<Profile?> getProfileStream() {
    final ref = _profileRef;
    if (ref == null) return Stream.value(null);

    return ref.snapshots().map((snapshot) {
      if (snapshot.exists) {
        return Profile.fromFirestore(snapshot.data()!, snapshot.id);
      }
      return null;
    });
  }

  /// Get user profile (one-time read)
  Future<Profile?> getProfile() async {
    final ref = _profileRef;
    if (ref == null) return null;

    try {
      final snapshot = await ref.get();
      if (snapshot.exists) {
        return Profile.fromFirestore(snapshot.data()!, snapshot.id);
      }
      return null;
    } catch (e) {
      print('Error getting profile: $e');
      return null;
    }
  }

  /// Create or update user profile
  Future<bool> saveProfile(Profile profile) async {
    final ref = _profileRef;
    if (ref == null) return false;

    try {
      await ref.set(profile.toFirestore(), SetOptions(merge: true));
      return true;
    } catch (e) {
      print('Error saving profile: $e');
      return false;
    }
  }

  /// Initialize profile for new user
  Future<bool> initializeProfile(String displayName, String email) async {
    final profile = Profile.createDefault(displayName, email);
    return await saveProfile(profile);
  }

  /// Update display name (also updates Firebase Auth)
  Future<bool> updateDisplayName(String displayName) async {
    try {
      // Update Firebase Auth
      await _auth.currentUser?.updateDisplayName(displayName);

      // Update Firestore profile
      final profile = await getProfile();
      if (profile != null) {
        final updatedProfile = profile.copyWith(displayName: displayName);
        return await saveProfile(updatedProfile);
      }

      // Create new profile if doesn't exist
      final newProfile = Profile.createDefault(displayName, _auth.currentUser?.email ?? '');
      return await saveProfile(newProfile);
    } catch (e) {
      print('Error updating display name: $e');
      return false;
    }
  }

  /// Update email (requires re-authentication)
  Future<bool> updateEmail(String newEmail, String password) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) return false;

      // Re-authenticate user
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);

      // Update email in Firebase Auth
      await user.updateEmail(newEmail);

      // Update profile in Firestore
      final profile = await getProfile();
      if (profile != null) {
        final updatedProfile = profile.copyWith(email: newEmail);
        return await saveProfile(updatedProfile);
      }

      return true;
    } catch (e) {
      print('Error updating email: $e');
      return false;
    }
  }

  /// Update password
  Future<bool> updatePassword(String currentPassword, String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) return false;

      // Re-authenticate user
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(newPassword);
      return true;
    } catch (e) {
      print('Error updating password: $e');
      return false;
    }
  }

  /// Delete user account and all data
  Future<bool> deleteAccount(String password) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) return false;

      // Re-authenticate user
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);

      // Delete Firestore data first
      final userId = user.uid;
      final batch = _firestore.batch();

      // Delete profile data
      final profileRef = _firestore.collection('users').doc(userId).collection('profile').doc('data');
      batch.delete(profileRef);

      // Delete fitness data
      final fitnessDataRef = _firestore.collection('users').doc(userId).collection('fitnessData');
      final fitnessDocs = await fitnessDataRef.get();
      for (final doc in fitnessDocs.docs) {
        batch.delete(doc.reference);
      }

      // Delete workouts
      final workoutsRef = _firestore.collection('users').doc(userId).collection('workouts');
      final workoutDocs = await workoutsRef.get();
      for (final doc in workoutDocs.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      // Delete Firebase Auth account
      await user.delete();

      return true;
    } catch (e) {
      print('Error deleting account: $e');
      return false;
    }
  }

  /// Update fitness goals
  Future<bool> updateFitnessGoals({
    int? dailyCalorieTarget,
    int? stepGoal,
  }) async {
    try {
      final profile = await getProfile();
      if (profile == null) return false;

      final updatedProfile = profile.copyWith(
        dailyCalorieTarget: dailyCalorieTarget,
        stepGoal: stepGoal,
      );

      return await saveProfile(updatedProfile);
    } catch (e) {
      print('Error updating fitness goals: $e');
      return false;
    }
  }

  /// Update personal metrics
  Future<bool> updatePersonalMetrics({
    double? height,
    double? weight,
    int? age,
    String? fitnessLevel,
  }) async {
    try {
      final profile = await getProfile();
      if (profile == null) return false;

      final updatedProfile = profile.copyWith(
        height: height,
        weight: weight,
        age: age,
        fitnessLevel: fitnessLevel,
      );

      return await saveProfile(updatedProfile);
    } catch (e) {
      print('Error updating personal metrics: $e');
      return false;
    }
  }

  /// Check if profile exists
  Future<bool> profileExists() async {
    final ref = _profileRef;
    if (ref == null) return false;

    try {
      final snapshot = await ref.get();
      return snapshot.exists;
    } catch (e) {
      return false;
    }
  }

  /// Get profile completion percentage
  Future<double> getProfileCompletion() async {
    try {
      final profile = await getProfile();
      if (profile == null) return 0.0;

      int completedFields = 0;
      int totalFields = 8; // displayName, email, dailyCalorieTarget, stepGoal, height, weight, age, fitnessLevel

      if (profile.displayName.isNotEmpty) completedFields++;
      if (profile.email.isNotEmpty) completedFields++;
      if (profile.dailyCalorieTarget != null) completedFields++;
      if (profile.stepGoal != null) completedFields++;
      if (profile.height != null) completedFields++;
      if (profile.weight != null) completedFields++;
      if (profile.age != null) completedFields++;
      if (profile.fitnessLevel != null) completedFields++;

      return completedFields / totalFields;
    } catch (e) {
      return 0.0;
    }
  }
}