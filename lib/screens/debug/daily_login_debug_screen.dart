import 'package:flutter/material.dart';
import 'package:rescueeats/core/services/api_service.dart';
import 'package:rescueeats/core/services/daily_login_service.dart';

/// Debug helper widget to test daily login functionality
/// Add this to your dev menu or use it as a standalone test screen
class DailyLoginDebugScreen extends StatefulWidget {
  const DailyLoginDebugScreen({super.key});

  @override
  State<DailyLoginDebugScreen> createState() => _DailyLoginDebugScreenState();
}

class _DailyLoginDebugScreenState extends State<DailyLoginDebugScreen> {
  final ApiService _apiService = ApiService();
  late DailyLoginService _loginService;

  String _logs = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loginService = DailyLoginService(_apiService);
    _addLog('Daily Login Debug Screen initialized');
  }

  void _addLog(String message) {
    setState(() {
      final timestamp = DateTime.now().toString().substring(11, 19);
      _logs = '[$timestamp] $message\n$_logs';
    });
    print('[DailyLoginDebug] $message');
  }

  Future<void> _testHealthCheck() async {
    setState(() => _isLoading = true);
    _addLog('Testing backend health...');

    try {
      // You'll need to add a health check method to ApiService
      _addLog('Backend URL: ${ApiService.baseUrl}');
      _addLog('Health check would go here - implement if needed');
    } catch (e) {
      _addLog('Health check error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testGetStatus() async {
    setState(() => _isLoading = true);
    _addLog('Getting daily reward status...');

    try {
      final status = await _apiService.getDailyRewardStatus();
      _addLog('Status received: ${status?.toString() ?? "null"}');

      if (status != null) {
        _addLog('Can claim today: ${status['canClaimToday']}');
        _addLog('Current streak: ${status['currentStreak']}');
        _addLog('Current day: ${status['currentDay']}');
      }
    } catch (e) {
      _addLog('Status error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testClaimReward() async {
    setState(() => _isLoading = true);
    _addLog('Attempting to claim daily reward...');

    try {
      final result = await _loginService.claimReward();
      _addLog('Claim result: ${result.toString()}');

      if (result['success'] == true) {
        _addLog('✅ SUCCESS! Reward: ${result['reward']} coins');
        _addLog('New streak: ${result['streak']}');
      } else {
        _addLog('❌ FAILED: ${result['message']}');
      }
    } catch (e) {
      _addLog('Claim error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testGetLoginState() async {
    setState(() => _isLoading = true);
    _addLog('Getting login state...');

    try {
      final state = await _loginService.getLoginState();
      _addLog('State received:');
      _addLog('  Current streak: ${state.currentStreak}');
      _addLog('  Current day: ${state.currentDay}');
      _addLog('  Can claim: ${state.canClaimToday}');
      _addLog('  Last claim: ${state.lastClaimDate}');
      _addLog('  Rewards count: ${state.rewards.length}');
    } catch (e) {
      _addLog('State error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _clearLogs() async {
    setState(() => _logs = '');
    _addLog('Logs cleared');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Login Debug'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _clearLogs,
            tooltip: 'Clear logs',
          ),
        ],
      ),
      body: Column(
        children: [
          // Control Panel
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Test Controls',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton(
                      onPressed: _isLoading ? null : _testHealthCheck,
                      child: const Text('Health Check'),
                    ),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _testGetStatus,
                      child: const Text('Get Status'),
                    ),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _testGetLoginState,
                      child: const Text('Get State'),
                    ),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _testClaimReward,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                      ),
                      child: const Text('Claim Reward'),
                    ),
                  ],
                ),
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: LinearProgressIndicator(),
                  ),
              ],
            ),
          ),

          // Logs Display
          Expanded(
            child: Container(
              color: Colors.black,
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                reverse: true,
                child: Text(
                  _logs.isEmpty
                      ? 'No logs yet. Click a button above to test.'
                      : _logs,
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
