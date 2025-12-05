import 'package:flutter/material.dart';
import 'package:rescueeats/core/appTheme/appColors.dart';
import 'package:rescueeats/screens/user/catchGameScreen.dart';
import 'package:rescueeats/core/model/game/game_session.dart';
import 'package:rescueeats/core/services/api_service.dart';
import 'package:rescueeats/core/services/daily_login_service.dart';
import 'package:rescueeats/features/widgets/daily_login_modal.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  late EnergySystem energySystem;
  int coins = 0;
  int xp = 0;
  int level = 1;
  Timer? energyTimer;
  bool isLoading = true;
  late DailyLoginService _dailyLoginService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _dailyLoginService = DailyLoginService(ApiService());
    _loadData();
    // Update energy every minute
    _startEnergyTimer();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Stop energy updates when app is paused/inactive, resume when active
    if (state == AppLifecycleState.resumed) {
      _startEnergyTimer();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _stopEnergyTimer();
    }
  }

  void _startEnergyTimer() {
    // Cancel existing timer to prevent multiple timers
    energyTimer?.cancel();

    energyTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        _updateEnergy();
      }
    });
  }

  void _stopEnergyTimer() {
    energyTimer?.cancel();
    energyTimer = null;
  }

  @override
  void dispose() {
    _stopEnergyTimer();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Public method to refresh game data (callable from parent widgets)
  void refresh() {
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load energy system from backend
      EnergySystem loadedEnergy;
      try {
        final apiService = ApiService();
        final energyData = await apiService.getEnergy();

        if (energyData != null) {
          final currentEnergy = energyData['current'] ?? 5;
          // final maxEnergy = energyData['max'] ?? 5; // Not used in constructor currently
          final minutesUntilNext = energyData['minutesUntilNext'];

          loadedEnergy = EnergySystem(
            currentEnergy: currentEnergy,
            lastEnergyUpdate: minutesUntilNext != null
                ? DateTime.now().subtract(
                    Duration(minutes: 30 - (minutesUntilNext as int)),
                  )
                : null,
          );
        } else {
          // Fallback to default if backend fetch fails
          loadedEnergy = EnergySystem();
        }
      } catch (e) {
        loadedEnergy = EnergySystem();
      }

      // Fetch game data from backend API
      int loadedCoins = 0;
      int loadedXp = 0;
      int loadedLevel = 1;

      try {
        // Import ApiService
        final apiService = ApiService();
        final gameData = await apiService.initGame();

        if (gameData != null) {
          // Extract data from backend response
          loadedCoins = gameData['coins'] ?? 0;
          loadedXp = gameData['xp'] ?? 0;
          loadedLevel = gameData['level'] ?? 1;

          // Cache in SharedPreferences for offline access
          await prefs.setInt('game_coins', loadedCoins);
          await prefs.setInt('game_xp', loadedXp);
          await prefs.setInt('game_level', loadedLevel);

          // Check and show daily login modal
          try {
            final canClaim = await _dailyLoginService.canClaimToday();
            if (canClaim && mounted) {
              // Small delay to let UI render first
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted) {
                  _showDailyLoginModal();
                }
              });
            }
          } catch (e) {
            // Silently fail - not critical
          }
        } else {
          // Fallback to cached data if backend fails
          loadedCoins = prefs.getInt('game_coins') ?? 0;
          loadedXp = prefs.getInt('game_xp') ?? 0;
          loadedLevel = prefs.getInt('game_level') ?? 1;
        }
      } catch (e) {
        // Fallback to cached data on error
        loadedCoins = prefs.getInt('game_coins') ?? 0;
        loadedXp = prefs.getInt('game_xp') ?? 0;
        loadedLevel = prefs.getInt('game_level') ?? 1;
      }

      if (mounted) {
        setState(() {
          coins = loadedCoins;
          xp = loadedXp;
          level = loadedLevel;
          energySystem = loadedEnergy;
          isLoading = false;
        });
      }
    } catch (e) {
      // Set defaults on error
      if (mounted) {
        setState(() {
          energySystem = EnergySystem();
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

  Future<void> _showDailyLoginModal() async {
    if (!mounted) return;

    try {
      final loginState = await _dailyLoginService.getLoginState();

      if (!mounted) return;

      // Double-check if user can actually claim
      if (!loginState.canClaimToday) {
        return;
      }
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => DailyLoginModal(
          loginState: loginState,
          loginService: _dailyLoginService,
          onRewardClaimed: () {
            // Reload data to update coins and XP
            _loadData();
          },
        ),
      );

      // Reload data after modal closes to ensure coins are updated
      if (mounted) {
        await _loadData();
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Failed to load daily rewards. Please try again.');
      }
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

              // Play Button
              ElevatedButton(
                onPressed: energySystem.canPlay()
                    ? () async {
                        // Use energy from backend
                        final apiService = ApiService();
                        final success = await apiService.useEnergy();

                        if (success) {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CatchGameScreen(),
                            ),
                          );
                          // Reload data to sync energy and coins
                          _loadData();
                        } else {
                          _showMessage('Not enough energy or network error!');
                        }
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

              // Daily Reward Button
              OutlinedButton(
                onPressed: _showDailyLoginModal,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  side: const BorderSide(color: AppColors.primary, width: 2),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('🎁', style: TextStyle(fontSize: 24)),
                    SizedBox(width: 8),
                    Text(
                      'Daily Login Rewards',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
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
