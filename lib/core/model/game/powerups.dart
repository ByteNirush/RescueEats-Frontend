enum PowerUp { magnet, slow, doubleCoin, shield, timeFreeze, extraLife }

class PowerUpConfig {
  final PowerUp type;
  final int cost;
  final int durationSeconds;
  final String name;
  final String icon;
  final String description;

  const PowerUpConfig({
    required this.type,
    required this.cost,
    required this.durationSeconds,
    required this.name,
    required this.icon,
    required this.description,
  });

  static const Map<PowerUp, PowerUpConfig> configs = {
    PowerUp.magnet: PowerUpConfig(
      type: PowerUp.magnet,
      cost: 40,
      durationSeconds: 8,
      name: 'Magnet',
      icon: '🧲',
      description: 'Attracts nearby items',
    ),
    PowerUp.slow: PowerUpConfig(
      type: PowerUp.slow,
      cost: 25,
      durationSeconds: 7,
      name: 'Slow Motion',
      icon: '🐢',
      description: 'Slows down falling items',
    ),
    PowerUp.doubleCoin: PowerUpConfig(
      type: PowerUp.doubleCoin,
      cost: 60,
      durationSeconds: 12,
      name: 'Double Coins',
      icon: '💰',
      description: 'Doubles coin rewards',
    ),
    PowerUp.shield: PowerUpConfig(
      type: PowerUp.shield,
      cost: 35,
      durationSeconds: 10,
      name: 'Shield',
      icon: '🛡️',
      description: 'Protects from bombs',
    ),
    PowerUp.timeFreeze: PowerUpConfig(
      type: PowerUp.timeFreeze,
      cost: 80,
      durationSeconds: 3,
      name: 'Time Freeze',
      icon: '❄️',
      description: 'Freezes all items',
    ),
    PowerUp.extraLife: PowerUpConfig(
      type: PowerUp.extraLife,
      cost: 100,
      durationSeconds: 0,
      name: 'Extra Life',
      icon: '💚',
      description: 'Gain one extra life',
    ),
  };

  static PowerUpConfig get(PowerUp type) => configs[type]!;
}
