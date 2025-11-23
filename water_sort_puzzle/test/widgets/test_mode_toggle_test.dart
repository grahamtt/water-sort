import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../lib/services/test_mode_manager.dart';
import '../../lib/widgets/test_mode_toggle.dart';

import 'test_mode_toggle_test.mocks.dart';

@GenerateMocks([SharedPreferences])
void main() {
  group('TestModeToggle Widget Tests', () {
    late MockSharedPreferences mockPrefs;
    late TestModeManager testModeManager;

    setUp(() {
      mockPrefs = MockSharedPreferences();
      testModeManager = TestModeManager(mockPrefs);
    });

    testWidgets('should display test mode toggle with initial state disabled', (tester) async {
      // Arrange
      when(mockPrefs.getBool('test_mode_enabled')).thenReturn(false);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TestModeToggle(testModeManager: testModeManager),
          ),
        ),
      );

      // Assert
      expect(find.text('Test Mode'), findsOneWidget);
      expect(find.text('Normal progression rules apply'), findsOneWidget);
      expect(find.byIcon(Icons.bug_report), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);
      
      final switch_ = tester.widget<Switch>(find.byType(Switch));
      expect(switch_.value, false);
    });

    testWidgets('should display test mode toggle with initial state enabled', (tester) async {
      // Arrange
      when(mockPrefs.getBool('test_mode_enabled')).thenReturn(true);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TestModeToggle(testModeManager: testModeManager),
          ),
        ),
      );

      // Assert
      expect(find.text('Test Mode'), findsOneWidget);
      expect(find.text('All levels unlocked for testing'), findsOneWidget);
      expect(find.textContaining('Test mode allows access to all levels'), findsOneWidget);
      
      final switch_ = tester.widget<Switch>(find.byType(Switch));
      expect(switch_.value, true);
    });

    testWidgets('should toggle test mode when switch is pressed', (tester) async {
      // Arrange
      when(mockPrefs.getBool('test_mode_enabled')).thenReturn(false);
      when(mockPrefs.setBool('test_mode_enabled', true)).thenAnswer((_) async => true);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TestModeToggle(testModeManager: testModeManager),
          ),
        ),
      );

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      // Assert
      verify(mockPrefs.setBool('test_mode_enabled', true)).called(1);
      expect(find.text('All levels unlocked for testing'), findsOneWidget);
    });

    testWidgets('should show loading indicator while toggling', (tester) async {
      // Arrange
      when(mockPrefs.getBool('test_mode_enabled')).thenReturn(false);
      when(mockPrefs.setBool('test_mode_enabled', true)).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 100));
        return true;
      });

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TestModeToggle(testModeManager: testModeManager),
          ),
        ),
      );

      await tester.tap(find.byType(Switch));
      await tester.pump(); // Don't settle, so we can see loading state

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(Switch), findsNothing);

      // Wait for completion
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(Switch), findsOneWidget);
    });

    testWidgets('should handle persistence failure gracefully', (tester) async {
      // Arrange
      when(mockPrefs.getBool('test_mode_enabled')).thenReturn(false);
      when(mockPrefs.setBool('test_mode_enabled', true))
          .thenThrow(Exception('Storage error'));

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TestModeToggle(testModeManager: testModeManager),
          ),
        ),
      );

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Unable to save test mode setting'), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('Failed to enable test mode'), findsOneWidget);
    });

    testWidgets('should handle TestModeException with specific error message', (tester) async {
      // Arrange
      when(mockPrefs.getBool('test_mode_enabled')).thenReturn(false);
      when(mockPrefs.setBool('test_mode_enabled', true))
          .thenThrow(const TestModeException(
            TestModeErrorType.persistenceFailure,
            'Failed to persist test mode state',
          ));

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TestModeToggle(testModeManager: testModeManager),
          ),
        ),
      );

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Unable to save test mode setting'), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('should call onError callback when error occurs', (tester) async {
      // Arrange
      bool errorCallbackCalled = false;
      when(mockPrefs.getBool('test_mode_enabled')).thenReturn(false);
      when(mockPrefs.setBool('test_mode_enabled', true))
          .thenThrow(Exception('Storage error'));

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TestModeToggle(
              testModeManager: testModeManager,
              onError: () => errorCallbackCalled = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      // Assert
      expect(errorCallbackCalled, true);
    });

    testWidgets('should show retry action in error snackbar', (tester) async {
      // Arrange
      when(mockPrefs.getBool('test_mode_enabled')).thenReturn(false);
      when(mockPrefs.setBool('test_mode_enabled', true))
          .thenThrow(Exception('Storage error'));

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TestModeToggle(testModeManager: testModeManager),
          ),
        ),
      );

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Retry'), findsOneWidget);
      
      // Test retry functionality
      when(mockPrefs.setBool('test_mode_enabled', true)).thenAnswer((_) async => true);
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      
      verify(mockPrefs.setBool('test_mode_enabled', true)).called(2); // Original + retry
    });

    testWidgets('should prevent multiple simultaneous toggles', (tester) async {
      // Arrange
      when(mockPrefs.getBool('test_mode_enabled')).thenReturn(false);
      when(mockPrefs.setBool('test_mode_enabled', true)).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 100));
        return true;
      });

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TestModeToggle(testModeManager: testModeManager),
          ),
        ),
      );

      // Tap the switch, which should start loading
      await tester.tap(find.byType(Switch));
      await tester.pump();
      
      // Verify loading state - switch should be replaced with progress indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(Switch), findsNothing);

      // Wait for completion
      await tester.pumpAndSettle();

      // Assert - should only be called once
      verify(mockPrefs.setBool('test_mode_enabled', true)).called(1);
    });

    testWidgets('should display different visual styles for enabled/disabled states', (tester) async {
      // Test disabled state
      when(mockPrefs.getBool('test_mode_enabled')).thenReturn(false);
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TestModeToggle(testModeManager: testModeManager),
          ),
        ),
      );

      Card disabledCard = tester.widget<Card>(find.byType(Card));
      Icon disabledIcon = tester.widget<Icon>(find.byIcon(Icons.bug_report));
      
      expect(disabledCard.color, isNull);
      expect(disabledIcon.color, Colors.grey);

      // Test enabled state - create new manager with enabled state
      final enabledMockPrefs = MockSharedPreferences();
      when(enabledMockPrefs.getBool('test_mode_enabled')).thenReturn(true);
      final enabledTestModeManager = TestModeManager(enabledMockPrefs);
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TestModeToggle(testModeManager: enabledTestModeManager),
          ),
        ),
      );

      Card enabledCard = tester.widget<Card>(find.byType(Card));
      Icon enabledIcon = tester.widget<Icon>(find.byIcon(Icons.bug_report));
      
      expect(enabledCard.color, Colors.orange.shade100);
      expect(enabledIcon.color, Colors.orange);
    });

    testWidgets('should show help text only when test mode is enabled', (tester) async {
      // Test disabled state - no help text
      when(mockPrefs.getBool('test_mode_enabled')).thenReturn(false);
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TestModeToggle(testModeManager: testModeManager),
          ),
        ),
      );

      expect(find.textContaining('Test mode allows access to all levels'), findsNothing);
      expect(find.byIcon(Icons.info_outline), findsNothing);

      // Test enabled state - create new manager with enabled state
      final enabledMockPrefs = MockSharedPreferences();
      when(enabledMockPrefs.getBool('test_mode_enabled')).thenReturn(true);
      final enabledTestModeManager = TestModeManager(enabledMockPrefs);
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TestModeToggle(testModeManager: enabledTestModeManager),
          ),
        ),
      );

      expect(find.textContaining('Test mode allows access to all levels'), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });
  });
}