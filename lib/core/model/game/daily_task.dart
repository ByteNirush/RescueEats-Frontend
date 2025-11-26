import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

enum TaskType { dailyLogin, rescueMeal, playGames }

class DailyTask {
  final TaskType type;
  final String title;
  final String description;
  final int reward;
  final String icon;
  bool isCompleted;
  int progress;
  int target;

  DailyTask({
    required this.type,
    required this.title,
    required this.description,
    required this.reward,
    required this.icon,
    this.isCompleted = false,
    this.progress = 0,
    required this.target,
  });

  double get progressPercentage => target > 0 ? progress / target : 0;

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'isCompleted': isCompleted,
    'progress': progress,
  };

  factory DailyTask.fromJson(Map<String, dynamic> json, TaskType type) {
    final task = DailyTask.getDefault(type);
    return DailyTask(
      type: type,
      title: task.title,
      description: task.description,
      reward: task.reward,
      icon: task.icon,
      isCompleted: json['isCompleted'] ?? false,
      progress: json['progress'] ?? 0,
      target: task.target,
    );
  }

  static DailyTask getDefault(TaskType type) {
    switch (type) {
      case TaskType.dailyLogin:
        return DailyTask(
          type: TaskType.dailyLogin,
          title: 'Daily Login',
          description: '+50 Coins',
          reward: 50,
          icon: '🎁',
          target: 1,
        );
      case TaskType.rescueMeal:
        return DailyTask(
          type: TaskType.rescueMeal,
          title: 'Rescue a Meal',
          description: '+30 Coins',
          reward: 30,
          icon: '🍔',
          target: 1,
        );
      case TaskType.playGames:
        return DailyTask(
          type: TaskType.playGames,
          title: 'Play 3 Games',
          description: '+10 Coins',
          reward: 10,
          icon: '🎮',
          target: 3,
        );
    }
  }

  static List<DailyTask> getDefaultTasks() {
    return [
      getDefault(TaskType.dailyLogin),
      getDefault(TaskType.rescueMeal),
      getDefault(TaskType.playGames),
    ];
  }
}

class DailyTaskManager {
  static const String _tasksKey = 'daily_tasks';
  static const String _lastResetKey = 'tasks_last_reset';

  static Future<List<DailyTask>> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();

    // Check if we need to reset tasks
    final lastReset = prefs.getString(_lastResetKey);
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month}-${today.day}';

    if (lastReset != todayStr) {
      // Reset tasks for new day
      await _resetTasks();
      return DailyTask.getDefaultTasks();
    }

    // Load existing tasks
    final tasksJson = prefs.getString(_tasksKey);
    if (tasksJson == null) {
      return DailyTask.getDefaultTasks();
    }

    try {
      final List<dynamic> tasksList = jsonDecode(tasksJson);
      return tasksList.map((json) {
        final typeStr = json['type'] as String;
        final type = TaskType.values.firstWhere((e) => e.name == typeStr);
        return DailyTask.fromJson(json, type);
      }).toList();
    } catch (e) {
      return DailyTask.getDefaultTasks();
    }
  }

  static Future<void> saveTasks(List<DailyTask> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = jsonEncode(tasks.map((t) => t.toJson()).toList());
    await prefs.setString(_tasksKey, tasksJson);
  }

  static Future<void> _resetTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month}-${today.day}';
    await prefs.setString(_lastResetKey, todayStr);
    await prefs.remove(_tasksKey);
  }

  static Future<void> completeTask(TaskType type, {int increment = 1}) async {
    final tasks = await loadTasks();
    final task = tasks.firstWhere((t) => t.type == type);

    if (!task.isCompleted) {
      task.progress = (task.progress + increment).clamp(0, task.target);
      if (task.progress >= task.target) {
        task.isCompleted = true;
      }
      await saveTasks(tasks);
    }
  }

  static Future<int> claimReward(TaskType type) async {
    final tasks = await loadTasks();
    final task = tasks.firstWhere((t) => t.type == type);

    if (task.isCompleted && task.progress >= task.target) {
      final reward = task.reward;
      // Mark as claimed by resetting progress beyond target
      task.progress = task.target + 1;
      await saveTasks(tasks);
      return reward;
    }
    return 0;
  }
}
