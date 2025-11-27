import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rescueeats/core/model/game/food.dart';
import 'package:rescueeats/core/model/game/player.dart';
import 'package:rescueeats/core/model/game/powerups.dart';
import 'package:rescueeats/core/model/game/game_session.dart';
import 'package:rescueeats/core/services/api_service.dart';

class Particle {
  double x;
  double y;
  double vx;
  double vy;
  Color color;
  double life;
  double maxLife;

  Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    this.maxLife = 1.0,
  }) : life = maxLife;

  void update() {
    x += vx;
    y += vy;
    vy += 0.001;
    life -= 0.02;
  }

  bool get isDead => life <= 0;
}

class CatchGameScreen extends StatefulWidget {
  const CatchGameScreen({super.key});

  @override
  State<CatchGameScreen> createState() => _CatchGameScreenState();
}

class _CatchGameScreenState extends State<CatchGameScreen>
    with SingleTickerProviderStateMixin {
  Ticker? _ticker;
  final Player player = Player();
  final List<Food> foods = [];
  final List<Particle> particles = [];
  final Random random = Random();
  final ApiService _apiService = ApiService();

  // Game state
  int coins = 0;
  int xp = 0;
  int level = 1;
  int score = 0;
  int lives = 3;
  int maxLives = 5;
  int combo = 0;
  int maxCombo = 0;
  int itemsCaught = 0;
  double scoreMultiplier = 1.0;
  bool isGameOver = false;
  bool isPaused = false;
  bool showTutorial = false;
  bool isLoadingBackend = false;
  DateTime? gameStartTime;

  // Energy system
  late EnergySystem energySystem;

  // Power-ups
  Map<PowerUp, bool> activePowerUps = {
    PowerUp.magnet: false,
    PowerUp.slow: false,
    PowerUp.doubleCoin: false,
    PowerUp.shield: false,
    PowerUp.timeFreeze: false,
    PowerUp.extraLife: false,
  };

  Map<PowerUp, Timer?> powerUpTimers = {};
  Map<PowerUp, DateTime?> powerUpCooldowns = {};

  double globalSpeedMul = 1.0;
  Timer? spawnTimer;
  int spawnInterval = 700;

  // Achievements
  Set<String> achievements = {};

  @override
  void initState() {
    super.initState();
    _loadLocal();
    gameStartTime = DateTime.now();
  }

  @override
  void dispose() {
    _ticker?.dispose();
    spawnTimer?.cancel();
    for (var timer in powerUpTimers.values) {
      timer?.cancel();
    }
    super.dispose();
  }

  Future<void> _loadLocal() async {
    setState(() {
      isLoadingBackend = true;
    });

    final prefs = await SharedPreferences.getInstance();

    // Load from backend
    final backendGame = await _apiService.initGame();

    setState(() {
      if (backendGame != null) {
        coins = backendGame['coins'] ?? 0;
        xp = backendGame['xp'] ?? 0;
        level = backendGame['level'] ?? 1;
      } else {
        coins = prefs.getInt('game_coins') ?? 0;
        xp = prefs.getInt('game_xp') ?? 0;
        level = prefs.getInt('game_level') ?? 1;
      }

      showTutorial = !(prefs.getBool('game_tutorial_completed') ?? false);

      final achievementsList = prefs.getStringList('achievements') ?? [];
      achievements = Set.from(achievementsList);

      final energyJson = prefs.getString('energy_system');
      if (energyJson != null && energyJson.isNotEmpty) {
        try {
          final params = Uri.splitQueryString(energyJson);
          energySystem = EnergySystem(
            currentEnergy: int.tryParse(params['currentEnergy'] ?? '5') ?? 5,
            lastEnergyUpdate: params['lastEnergyUpdate']?.isNotEmpty == true
                ? DateTime.tryParse(params['lastEnergyUpdate']!)
                : null,
          );
          energySystem.regenerateEnergy();
        } catch (e) {
          energySystem = EnergySystem();
        }
      } else {
        energySystem = EnergySystem();
      }

      isLoadingBackend = false;
    });

    if (!energySystem.canPlay()) {
      _showNoEnergyDialog();
    } else {
      if (showTutorial) {
        _showTutorialDialog();
      } else {
        _startGame();
      }
    }
  }

  void _saveLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('game_coins', coins);
    await prefs.setInt('game_xp', xp);
    await prefs.setInt('game_level', level);
    await prefs.setStringList('achievements', achievements.toList());

    _apiService.updateGameScore(coins, xp);
  }

  void _saveEnergySystem() async {
    final prefs = await SharedPreferences.getInstance();
    final json = energySystem.toJson();
    await prefs.setString(
      'energy_system',
      Uri(
        queryParameters: {
          'currentEnergy': json['currentEnergy'].toString(),
          'lastEnergyUpdate': json['lastEnergyUpdate'] ?? '',
        },
      ).query,
    );
  }

  void _startGame() {
    energySystem.useEnergy();
    _saveEnergySystem();
    _ticker = createTicker(_onTick)..start();
    _startSpawning();
  }

  void _startSpawning() {
    spawnTimer?.cancel();
    spawnTimer = Timer.periodic(Duration(milliseconds: spawnInterval), (_) {
      if (!isPaused && !isGameOver && !activePowerUps[PowerUp.timeFreeze]!) {
        _spawnFood();
      }
    });
  }

  void _updateSpawnRate() {
    final oldInterval = spawnInterval;
    spawnInterval = (700 - (level * 20)).clamp(300, 700);

    if (oldInterval != spawnInterval) {
      _startSpawning();
    }
  }

  void _spawnFood() {
    final rand = random.nextDouble();
    FoodType type;

    // Fixed spawn rates
    if (rand < 0.22) {
      type = FoodType.bomb;
    } else if (rand < 0.23) {
      type = FoodType.goldenApple;
    } else if (rand < 0.26) {
      type = FoodType.mysteryBox;
    } else if (rand < 0.29) {
      type = FoodType.heart;
    } else if (rand < 0.33) {
      type = FoodType.star;
    } else {
      final foodTypes = [
        FoodType.apple,
        FoodType.burger,
        FoodType.pizza,
        FoodType.donut,
        FoodType.taco,
        FoodType.sushi,
        FoodType.cake,
        FoodType.iceCream,
      ];
      type = foodTypes[random.nextInt(foodTypes.length)];
    }

    final f = Food(
      x: 0.1 + random.nextDouble() * 0.8,
      y: -0.05,
      speed: (0.004 + random.nextDouble() * 0.009) * globalSpeedMul,
      type: type,
      hasGlow: type == FoodType.goldenApple || type == FoodType.mysteryBox,
      rotation: random.nextDouble() * 2 * pi,
    );
    setState(() => foods.add(f));
  }

  void _onTick(Duration elapsed) {
    if (isPaused || isGameOver) return;

    setState(() {
      player.updateInvincibility();

      if (!activePowerUps[PowerUp.timeFreeze]!) {
        for (var f in foods) {
          f.y += f.speed;
          f.rotation += 0.05;
        }
      }

      particles.removeWhere((p) {
        p.update();
        return p.isDead;
      });

      foods.removeWhere((f) {
        bool caught = false;

        if (activePowerUps[PowerUp.magnet]! &&
            f.y > 0.5 &&
            (f.x - player.x).abs() < 0.3) {
          caught = true;
        }

        caught =
            caught ||
            (f.y > 0.84 &&
                (f.x > player.x - player.size && f.x < player.x + player.size));

        if (caught) {
          _handleItemCaught(f);
          return true;
        }

        if (f.y > 1.1 && f.isGood) {
          _breakCombo();
        }

        if (f.y > 1.3) return true;
        return false;
      });

      // Speed increases over time
      globalSpeedMul += 0.000005;

      scoreMultiplier = 1.0 + (combo * 0.1);
    });
  }

  void _handleItemCaught(Food food) {
    if (food.isBad) {
      if (activePowerUps[PowerUp.shield]! || player.isInvincible) {
        _createParticles(food.x, food.y, Colors.blue, 10);
      } else {
        lives--;
        _createParticles(food.x, food.y, Colors.red, 20);

        if (lives <= 0) {
          _gameOver();
        } else {
          player.activateInvincibility(const Duration(seconds: 2));
          _breakCombo();
        }
      }
    } else if (food.type == FoodType.heart) {
      if (lives < maxLives) {
        lives++;
        _createParticles(food.x, food.y, Colors.pink, 15);
      }
    } else if (food.type == FoodType.mysteryBox) {
      final reward = random.nextInt(3);
      if (reward == 0 && lives < maxLives) {
        lives++;
      } else if (reward == 1) {
        final bonusCoins = 10 + random.nextInt(15);
        coins += bonusCoins;
      } else {
        xp += 25;
      }
      _createParticles(food.x, food.y, Colors.purple, 25);
    } else if (food.isGood || food.isSpecial) {
      itemsCaught++;
      combo++;
      maxCombo = max(maxCombo, combo);

      final baseCoins = (food.coinValue * 0.5).ceil();
      final multiplier = activePowerUps[PowerUp.doubleCoin]! ? 2.0 : 1.0;
      final comboBonus = (combo > 10) ? (combo ~/ 10) : 0;
      final totalCoins = ((baseCoins * multiplier) + comboBonus).toInt();

      coins += totalCoins;
      xp += (3 * scoreMultiplier).toInt();
      score += (baseCoins * 10 * scoreMultiplier).toInt();

      final oldLevel = level;
      level = (xp ~/ 100) + 1;

      if (level > oldLevel) {
        _updateSpawnRate();
      }

      _createParticles(food.x, food.y, food.color, food.shouldGlow ? 30 : 15);

      _checkAchievements();

      if (itemsCaught % 10 == 0) {
        _apiService.updateGameScore(coins, xp);
      }

      _saveLocal();
    }
  }

  void _checkAchievements() {
    if (itemsCaught >= 100 && !achievements.contains('catcher_100')) {
      achievements.add('catcher_100');
      coins += 50;
      _showMessage('🏆 Achievement: Caught 100 items! +50 coins');
    }

    if (combo >= 15 && !achievements.contains('combo_15')) {
      achievements.add('combo_15');
      coins += 30;
      _showMessage('🔥 Achievement: 15x Combo Master! +30 coins');
    }

    if (combo >= 30 && !achievements.contains('combo_30')) {
      achievements.add('combo_30');
      coins += 75;
      _showMessage('⚡ Achievement: 30x Combo Legend! +75 coins');
    }

    if (score >= 15000 && !achievements.contains('score_15k')) {
      achievements.add('score_15k');
      coins += 100;
      _showMessage('💯 Achievement: 15,000 Points! +100 coins');
    }

    _saveLocal();
  }

  void _createParticles(double x, double y, Color color, int count) {
    for (int i = 0; i < count; i++) {
      final angle = random.nextDouble() * 2 * pi;
      final speed = 0.005 + random.nextDouble() * 0.01;
      particles.add(
        Particle(
          x: x,
          y: y,
          vx: cos(angle) * speed,
          vy: sin(angle) * speed,
          color: color,
        ),
      );
    }
  }

  void _breakCombo() {
    if (combo > 0) {
      setState(() => combo = 0);
    }
  }

  void activatePowerUp(PowerUp p) {
    final config = PowerUpConfig.get(p);

    if (powerUpCooldowns[p] != null) {
      final cooldownEnd = powerUpCooldowns[p]!.add(const Duration(seconds: 20));
      if (DateTime.now().isBefore(cooldownEnd)) {
        _showMessage('Power-up on cooldown!');
        return;
      }
    }

    if (coins < config.cost) {
      _showMessage('Not enough coins! Need ${config.cost} coins');
      return;
    }

    setState(() {
      coins -= config.cost;
      activePowerUps[p] = true;
      powerUpCooldowns[p] = DateTime.now();
    });

    _saveLocal();

    if (p == PowerUp.slow) {
      globalSpeedMul = max(0.5, globalSpeedMul * 0.6);
    } else if (p == PowerUp.extraLife) {
      if (lives < maxLives) {
        lives++;
        _showMessage('Gained extra life! ❤️');
      }
      setState(() => activePowerUps[p] = false);
      return;
    }

    if (config.durationSeconds > 0) {
      powerUpTimers[p]?.cancel();
      powerUpTimers[p] = Timer(Duration(seconds: config.durationSeconds), () {
        setState(() {
          activePowerUps[p] = false;
          if (p == PowerUp.slow) {
            globalSpeedMul = min(2.5, globalSpeedMul * 1.67);
          }
        });
      });
    }
  }

  void _movePlayer(double dx) {
    if (isPaused || isGameOver) return;
    setState(() {
      player.x += dx;
      player.x = player.x.clamp(player.size, 1.0 - player.size);
    });
  }

  void _togglePause() {
    setState(() {
      isPaused = !isPaused;
    });
  }

  void _gameOver() {
    setState(() {
      isGameOver = true;
    });

    _ticker?.dispose();
    spawnTimer?.cancel();

    final session = GameSession(
      startTime: gameStartTime!,
      finalScore: score,
      coinsEarned: coins,
      xpEarned: xp,
      itemsCaught: itemsCaught,
      maxCombo: maxCombo,
      playTime: DateTime.now().difference(gameStartTime!),
    );

    _apiService.saveGameSession(
      finalScore: score,
      coinsEarned: coins,
      xpEarned: xp,
      itemsCaught: itemsCaught,
      maxCombo: maxCombo,
      playTimeSeconds: session.playTime.inSeconds,
      difficulty: 'hard',
    );

    _saveLocal();

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _showGameOverDialog(session);
      }
    });
  }

  void _showMessage(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
      );
    }
  }

  void _showTutorialDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🎮 How to Play'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('👆 Drag to move basket', style: TextStyle(fontSize: 14)),
              SizedBox(height: 6),
              Text('🍔 Catch food for coins', style: TextStyle(fontSize: 14)),
              SizedBox(height: 6),
              Text('💣 Avoid bombs (-1 life)', style: TextStyle(fontSize: 14)),
              SizedBox(height: 6),
              Text('❤️ Hearts restore lives', style: TextStyle(fontSize: 14)),
              SizedBox(height: 6),
              Text('⭐ Special = bonus coins', style: TextStyle(fontSize: 14)),
              SizedBox(height: 6),
              Text(
                '🔥 Build combos for multipliers',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 6),
              Text(
                '⚡ Game gets faster as you level up!',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('game_tutorial_completed', true);
              if (mounted) {
                Navigator.pop(context);
                _startGame();
              }
            },
            child: const Text('Start Game!'),
          ),
        ],
      ),
    );
  }

  void _showNoEnergyDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('⚡ No Energy'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('You need energy to play!'),
            const SizedBox(height: 12),
            Text(
              'Energy: ${energySystem.currentEnergy}/${EnergySystem.maxEnergy}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            if (energySystem.getTimeUntilNextEnergy() != null)
              Text(
                'Next in: ${_formatDuration(energySystem.getTimeUntilNextEnergy()!)}',
                style: const TextStyle(fontSize: 12),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showGameOverDialog(GameSession session) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🎮 Game Over!', style: TextStyle(fontSize: 20)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _statRow('Score', session.finalScore.toString()),
              _statRow('Coins', '🪙 ${session.coinsEarned}'),
              _statRow('XP', '⭐ ${session.xpEarned}'),
              _statRow('Caught', session.itemsCaught.toString()),
              _statRow('Max Combo', '${session.maxCombo}x'),
              _statRow('Time', _formatDuration(session.playTime)),
              const Divider(),
              Text(
                'Energy: ${energySystem.currentEnergy}/${EnergySystem.maxEnergy}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Exit'),
          ),
          if (energySystem.canPlay())
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CatchGameScreen(),
                  ),
                );
              },
              child: const Text('Play Again'),
            ),
        ],
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes % 60;
    final seconds = d.inSeconds % 60;
    if (hours > 0) return '${hours}h ${minutes}m';
    if (minutes > 0) return '${minutes}m ${seconds}s';
    return '${seconds}s';
  }

  @override
  Widget build(BuildContext context) {
    if (isLoadingBackend) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading game data...'),
            ],
          ),
        ),
      );
    }

    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.orange.shade50,
              Colors.orange.shade100,
              Colors.orange.shade200,
              Colors.deepOrange.shade300,
            ],
            stops: const [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Game area
              Positioned.fill(
                top: 80,
                bottom: 100,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    _movePlayer(details.delta.dx / screenWidth);
                  },
                  child: Stack(
                    children: [
                      // Particles
                      for (var p in particles)
                        Positioned(
                          left: p.x * screenWidth,
                          top: (p.y * (screenHeight - 180)) + 80,
                          child: Opacity(
                            opacity: p.life / p.maxLife,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                gradient: RadialGradient(
                                  colors: [
                                    p.color.withOpacity(0.9),
                                    p.color.withOpacity(0.5),
                                    p.color.withOpacity(0.0),
                                  ],
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: p.color.withOpacity(0.5),
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                      // Foods
                      for (var f in foods)
                        Positioned(
                          left: (f.x * screenWidth) - 30,
                          top: ((f.y * (screenHeight - 180)) + 80) - 30,
                          child: Transform.rotate(
                            angle: f.rotation,
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                gradient: RadialGradient(
                                  colors: [
                                    f.color.withOpacity(0.9),
                                    f.color,
                                    f.color.withOpacity(0.7),
                                  ],
                                  stops: const [0.0, 0.7, 1.0],
                                ),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: f.shouldGlow
                                        ? Colors.amber.withOpacity(0.8)
                                        : Colors.black.withOpacity(0.4),
                                    blurRadius: f.shouldGlow ? 15 : 8,
                                    spreadRadius: f.shouldGlow ? 2 : 1,
                                    offset: const Offset(0, 4),
                                  ),
                                  if (f.shouldGlow)
                                    BoxShadow(
                                      color: f.color.withOpacity(0.6),
                                      blurRadius: 20,
                                      spreadRadius: 3,
                                    ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  f.icon,
                                  style: const TextStyle(
                                    fontSize: 36,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black26,
                                        offset: Offset(1, 1),
                                        blurRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                      // Player
                      Positioned(
                        left: (player.x * screenWidth) - 60,
                        bottom: 20,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 100),
                          width: 120,
                          height: 90,
                          child: Stack(
                            children: [
                              // Shadow layer
                              Positioned(
                                bottom: 0,
                                left: 10,
                                right: 10,
                                child: Container(
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(50),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 10,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // Main basket
                              Positioned(
                                bottom: 5,
                                left: 0,
                                right: 0,
                                child: Container(
                                  height: 80,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: player.isInvincible
                                          ? [
                                              Colors.cyan.shade200,
                                              Colors.cyan.shade400,
                                              Colors.blue.shade600,
                                            ]
                                          : activePowerUps[PowerUp.shield]!
                                          ? [
                                              Colors.blue.shade300,
                                              Colors.blue.shade500,
                                              Colors.blue.shade700,
                                            ]
                                          : [
                                              Colors.brown.shade300,
                                              Colors.brown.shade500,
                                              Colors.brown.shade700,
                                            ],
                                    ),
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(20),
                                      topRight: Radius.circular(20),
                                      bottomLeft: Radius.circular(25),
                                      bottomRight: Radius.circular(25),
                                    ),
                                    border: Border.all(
                                      color:
                                          (activePowerUps[PowerUp.shield]! ||
                                              player.isInvincible)
                                          ? Colors.white
                                          : Colors.brown.shade800,
                                      width: 3,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.4),
                                        blurRadius: 12,
                                        offset: const Offset(0, 6),
                                        spreadRadius: 1,
                                      ),
                                      if (activePowerUps[PowerUp.shield]! ||
                                          player.isInvincible)
                                        BoxShadow(
                                          color: Colors.white.withOpacity(0.5),
                                          blurRadius: 20,
                                          spreadRadius: 2,
                                        ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Icon(
                                      Icons.shopping_basket,
                                      size: 48,
                                      color: Colors.white,
                                      shadows: const [
                                        Shadow(
                                          color: Colors.black45,
                                          offset: Offset(2, 2),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Top HUD
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.black45, Colors.transparent],
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: List.generate(
                              maxLives,
                              (i) => Text(
                                i < lives ? '❤️' : '🖤',
                                style: const TextStyle(fontSize: 18),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              isPaused ? Icons.play_arrow : Icons.pause,
                              color: Colors.white,
                              size: 22,
                            ),
                            onPressed: _togglePause,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Score: $score',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  shadows: [
                                    Shadow(color: Colors.black, blurRadius: 3),
                                  ],
                                ),
                              ),
                              Text(
                                '🪙 $coins  ⭐ Lv.$level',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  shadows: [
                                    Shadow(color: Colors.black, blurRadius: 3),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          if (combo > 1)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: combo > 15
                                      ? [Colors.purple, Colors.pink]
                                      : combo > 10
                                      ? [Colors.orange, Colors.red]
                                      : [Colors.yellow.shade700, Colors.orange],
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                '🔥 ${combo}x',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Power-up buttons
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 90,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black45, Colors.transparent],
                    ),
                  ),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    children: [
                      for (var powerUp in PowerUp.values) _powerUpBtn(powerUp),
                    ],
                  ),
                ),
              ),

              // Pause overlay
              if (isPaused)
                Positioned.fill(
                  child: Container(
                    color: Colors.black54,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'PAUSED',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _togglePause,
                            child: const Text('Resume'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _powerUpBtn(PowerUp powerUp) {
    final config = PowerUpConfig.get(powerUp);
    final isActive = activePowerUps[powerUp]!;
    final canAfford = coins >= config.cost;

    bool onCooldown = false;
    if (powerUpCooldowns[powerUp] != null) {
      final cooldownEnd = powerUpCooldowns[powerUp]!.add(
        const Duration(seconds: 20),
      );
      onCooldown = DateTime.now().isBefore(cooldownEnd);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Opacity(
        opacity: (canAfford && !isActive && !onCooldown) ? 1.0 : 0.4,
        child: ElevatedButton(
          onPressed: (canAfford && !isActive && !onCooldown)
              ? () => activatePowerUp(powerUp)
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: isActive
                ? Colors.green.shade600
                : (canAfford ? Colors.black87 : Colors.grey.shade600),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 4,
            minimumSize: const Size(60, 60),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(config.icon, style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 2),
              Text(
                '${config.cost}',
                style: const TextStyle(fontSize: 9, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
