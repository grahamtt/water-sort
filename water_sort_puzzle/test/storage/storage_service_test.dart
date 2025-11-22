import 'package:flutter_test/flutter_test.dart';
import 'package:water_sort_puzzle/storage/storage_service.dart';

void main() {
  group('StorageService', () {
    late StorageService storageService;
    
    setUp(() {
      storageService = StorageService();
    });
    
    group('error handling', () {
      test('should throw StorageException with meaningful messages', () {
        final exception = StorageException('Test error', 'Test cause');
        
        expect(exception.message, equals('Test error'));
        expect(exception.cause, equals('Test cause'));
        expect(exception.toString(), contains('Test error'));
        expect(exception.toString(), contains('Test cause'));
      });
      
      test('should handle StorageException without cause', () {
        final exception = StorageException('Test error');
        
        expect(exception.message, equals('Test error'));
        expect(exception.cause, isNull);
        expect(exception.toString(), contains('Test error'));
        expect(exception.toString(), isNot(contains('Cause:')));
      });
      
      test('should throw exception when not initialized', () async {
        expect(
          () => storageService.getGameProgress(),
          throwsA(isA<StorageException>()),
        );
      });
    });
    
    group('close operations', () {
      test('should handle close when not initialized', () async {
        // Should not throw
        await storageService.close();
        
        // Should still throw when trying to use it
        expect(
          () => storageService.getGameProgress(),
          throwsA(isA<StorageException>()),
        );
      });
    });
  });
}