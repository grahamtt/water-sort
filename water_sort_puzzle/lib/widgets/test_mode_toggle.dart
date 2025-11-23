import 'package:flutter/material.dart';
import '../services/test_mode_manager.dart';

/// Widget that provides a toggle interface for enabling/disabling test mode
/// 
/// This widget displays a switch with descriptive text and visual indicators
/// to help developers toggle test mode on and off. It includes proper error
/// handling for persistence failures and clear visual feedback about the
/// current test mode state.
class TestModeToggle extends StatefulWidget {
  final TestModeManager testModeManager;
  final VoidCallback? onError;

  const TestModeToggle({
    super.key,
    required this.testModeManager,
    this.onError,
  });

  @override
  State<TestModeToggle> createState() => _TestModeToggleState();
}

class _TestModeToggleState extends State<TestModeToggle> {
  late bool _isEnabled;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _isEnabled = widget.testModeManager.isTestModeEnabled;
  }

  @override
  void didUpdateWidget(TestModeToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.testModeManager != widget.testModeManager) {
      _isEnabled = widget.testModeManager.isTestModeEnabled;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: _isEnabled ? Colors.orange.shade100 : null,
      elevation: _isEnabled ? 4 : 1,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                Icons.bug_report,
                color: _isEnabled ? Colors.orange : Colors.grey,
                size: 28,
              ),
              title: const Text(
                'Test Mode',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isEnabled 
                      ? 'All levels unlocked for testing'
                      : 'Normal progression rules apply',
                    style: TextStyle(
                      color: _isEnabled ? Colors.orange.shade700 : Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
              trailing: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Switch(
                      value: _isEnabled,
                      onChanged: _handleToggle,
                      activeColor: Colors.orange,
                      activeTrackColor: Colors.orange.shade200,
                    ),
            ),
            if (_isEnabled) ...[
              const Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Colors.orange.shade700,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Test mode allows access to all levels for testing purposes. '
                        'Progress made in test mode will not affect normal game progression.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade700,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _handleToggle(bool value) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await widget.testModeManager.setTestMode(value);
      
      if (mounted) {
        setState(() {
          _isEnabled = value;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = _getErrorMessage(e);
        });
        
        // Call error callback if provided
        widget.onError?.call();
        
        // Show snackbar for additional user feedback
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to ${value ? 'enable' : 'disable'} test mode: ${_getErrorMessage(e)}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: () => _handleToggle(value),
              ),
            ),
          );
        }
      }
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error is TestModeException) {
      switch (error.type) {
        case TestModeErrorType.persistenceFailure:
          return 'Unable to save test mode setting';
        case TestModeErrorType.levelGenerationFailure:
          return 'Level generation error';
        case TestModeErrorType.progressCorruption:
          return 'Progress data error';
      }
    }
    return 'An unexpected error occurred';
  }
}