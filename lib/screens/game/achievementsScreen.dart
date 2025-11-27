import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rescueeats/core/services/api_service.dart';

// --- PROVIDER ---

final achievementsProvider = FutureProvider.autoDispose<List<dynamic>>((
  ref,
) async {
  final apiService = ApiService();
  return apiService.getAchievements();
});

// --- UI ---

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievementsAsync = ref.watch(achievementsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Achievements')),
      body: achievementsAsync.when(
        data: (achievements) {
          if (achievements.isEmpty) {
            return const Center(
              child: Text(
                'No achievements unlocked yet.\nKeep rescuing food!',
                textAlign: TextAlign.center,
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: achievements.length,
            itemBuilder: (context, index) {
              final achievement = achievements[index];
              return Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.amber.shade100,
                    child: const Icon(Icons.emoji_events, color: Colors.amber),
                  ),
                  title: Text(
                    achievement['id'] ?? 'Achievement',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Unlocked on: ${_formatDate(achievement['unlockedAt'])}',
                  ),
                  trailing: achievement['reward'] != null
                      ? Chip(
                          label: Text('+${achievement['reward']} Coins'),
                          backgroundColor: Colors.green.shade100,
                          labelStyle: TextStyle(color: Colors.green.shade800),
                        )
                      : null,
                ),
              );
            },
          );
        },
        error: (err, stack) => Center(child: Text('Error: $err')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    final date = DateTime.tryParse(dateStr);
    if (date == null) return '';
    return '${date.day}/${date.month}/${date.year}';
  }
}
