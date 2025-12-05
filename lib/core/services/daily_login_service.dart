import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rescueeats/core/model/game/daily_login_reward.dart';
import 'package:rescueeats/core/services/api_service.dart';

class DailyLoginService {
  static const String _storageKey = 'daily_login_state';
  static const String _lastCheckKey = 'daily_login_last_check';

  final ApiService _apiService;

  DailyLoginService(this._apiService);

  /// Check if user can claim today's reward
  Future<bool> canClaimToday() async {
    try {
      // Always check backend first for accurate state
      final backendStatus = await _apiService.getDailyRewardStatus();

      if (backendStatus != null && backendStatus['success'] == true) {
        final canClaim = backendStatus['canClaimToday'] ?? false;
        return canClaim;
      }
    } catch (e) {
      // Backend check failed, using local state
    }

    // Fallback to local check
    final prefs = await SharedPreferences.getInstance();
    final lastClaimStr = prefs.getString(_lastCheckKey);

    if (lastClaimStr == null) return true;

    final lastClaim = DateTime.parse(lastClaimStr);
    final now = DateTime.now();

    // Check if it's a new day (reset at midnight)
    return !_isSameDay(lastClaim, now);
  }

  /// Get current daily login state
  Future<DailyLoginState> getLoginState() async {
    try {
      // Try to fetch from backend first
      final backendStatus = await _apiService.getDailyRewardStatus();

      if (backendStatus != null && backendStatus['success'] == true) {
        // Use backend data as source of truth
        final rewards =
            (backendStatus['rewards'] as List<dynamic>?)
                ?.map(
                  (r) => DailyLoginReward.fromJson(r as Map<String, dynamic>),
                )
                .toList() ??
            DailyLoginReward.getDefaultRewards();

        final state = DailyLoginState(
          currentStreak: backendStatus['currentStreak'] ?? 0,
          lastClaimDate: backendStatus['lastClaimDate'] != null
              ? DateTime.parse(backendStatus['lastClaimDate'])
              : null,
          canClaimToday: backendStatus['canClaimToday'] ?? true,
          rewards: rewards,
        );

        // Save to local storage for offline access
        await _saveState(state);

        return state;
      }
    } catch (e) {
      // Backend fetch failed, using local state
    }

    // Fallback to local storage if backend fails
    final prefs = await SharedPreferences.getInstance();
    final stateJson = prefs.getString(_storageKey);

    DailyLoginState state;

    if (stateJson != null) {
      // Load from local storage
      try {
        state = DailyLoginState.fromJson(json.decode(stateJson));
      } catch (e) {
        state = DailyLoginState(
          currentStreak: 0,
          lastClaimDate: null,
          canClaimToday: true,
          rewards: DailyLoginReward.getDefaultRewards(),
        );
      }
    } else {
      // Initialize new state
      state = DailyLoginState(
        currentStreak: 0,
        lastClaimDate: null,
        canClaimToday: true,
        rewards: DailyLoginReward.getDefaultRewards(),
      );
    }

    // Check if can claim today
    final canClaim = await canClaimToday();

    // Update streak if needed
    if (state.lastClaimDate != null) {
      final now = DateTime.now();
      final daysSinceLastClaim = now.difference(state.lastClaimDate!).inDays;

      // Reset streak if missed more than 1 day (not same day, not next day)
      if (daysSinceLastClaim > 1) {
        state = state.copyWith(
          currentStreak: 0,
          lastClaimDate: null,
          canClaimToday: true,
        );
      } else {
        state = state.copyWith(canClaimToday: canClaim);
      }
    } else {
      state = state.copyWith(canClaimToday: canClaim);
    }

    // Update rewards with current state
    final updatedRewards = state.getUpdatedRewards();
    state = state.copyWith(rewards: updatedRewards);

    print(
      '[DailyLogin] Final state - Day: ${state.currentDay}, CanClaim: ${state.canClaimToday}',
    );
    return state;
  }

  /// Claim today's reward
  Future<Map<String, dynamic>> claimReward() async {
    try {
      final canClaim = await canClaimToday();

      if (!canClaim) {
        print('[DailyLogin] Already claimed today');
        return {'success': false, 'message': 'Already claimed today!'};
      }

      // Get current state
      final state = await getLoginState();
      final currentDay = state.currentDay;

      // Validate day is within bounds
      if (currentDay < 1 || currentDay > state.rewards.length) {
        return {'success': false, 'message': 'Invalid reward day'};
      }

      final currentReward = state.rewards[currentDay - 1];

      // Call backend API with retry logic
      Map<String, dynamic>? result;
      int retryCount = 0;

      while (retryCount < 3) {
        try {
          result = await _apiService.claimDailyReward();
          if (result['success'] == true) {
            break;
          }
          retryCount++;
          if (retryCount < 3) {
            await Future.delayed(Duration(milliseconds: 500 * retryCount));
          }
        } catch (e) {
          retryCount++;
          if (retryCount >= 3) {
            rethrow;
          }
          await Future.delayed(Duration(milliseconds: 500 * retryCount));
        }
      }

      if (result != null && result['success'] == true) {
        // Extract data from backend response
        final rewardData = result['reward'] as Map<String, dynamic>?;
        final gameData = result['game'] as Map<String, dynamic>?;
        final newStreak = result['newStreak'] ?? state.currentStreak + 1;
        final now = DateTime.now();

        // Mark all rewards up to current day as claimed
        final updatedRewards = List<DailyLoginReward>.from(state.rewards);
        for (int i = 0; i < currentDay && i < updatedRewards.length; i++) {
          updatedRewards[i] = updatedRewards[i].copyWith(isClaimed: true);
        }

        final updatedState = state.copyWith(
          currentStreak: newStreak,
          lastClaimDate: now,
          canClaimToday: false,
          rewards: updatedRewards,
        );

        // Save to local storage immediately
        await _saveState(updatedState);

        final rewardCoins = rewardData?['coins'] ?? currentReward.coins;

        return {
          'success': true,
          'reward': rewardCoins,
          'xp': rewardData?['xp'] ?? currentReward.xp ?? 0,
          'newCoins': gameData?['coins'] ?? 0, // Updated coin balance
          'streak': newStreak,
          'day': rewardData?['day'] ?? currentDay,
          'message': result['message'] ?? 'Claimed $rewardCoins coins!',
        };
      } else {
        final message = result?['message'] ?? 'Backend request failed';
        return {
          'success': false,
          'message': message,
          'error': 'Backend returned success=false',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  /// Save state to local storage
  Future<void> _saveState(DailyLoginState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(state.toJson()));
    await prefs.setString(_lastCheckKey, DateTime.now().toIso8601String());
  }

  /// Check if two dates are on the same day
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// Reset streak (for testing or admin purposes)
  Future<void> resetStreak() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    await prefs.remove(_lastCheckKey);
  }

  /// Get days until streak resets
  Future<Duration?> getTimeUntilReset() async {
    final prefs = await SharedPreferences.getInstance();
    final lastClaimStr = prefs.getString(_lastCheckKey);

    if (lastClaimStr == null) return null;

    final lastClaim = DateTime.parse(lastClaimStr);
    final nextReset = DateTime(
      lastClaim.year,
      lastClaim.month,
      lastClaim.day + 1,
      0,
      0,
      0,
    );

    final now = DateTime.now();
    if (now.isAfter(nextReset)) return null;

    return nextReset.difference(now);
  }
}
