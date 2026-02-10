/// Helper class for Spaced Repetition System (SRS) using the SM-2 algorithm.
///
/// The SM-2 algorithm calculates the next review interval based on:
/// - Current interval (days)
/// - Ease factor (EF): Indicates how easy the item is (default 2.5)
/// - Quality rating (q): 0-5 scale of how well the user remembered the item
class SRSAlgo {
  /// Calculate the next review schedule.
  ///
  /// [currentInterval]: The previous interval in days. 0 for new items.
  /// [currentEaseFactor]: The previous ease factor. Default 2.5.
  /// [quality]: Performance rating (0-5).
  ///
  /// Returns a record with (newInterval, newEaseFactor).
  static ({double newInterval, double newEaseFactor}) calculateNextReview({
    required double currentInterval,
    required double currentEaseFactor,
    required int quality,
  }) {
    // Quality must be between 0 and 5
    // 5 - perfect response
    // 4 - correct response after a hesitation
    // 3 - correct response recalled with serious difficulty
    // 2 - incorrect response; where the correct one seemed easy to recall
    // 1 - incorrect response; the correct one remembered
    // 0 - complete blackout.
    assert(quality >= 0 && quality <= 5);

    double newEaseFactor = currentEaseFactor;
    double newInterval = 0;

    if (quality >= 3) {
      // Correct response
      if (currentInterval == 0) {
        newInterval = 1; // First repetition = 1 day
      } else if (currentInterval == 1) {
        newInterval = 6; // Second repetition = 6 days
      } else {
        newInterval = (currentInterval * currentEaseFactor).roundToDouble();
      }

      // Update Ease Factor
      // EF' = EF + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02))
      newEaseFactor = currentEaseFactor + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
      if (newEaseFactor < 1.3) newEaseFactor = 1.3; // Minimum EF is 1.3
    } else {
      // Incorrect response: Reset interval to 1 day, keep EF same (or decrease slightly? SM-2 says keep EF but reset interval)
      // Actually standard SM-2 doesn't change EF on failure, just resets interval.
      // But some variants punish EF. Let's stick to standard SM-2 for simplicity:
      // Interval resets to 1.
      newInterval = 1;
      // Optionally we could decrease EF here too to punish hard words more.
      // Let's stick to the formula above which essentially handles EF updates for all q >= 3.
      // For q < 3, the interval resets.
    }

    return (newInterval: newInterval, newEaseFactor: newEaseFactor);
  }

  /// Get the timestamp for the next review based on the calculated interval.
  static int getNextReviewTimestamp(double intervalInDays) {
    final now = DateTime.now();
    final nextReviewDate = now.add(Duration(days: intervalInDays.toInt()));
    return nextReviewDate.millisecondsSinceEpoch;
  }
}
