import 'package:flutter/material.dart';

/// Simple dialog widget for displaying loss notification
class LossDialog extends StatelessWidget {
  /// The loss message to display
  final String message;

  /// Callback when the restart button is pressed
  final VoidCallback onRestart;

  /// Callback when the level select button is pressed
  final VoidCallback onLevelSelect;

  const LossDialog({
    Key? key,
    required this.message,
    required this.onRestart,
    required this.onLevelSelect,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Game Over',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.red,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.sentiment_dissatisfied,
            size: 48,
            color: Colors.orange,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onLevelSelect,
          child: const Text(
            'Level Select',
            style: TextStyle(fontSize: 16),
          ),
        ),
        ElevatedButton(
          onPressed: onRestart,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: const Text(
            'Restart Level',
            style: TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }
}