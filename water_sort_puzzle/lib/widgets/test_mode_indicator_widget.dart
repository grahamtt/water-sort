import 'package:flutter/material.dart';
import '../models/test_mode_indicator.dart';

/// Widget that displays a visual indicator when test mode is active
class TestModeIndicatorWidget extends StatelessWidget {
  final TestModeIndicator indicator;

  const TestModeIndicatorWidget({
    Key? key,
    required this.indicator,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: indicator.color.withOpacity(0.2),
        border: Border.all(color: indicator.color, width: 2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            indicator.icon,
            size: 16,
            color: indicator.color,
          ),
          const SizedBox(width: 4),
          Text(
            indicator.text,
            style: TextStyle(
              color: indicator.color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}