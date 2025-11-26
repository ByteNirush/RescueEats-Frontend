import 'package:flutter/material.dart';
import 'package:rescueeats/screens/admin/widgets/trendIndicator.dart';

class AdminStatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;
  final String? subtitle;
  final VoidCallback? onTap;
  final double? trend;
  final double? previousValue;

  const AdminStatCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    this.subtitle,
    this.onTap,
    this.trend,
    this.previousValue,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12), // Reduced from 16
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              mainAxisSize: MainAxisSize.min, // Added to prevent overflow
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8), // Reduced from 12
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        icon,
                        color: color,
                        size: 20, // Reduced from 24
                      ),
                    ),
                    if (onTap != null)
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 12, // Reduced from 16
                        color: Colors.grey[400],
                      ),
                  ],
                ),
                const SizedBox(height: 8), // Reduced from 12
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11, // Reduced from 13
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4), // Reduced from 6
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          value,
                          style: const TextStyle(
                            fontSize: 18, // Reduced from 22
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                    if (previousValue != null) ...[
                      const SizedBox(width: 4),
                      TrendIndicator(
                        value:
                            double.tryParse(
                              value.replaceAll(RegExp(r'[^0-9.]'), ''),
                            ) ??
                            0,
                        previousValue: previousValue,
                      ),
                    ],
                  ],
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2), // Reduced from 4
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 9, // Reduced from 11
                      color: Colors.grey[500],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
