import 'package:flutter/material.dart';

enum FoodType {
  // Common foods
  apple,
  burger,
  pizza,
  donut,

  // New food types
  taco,
  sushi,
  cake,
  iceCream,

  // Special items
  bomb,
  star,
  heart,

  // Rare items
  goldenApple,
  mysteryBox,
}

enum FoodRarity { common, rare, epic, legendary }

class Food {
  double x;
  double y;
  double speed;
  FoodType type;
  bool hasGlow;
  double rotation;

  Food({
    required this.x,
    required this.y,
    required this.speed,
    required this.type,
    this.hasGlow = false,
    this.rotation = 0,
  });

  String get icon {
    switch (type) {
      case FoodType.apple:
        return "🍎";
      case FoodType.burger:
        return "🍔";
      case FoodType.pizza:
        return "🍕";
      case FoodType.donut:
        return "🍩";
      case FoodType.taco:
        return "🌮";
      case FoodType.sushi:
        return "🍣";
      case FoodType.cake:
        return "🍰";
      case FoodType.iceCream:
        return "🍦";
      case FoodType.bomb:
        return "💣";
      case FoodType.star:
        return "⭐";
      case FoodType.heart:
        return "❤️";
      case FoodType.goldenApple:
        return "🏆";
      case FoodType.mysteryBox:
        return "🎁";
    }
  }

  Color get color {
    switch (type) {
      case FoodType.apple:
        return Colors.red.shade300;
      case FoodType.burger:
        return Colors.brown.shade300;
      case FoodType.pizza:
        return Colors.orange.shade300;
      case FoodType.donut:
        return Colors.pink.shade300;
      case FoodType.taco:
        return Colors.yellow.shade400;
      case FoodType.sushi:
        return Colors.teal.shade300;
      case FoodType.cake:
        return Colors.purple.shade200;
      case FoodType.iceCream:
        return Colors.cyan.shade200;
      case FoodType.bomb:
        return Colors.black87;
      case FoodType.star:
        return Colors.yellow.shade700;
      case FoodType.heart:
        return Colors.red.shade600;
      case FoodType.goldenApple:
        return Colors.amber.shade400;
      case FoodType.mysteryBox:
        return Colors.deepPurple.shade300;
    }
  }

  FoodRarity get rarity {
    switch (type) {
      case FoodType.goldenApple:
        return FoodRarity.legendary;
      case FoodType.mysteryBox:
        return FoodRarity.epic;
      case FoodType.star:
        return FoodRarity.rare;
      case FoodType.heart:
        return FoodRarity.rare;
      default:
        return FoodRarity.common;
    }
  }

  bool get isGood =>
      type == FoodType.apple ||
      type == FoodType.burger ||
      type == FoodType.pizza ||
      type == FoodType.donut ||
      type == FoodType.taco ||
      type == FoodType.sushi ||
      type == FoodType.cake ||
      type == FoodType.iceCream;

  bool get isBad => type == FoodType.bomb;

  bool get isSpecial =>
      type == FoodType.star ||
      type == FoodType.heart ||
      type == FoodType.goldenApple ||
      type == FoodType.mysteryBox;

  int get coinValue {
    switch (type) {
      case FoodType.apple:
        return 1;
      case FoodType.burger:
        return 2;
      case FoodType.pizza:
        return 3;
      case FoodType.donut:
        return 2;
      case FoodType.taco:
        return 3;
      case FoodType.sushi:
        return 4;
      case FoodType.cake:
        return 5;
      case FoodType.iceCream:
        return 2;
      case FoodType.star:
        return 10;
      case FoodType.goldenApple:
        return 50;
      case FoodType.mysteryBox:
        return 15;
      default:
        return 0;
    }
  }

  bool get shouldGlow =>
      rarity == FoodRarity.rare ||
      rarity == FoodRarity.epic ||
      rarity == FoodRarity.legendary;
}
