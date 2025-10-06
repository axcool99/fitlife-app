class Streak {
  final int current;
  final int longest;
  final DateTime? lastWorkoutDate;

  Streak({
    required this.current,
    required this.longest,
    this.lastWorkoutDate,
  });

  // Check if streak is active (worked out today or yesterday)
  bool get isActive {
    if (lastWorkoutDate == null) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final lastWorkoutDay = DateTime(
      lastWorkoutDate!.year,
      lastWorkoutDate!.month,
      lastWorkoutDate!.day,
    );

    return lastWorkoutDay == today || lastWorkoutDay == yesterday;
  }

  // Get streak status message
  String get statusMessage {
    if (current == 0) {
      return 'Start your streak today!';
    } else if (isActive) {
      return 'Keep it up!';
    } else {
      return 'Your streak ended. Start a new one!';
    }
  }

  // Get motivational message based on streak
  String get motivationalMessage {
    if (current == 0) {
      return 'Every journey begins with a single workout.';
    } else if (current < 3) {
      return 'You\'re building momentum!';
    } else if (current < 7) {
      return 'You\'re on fire!';
    } else if (current < 14) {
      return 'Consistency is your superpower!';
    } else if (current < 30) {
      return 'You\'re unstoppable!';
    } else {
      return 'Legend status achieved!';
    }
  }
}