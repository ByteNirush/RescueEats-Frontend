import 'package:flutter/material.dart';

class TrendIndicator extends StatelessWidget {
  final double value;
  final double? previousValue;
  final bool showPercentage;
  final Color? positiveColor;
  final Color? negativeColor;

  const TrendIndicator({
    super.key,
    required this.value,
    this.previousValue,
    this.showPercentage = true,
    this.positiveColor,
    this.negativeColor,
  });

  @override
  Widget build(BuildContext context) {
    if (previousValue == null || previousValue == 0) {
      return const SizedBox.shrink();
    }

    final change = value - previousValue!;
    final percentChange = (change / previousValue!) * 100;
    final isPositive = change >= 0;

    final color = isPositive
        ? (positiveColor ?? Colors.green)
        : (negativeColor ?? Colors.red);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.trending_up : Icons.trending_down,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            showPercentage
                ? '${percentChange.abs().toStringAsFixed(1)}%'
                : change.abs().toStringAsFixed(0),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
