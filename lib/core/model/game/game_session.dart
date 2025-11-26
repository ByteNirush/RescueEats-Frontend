class GameSession {
  final DateTime startTime;
  final int finalScore;
  final int coinsEarned;
  final int xpEarned;
  final int itemsCaught;
  final int maxCombo;
  final Duration playTime;

  GameSession({
    required this.startTime,
    required this.finalScore,
    required this.coinsEarned,
    required this.xpEarned,
    required this.itemsCaught,
    required this.maxCombo,
    required this.playTime,
  });

  Map<String, dynamic> toJson() => {
    'startTime': startTime.toIso8601String(),
    'finalScore': finalScore,
    'coinsEarned': coinsEarned,
    'xpEarned': xpEarned,
    'itemsCaught': itemsCaught,
    'maxCombo': maxCombo,
    'playTime': playTime.inSeconds,
  };

  factory GameSession.fromJson(Map<String, dynamic> json) => GameSession(
    startTime: DateTime.parse(json['startTime']),
    finalScore: json['finalScore'],
    coinsEarned: json['coinsEarned'],
    xpEarned: json['xpEarned'],
    itemsCaught: json['itemsCaught'],
    maxCombo: json['maxCombo'],
    playTime: Duration(seconds: json['playTime']),
  );
}

class EnergySystem {
  static const int maxEnergy = 5;
  static const Duration energyRegenTime = Duration(hours: 2);

  int currentEnergy;
  DateTime? lastEnergyUpdate;

  EnergySystem({this.currentEnergy = maxEnergy, this.lastEnergyUpdate});

  void useEnergy() {
    if (currentEnergy > 0) {
      currentEnergy--;
      lastEnergyUpdate = DateTime.now();
    }
  }

  void regenerateEnergy() {
    if (currentEnergy >= maxEnergy || lastEnergyUpdate == null) return;

    final now = DateTime.now();
    final timePassed = now.difference(lastEnergyUpdate!);
    final energyToAdd = timePassed.inHours ~/ energyRegenTime.inHours;

    if (energyToAdd > 0) {
      currentEnergy = (currentEnergy + energyToAdd).clamp(0, maxEnergy);
      lastEnergyUpdate = now;
    }
  }

  Duration? getTimeUntilNextEnergy() {
    if (currentEnergy >= maxEnergy || lastEnergyUpdate == null) return null;

    final now = DateTime.now();
    final timePassed = now.difference(lastEnergyUpdate!);
    final secondsPassed = timePassed.inSeconds;
    final regenSeconds = energyRegenTime.inSeconds;
    final secondsUntilNext = regenSeconds - (secondsPassed % regenSeconds);

    return Duration(seconds: secondsUntilNext);
  }

  bool canPlay() => currentEnergy > 0;

  Map<String, dynamic> toJson() => {
    'currentEnergy': currentEnergy,
    'lastEnergyUpdate': lastEnergyUpdate?.toIso8601String(),
  };

  factory EnergySystem.fromJson(Map<String, dynamic> json) {
    int currentEnergy = maxEnergy;
    DateTime? lastUpdate;

    // Handle both int and String types
    if (json['currentEnergy'] != null) {
      if (json['currentEnergy'] is int) {
        currentEnergy = json['currentEnergy'];
      } else if (json['currentEnergy'] is String) {
        currentEnergy = int.tryParse(json['currentEnergy']) ?? maxEnergy;
      }
    }

    if (json['lastEnergyUpdate'] != null && json['lastEnergyUpdate'] != '') {
      if (json['lastEnergyUpdate'] is DateTime) {
        lastUpdate = json['lastEnergyUpdate'];
      } else if (json['lastEnergyUpdate'] is String) {
        lastUpdate = DateTime.tryParse(json['lastEnergyUpdate']);
      }
    }

    return EnergySystem(
      currentEnergy: currentEnergy,
      lastEnergyUpdate: lastUpdate,
    );
  }
}
