import 'package:flutter/material.dart';
import 'package:rescueeats/core/appTheme/appColors.dart';
import 'package:rescueeats/screens/user/catchGameScreen.dart';
import 'package:rescueeats/core/model/game/game_session.dart';
import 'package:rescueeats/core/model/game/daily_task.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late EnergySystem energySystem;
  List<DailyTask> dailyTasks = [];
  int coins = 0;
  int xp = 0;
  int level = 1;
  Timer? energyTimer;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    // Update energy every minute
    energyTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _updateEnergy();
    });
  }

  @override
  void dispose() {
    energyTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load daily tasks
      final tasks = await DailyTaskManager.loadTasks();

      // Check and complete daily login task
      final lastLogin = prefs.getString('last_login_date');
      final today = DateTime.now();
      final todayStr = '${today.year}-${today.month}-${today.day}';

      if (lastLogin != todayStr) {
        await DailyTaskManager.completeTask(TaskType.dailyLogin);
        await prefs.setString('last_login_date', todayStr);
      }

      // Load energy system
      EnergySystem loadedEnergy;
      try {
        final energyJson = prefs.getString('energy_system');
        if (energyJson != null && energyJson.isNotEmpty) {
          final params = Uri.splitQueryString(energyJson);
          loadedEnergy = EnergySystem(
            currentEnergy: int.tryParse(params['currentEnergy'] ?? '5') ?? 5,
            lastEnergyUpdate: params['lastEnergyUpdate']?.isNotEmpty == true
                ? DateTime.tryParse(params['lastEnergyUpdate']!)
                : null,
          );
          loadedEnergy.regenerateEnergy();
        } else {
          loadedEnergy = EnergySystem();
        }
      } catch (e) {
        loadedEnergy = EnergySystem();
      }

      if (mounted) {
        setState(() {
          coins = prefs.getInt('game_coins') ?? 0;
          xp = prefs.getInt('game_xp') ?? 0;
          level = prefs.getInt('game_level') ?? 1;
          dailyTasks = tasks;
          energySystem = loadedEnergy;
          isLoading = false;
        });
      }
    } catch (e) {
      // Set defaults on error
      if (mounted) {
        setState(() {
          energySystem = EnergySystem();
          dailyTasks = DailyTask.getDefaultTasks();
          isLoading = false;
        });
      }
    }
  }

  void _updateEnergy() {
    setState(() {
      energySystem.regenerateEnergy();
    });
  }

  Future<void> _claimTaskReward(DailyTask task) async {
    if (!task.isCompleted || task.progress > task.target) {
      _showMessage('Task not completed or already claimed!');
      return;
    }

    final reward = await DailyTaskManager.claimReward(task.type);
    if (reward > 0) {
      setState(() {
        coins += reward;
        task.progress = task.target + 1; // Mark as claimed
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('game_coins', coins);

      _showMessage('Claimed $reward coins! 🎉', isSuccess: true);
    }
  }

  void _showMessage(String msg, {bool isSuccess = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: isSuccess ? Colors.green : null,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.amber.shade700, width: 2),
              ),
              child: Row(
                children: [
                  const Text('🪙', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 6),
                  Text(
                    '$coins',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 2,
        automaticallyImplyLeading: false,
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Energy Display Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text('⚡', style: TextStyle(fontSize: 32)),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Energy',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '${energySystem.currentEnergy}/${EnergySystem.maxEnergy}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (energySystem.currentEnergy < EnergySystem.maxEnergy &&
                        energySystem.getTimeUntilNextEnergy() != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Next in',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              _formatDuration(
                                energySystem.getTimeUntilNextEnergy()!,
                              ),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Daily Tasks Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('📋', style: TextStyle(fontSize: 24)),
                        const SizedBox(width: 8),
                        const Text(
                          'Daily Tasks',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Task List
                    for (var task in dailyTasks) _buildTaskItem(task),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Play Button
              ElevatedButton(
                onPressed: energySystem.canPlay()
                    ? () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CatchGameScreen(),
                          ),
                        );
                        // Complete play games task
                        await DailyTaskManager.completeTask(TaskType.playGames);
                        // Reload data
                        _loadData();
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  disabledBackgroundColor: Colors.grey,
                  elevation: 4,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.play_arrow, size: 28),
                    const SizedBox(width: 8),
                    Text(
                      energySystem.canPlay() ? 'Start Catch Game' : 'No Energy',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Stats Row
              Row(
                children: [
                  Expanded(child: _statCard('⭐', 'Level', level.toString())),
                  const SizedBox(width: 12),
                  Expanded(child: _statCard('🏆', 'XP', xp.toString())),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskItem(DailyTask task) {
    final isClaimed = task.progress > task.target;
    final canClaim = task.isCompleted && !isClaimed;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: canClaim ? Colors.green.shade200 : Colors.grey.shade200,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4),
              ],
            ),
            child: Center(
              child: Text(task.icon, style: const TextStyle(fontSize: 28)),
            ),
          ),
          const SizedBox(width: 12),

          // Task Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  task.description,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                if (task.target > 1)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: LinearProgressIndicator(
                      value: task.progressPercentage,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation(AppColors.primary),
                    ),
                  ),
              ],
            ),
          ),

          // Status/Claim Button
          if (isClaimed)
            const Icon(Icons.check_circle, color: Colors.green, size: 32)
          else if (canClaim)
            GestureDetector(
              onTap: () => _claimTaskReward(task),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Claim',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )
          else
            Icon(
              Icons.radio_button_unchecked,
              color: Colors.grey.shade400,
              size: 32,
            ),
        ],
      ),
    );
  }

  Widget _statCard(String icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes % 60;
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }
}
