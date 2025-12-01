class DailyLoginReward {
  final int day;
  final int coins;
  final int? xp;
  final String displayText;
  final bool isClaimed;
  final bool isCurrentDay;
  final bool isLocked;

  DailyLoginReward({
    required this.day,
    required this.coins,
    this.xp,
    required this.displayText,
    this.isClaimed = false,
    this.isCurrentDay = false,
    this.isLocked = true,
  });

  factory DailyLoginReward.fromJson(Map<String, dynamic> json) {
    return DailyLoginReward(
      day: json['day'] ?? 0,
      coins: json['coins'] ?? 0,
      xp: json['xp'],
      displayText: json['displayText'] ?? '',
      isClaimed: json['isClaimed'] ?? false,
      isCurrentDay: json['isCurrentDay'] ?? false,
      isLocked: json['isLocked'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'day': day,
    'coins': coins,
    'xp': xp,
    'displayText': displayText,
    'isClaimed': isClaimed,
    'isCurrentDay': isCurrentDay,
    'isLocked': isLocked,
  };

  DailyLoginReward copyWith({
    int? day,
    int? coins,
    int? xp,
    String? displayText,
    bool? isClaimed,
    bool? isCurrentDay,
    bool? isLocked,
  }) {
    return DailyLoginReward(
      day: day ?? this.day,
      coins: coins ?? this.coins,
      xp: xp ?? this.xp,
      displayText: displayText ?? this.displayText,
      isClaimed: isClaimed ?? this.isClaimed,
      isCurrentDay: isCurrentDay ?? this.isCurrentDay,
      isLocked: isLocked ?? this.isLocked,
    );
  }

  // Default 7-day reward schedule
  static List<DailyLoginReward> getDefaultRewards() {
    return [
      DailyLoginReward(day: 1, coins: 50, xp: 10, displayText: '50 Coins'),
      DailyLoginReward(day: 2, coins: 75, xp: 15, displayText: '75 Coins'),
      DailyLoginReward(day: 3, coins: 100, xp: 20, displayText: '100 Coins'),
      DailyLoginReward(day: 4, coins: 150, xp: 25, displayText: '150 Coins'),
      DailyLoginReward(day: 5, coins: 200, xp: 30, displayText: '200 Coins'),
      DailyLoginReward(day: 6, coins: 300, xp: 40, displayText: '300 Coins'),
      DailyLoginReward(
        day: 7,
        coins: 500,
        xp: 50,
        displayText: '500 Coins\n🎉 Bonus!',
      ),
    ];
  }
}

class DailyLoginState {
  final int currentStreak;
  final DateTime? lastClaimDate;
  final bool canClaimToday;
  final List<DailyLoginReward> rewards;

  DailyLoginState({
    required this.currentStreak,
    this.lastClaimDate,
    required this.canClaimToday,
    required this.rewards,
  });

  factory DailyLoginState.fromJson(Map<String, dynamic> json) {
    final rewardsList =
        (json['rewards'] as List<dynamic>?)
            ?.map((r) => DailyLoginReward.fromJson(r as Map<String, dynamic>))
            .toList() ??
        DailyLoginReward.getDefaultRewards();

    return DailyLoginState(
      currentStreak: json['currentStreak'] ?? 0,
      lastClaimDate: json['lastClaimDate'] != null
          ? DateTime.parse(json['lastClaimDate'])
          : null,
      canClaimToday: json['canClaimToday'] ?? true,
      rewards: rewardsList,
    );
  }

  Map<String, dynamic> toJson() => {
    'currentStreak': currentStreak,
    'lastClaimDate': lastClaimDate?.toIso8601String(),
    'canClaimToday': canClaimToday,
    'rewards': rewards.map((r) => r.toJson()).toList(),
  };

  DailyLoginState copyWith({
    int? currentStreak,
    DateTime? lastClaimDate,
    bool? canClaimToday,
    List<DailyLoginReward>? rewards,
  }) {
    return DailyLoginState(
      currentStreak: currentStreak ?? this.currentStreak,
      lastClaimDate: lastClaimDate ?? this.lastClaimDate,
      canClaimToday: canClaimToday ?? this.canClaimToday,
      rewards: rewards ?? this.rewards,
    );
  }

  // Get current day (1-7) based on streak
  // When streak is 0 (new user) or if can claim today, next day is the current day
  int get currentDay {
    if (currentStreak == 0) return 1;
    if (canClaimToday) {
      // If can claim, the next day in sequence is current
      return ((currentStreak) % 7) + 1;
    }
    // If already claimed, show the day they claimed
    return ((currentStreak - 1) % 7) + 1;
  }

  // Update rewards with proper state
  List<DailyLoginReward> getUpdatedRewards() {
    return rewards.asMap().entries.map((entry) {
      final index = entry.key;
      final reward = entry.value;
      final dayNumber = index + 1;

      // Handle claimed status: days before current day are claimed
      final isClaimed = canClaimToday
          ? dayNumber < currentDay
          : dayNumber <= currentDay;

      return reward.copyWith(
        isClaimed: isClaimed,
        isCurrentDay: dayNumber == currentDay && canClaimToday,
        isLocked: dayNumber > currentDay,
      );
    }).toList();
  }
}
