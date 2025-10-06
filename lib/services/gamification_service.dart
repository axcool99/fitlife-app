import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'analytics_service.dart';
import '../models/badge.dart';
import '../models/streak.dart';
import '../models/workout.dart';

class GamificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AnalyticsService _analyticsService;

  GamificationService(this._analyticsService);

  String? get currentUserId => _auth.currentUser?.uid;

  // Get current streak
  Future<Streak> getCurrentStreak() async {
    if (currentUserId == null) return Streak(current: 0, longest: 0, lastWorkoutDate: null);

    final streakCount = await _analyticsService.calculateStreak();
    final longestStreak = await _getLongestStreak();

    // Get last workout date
    final workouts = await _analyticsService.getWorkoutsInRange(
      DateTime.now().subtract(const Duration(days: 30)),
      DateTime.now(),
    );

    DateTime? lastWorkoutDate;
    if (workouts.isNotEmpty) {
      workouts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      lastWorkoutDate = workouts.first.createdAt;
    }

    return Streak(
      current: streakCount,
      longest: longestStreak,
      lastWorkoutDate: lastWorkoutDate,
    );
  }

  // Get longest streak ever achieved
  Future<int> _getLongestStreak() async {
    if (currentUserId == null) return 0;

    final userRef = _firestore.collection('users').doc(currentUserId);
    final gamificationDoc = await userRef.collection('gamification').doc('stats').get();

    if (gamificationDoc.exists) {
      return gamificationDoc.data()?['longestStreak'] ?? 0;
    }

    return 0;
  }

  // Update longest streak if current streak is longer
  Future<void> _updateLongestStreak(int currentStreak) async {
    if (currentUserId == null) return;

    final longestStreak = await _getLongestStreak();
    if (currentStreak > longestStreak) {
      final userRef = _firestore.collection('users').doc(currentUserId);
      await userRef.collection('gamification').doc('stats').set({
        'longestStreak': currentStreak,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  // Get all earned badges
  Future<List<Badge>> getEarnedBadges() async {
    if (currentUserId == null) return [];

    final userRef = _firestore.collection('users').doc(currentUserId);
    final badgesSnapshot = await userRef.collection('badges').get();

    return badgesSnapshot.docs.map((doc) => Badge.fromFirestore(doc)).toList();
  }

  // Check and award new badges
  Future<List<Badge>> checkAndAwardBadges() async {
    if (currentUserId == null) return [];

    final newBadges = <Badge>[];

    // Get current stats
    final streak = await getCurrentStreak();
    final totalWorkouts = await _getTotalWorkouts();
    final totalWeight = await _getTotalWeightLifted();

    // Update longest streak
    await _updateLongestStreak(streak.current);

    // Check streak badges
    final streakBadges = await _checkStreakBadges(streak);
    newBadges.addAll(streakBadges);

    // Check workout count badges
    final workoutBadges = await _checkWorkoutBadges(totalWorkouts);
    newBadges.addAll(workoutBadges);

    // Check weight lifting badges
    final weightBadges = await _checkWeightBadges(totalWeight);
    newBadges.addAll(weightBadges);

    // Check consistency badges
    final consistencyBadges = await _checkConsistencyBadges();
    newBadges.addAll(consistencyBadges);

    return newBadges;
  }

  // Check for streak-based badges
  Future<List<Badge>> _checkStreakBadges(Streak streak) async {
    final newBadges = <Badge>[];
    final earnedBadges = await getEarnedBadges();
    final earnedBadgeIds = earnedBadges.map((b) => b.id).toSet();

    final streakMilestones = [3, 7, 14, 30, 50, 100];

    for (final milestone in streakMilestones) {
      final badgeId = 'streak_$milestone';
      if (!earnedBadgeIds.contains(badgeId) && streak.current >= milestone) {
        final badge = Badge(
          id: badgeId,
          title: '${milestone} Day Streak!',
          description: 'Maintained a ${milestone}-day workout streak',
          icon: 'local_fire_department',
          color: '#FF6B35',
          earnedAt: DateTime.now(),
          category: BadgeCategory.streak,
        );
        await _awardBadge(badge);
        newBadges.add(badge);
      }
    }

    // Check longest streak badges
    final longestMilestones = [30, 50, 100];
    for (final milestone in longestMilestones) {
      final badgeId = 'longest_streak_$milestone';
      if (!earnedBadgeIds.contains(badgeId) && streak.longest >= milestone) {
        final badge = Badge(
          id: badgeId,
          title: 'Longest Streak: $milestone Days!',
          description: 'Achieved your longest workout streak of ${milestone} days',
          icon: 'emoji_events',
          color: '#FFD700',
          earnedAt: DateTime.now(),
          category: BadgeCategory.achievement,
        );
        await _awardBadge(badge);
        newBadges.add(badge);
      }
    }

    return newBadges;
  }

  // Check for workout count badges
  Future<List<Badge>> _checkWorkoutBadges(int totalWorkouts) async {
    final newBadges = <Badge>[];
    final earnedBadges = await getEarnedBadges();
    final earnedBadgeIds = earnedBadges.map((b) => b.id).toSet();

    final workoutMilestones = [10, 25, 50, 100, 250, 500, 1000];

    for (final milestone in workoutMilestones) {
      final badgeId = 'workouts_$milestone';
      if (!earnedBadgeIds.contains(badgeId) && totalWorkouts >= milestone) {
        final badge = Badge(
          id: badgeId,
          title: '$milestone Workouts!',
          description: 'Completed ${milestone} total workouts',
          icon: 'fitness_center',
          color: '#4CAF50',
          earnedAt: DateTime.now(),
          category: BadgeCategory.workouts,
        );
        await _awardBadge(badge);
        newBadges.add(badge);
      }
    }

    return newBadges;
  }

  // Check for weight lifting badges
  Future<List<Badge>> _checkWeightBadges(double totalWeight) async {
    final newBadges = <Badge>[];
    final earnedBadges = await getEarnedBadges();
    final earnedBadgeIds = earnedBadges.map((b) => b.id).toSet();

    final weightMilestones = [1000, 5000, 10000, 25000, 50000]; // in kg

    for (final milestone in weightMilestones) {
      final badgeId = 'weight_${milestone}kg';
      if (!earnedBadgeIds.contains(badgeId) && totalWeight >= milestone) {
        final badge = Badge(
          id: badgeId,
          title: '${milestone}kg Lifted!',
          description: 'Total weight lifted: ${milestone}kg',
          icon: 'sports_handball',
          color: '#9C27B0',
          earnedAt: DateTime.now(),
          category: BadgeCategory.strength,
        );
        await _awardBadge(badge);
        newBadges.add(badge);
      }
    }

    return newBadges;
  }

  // Check for consistency badges
  Future<List<Badge>> _checkConsistencyBadges() async {
    final newBadges = <Badge>[];
    final earnedBadges = await getEarnedBadges();
    final earnedBadgeIds = earnedBadges.map((b) => b.id).toSet();

    // Check for 30-day consistency (worked out every day for 30 days)
    final thirtyDayConsistency = await _checkDaysWorkedOut(30, 30);
    if (!earnedBadgeIds.contains('consistency_30') && thirtyDayConsistency) {
      final badge = Badge(
        id: 'consistency_30',
        title: '30-Day Warrior!',
        description: 'Worked out every day for 30 consecutive days',
        icon: 'military_tech',
        color: '#FF9800',
        earnedAt: DateTime.now(),
        category: BadgeCategory.consistency,
      );
      await _awardBadge(badge);
      newBadges.add(badge);
    }

    // Check for 7-day week consistency (4+ weeks)
    final weeklyConsistency = await _checkWeeklyConsistency(4);
    if (!earnedBadgeIds.contains('weekly_warrior') && weeklyConsistency) {
      final badge = Badge(
        id: 'weekly_warrior',
        title: 'Weekly Warrior!',
        description: 'Worked out 4+ days per week for 4 consecutive weeks',
        icon: 'calendar_month',
        color: '#2196F3',
        earnedAt: DateTime.now(),
        category: BadgeCategory.consistency,
      );
      await _awardBadge(badge);
      newBadges.add(badge);
    }

    return newBadges;
  }

  // Helper method to check if user worked out on X out of Y days
  Future<bool> _checkDaysWorkedOut(int requiredDays, int totalDays) async {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: totalDays));

    final workouts = await _analyticsService.getWorkoutsInRange(startDate, endDate);

    // Count unique days with workouts
    final workoutDays = workouts.map((w) =>
      DateTime(w.createdAt.year, w.createdAt.month, w.createdAt.day)
    ).toSet();

    return workoutDays.length >= requiredDays;
  }

  // Check weekly consistency (4+ days per week for X weeks)
  Future<bool> _checkWeeklyConsistency(int weeks) async {
    for (int i = 0; i < weeks; i++) {
      final weekStart = DateTime.now().subtract(Duration(days: i * 7 + 6));
      final weekEnd = weekStart.add(const Duration(days: 7));

      final workouts = await _analyticsService.getWorkoutsInRange(weekStart, weekEnd);
      final workoutDays = workouts.map((w) =>
        DateTime(w.createdAt.year, w.createdAt.month, w.createdAt.day)
      ).toSet();

      if (workoutDays.length < 4) return false;
    }
    return true;
  }

  // Get total workouts count
  Future<int> _getTotalWorkouts() async {
    if (currentUserId == null) return 0;

    final userWorkoutsRef = _firestore.collection('users').doc(currentUserId).collection('workouts');
    final snapshot = await userWorkoutsRef.get();
    return snapshot.docs.length;
  }

  // Get total weight lifted
  Future<double> _getTotalWeightLifted() async {
    if (currentUserId == null) return 0.0;

    final userWorkoutsRef = _firestore.collection('users').doc(currentUserId).collection('workouts');
    final snapshot = await userWorkoutsRef.get();

    double totalWeight = 0.0;
    for (final doc in snapshot.docs) {
      final workout = Workout.fromFirestore(doc);
      if (workout.weight != null && workout.weight! > 0) {
        totalWeight += workout.weight! * workout.sets * workout.reps;
      }
    }

    return totalWeight;
  }

  // Award a badge to the user
  Future<void> _awardBadge(Badge badge) async {
    if (currentUserId == null) return;

    final userRef = _firestore.collection('users').doc(currentUserId);
    await userRef.collection('badges').doc(badge.id).set(badge.toFirestore());
  }

  // Get gamification summary for home screen
  Future<GamificationSummary> getGamificationSummary() async {
    final streak = await getCurrentStreak();
    final badges = await getEarnedBadges();
    final totalWorkouts = await _getTotalWorkouts();

    return GamificationSummary(
      currentStreak: streak.current,
      longestStreak: streak.longest,
      totalBadges: badges.length,
      recentBadges: badges.where((badge) =>
        badge.earnedAt.isAfter(DateTime.now().subtract(const Duration(days: 7)))
      ).toList(),
      totalWorkouts: totalWorkouts,
    );
  }
}

class GamificationSummary {
  final int currentStreak;
  final int longestStreak;
  final int totalBadges;
  final List<Badge> recentBadges;
  final int totalWorkouts;

  GamificationSummary({
    required this.currentStreak,
    required this.longestStreak,
    required this.totalBadges,
    required this.recentBadges,
    required this.totalWorkouts,
  });
}