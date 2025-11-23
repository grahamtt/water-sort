import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../lib/services/dependency_injection.dart';
import '../../lib/storage/storage_service.dart';
import '../../lib/services/test_mode_manager.dart';
import '../../lib/services/progress_override.dart';
import '../../lib/services/level_generator.dart';
import '../../lib/services/game_engine.dart';
import '../../lib/services/audio_manager.dart';
import '../../lib/storage/game_progress.dart';

void main() {
  group('DependencyInjection', () {
    setUp(() {
      // Reset the singleton instance before each test
      DependencyInjection.reset();
    });

    tearDown(() {
      // Clean up after each test
      DependencyInjection.reset();
    });

    group('Singleton Behavior', () {
      test('should return same instance', () {
        final instance1 = DependencyInjection.instance;
        final instance2 = DependencyInjection.instance;

        expect(identical(instance1, instance2), isTrue);
      });

      test('should reset singleton for testing', () {
        final instance1 = DependencyInjection.instance;
        
        DependencyInjection.reset();
        
        final instance2 = DependencyInjection.instance;

        expect(identical(instance1, instance2), isFalse);
      });
    });

    group('Dependency Access', () {
      test('should throw exception when accessing dependencies before initialization', () {
        final di = DependencyInjection.instance;

        expect(
          () => di.sharedPreferences,
          throwsA(isA<DependencyInjectionException>()),
        );

        expect(
          () => di.storageService,
          throwsA(isA<DependencyInjectionException>()),
        );

        expect(
          () => di.testModeManager,
          throwsA(isA<DependencyInjectionException>()),
        );
      });
    });

    group('Disposal', () {
      test('should handle disposal when not initialized', () async {
        final di = DependencyInjection.instance;

        // Should not throw when disposing uninitialized instance
        expect(() => di.dispose(), returnsNormally);
      });
    });
  });

  group('DependencyInjectionException', () {
    test('should create exception with message', () {
      const message = 'Test error message';
      final exception = DependencyInjectionException(message);

      expect(exception.message, equals(message));
      expect(exception.cause, isNull);
      expect(exception.toString(), equals('DependencyInjectionException: $message'));
    });

    test('should create exception with message and cause', () {
      const message = 'Test error message';
      final cause = Exception('Root cause');
      final exception = DependencyInjectionException(message, cause);

      expect(exception.message, equals(message));
      expect(exception.cause, equals(cause));
      expect(exception.toString(), contains(message));
      expect(exception.toString(), contains('caused by'));
    });
  });
}