import 'package:flutter_test/flutter_test.dart';
import 'package:paws_and_found/core/services/user_restriction_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late UserRestrictionService service;
  const testUserId = 'test-user-123';

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    service = const UserRestrictionService();
    await service.clearViolations(testUserId);
  });

  tearDown(() async {
    await service.clearViolations(testUserId);
  });

  group('UserRestrictionService Strike Escalation Tests', () {
    test('initial state has 0 violations and is not suspended', () async {
      expect(await service.getViolationCount(testUserId), 0);
      expect(await service.isUserSuspended(testUserId), isFalse);
      expect(await service.getUserStatus(testUserId), 'Active');
    });

    test('violations 1 and 2 keep status Active without escalation', () async {
      final r1 = await service.recordViolation(userId: testUserId, prohibitedWord: 'buang');
      expect(r1.count, 1);
      expect(r1.status, 'Active');
      expect(r1.isWarning, isFalse);
      expect(r1.isSuspended, isFalse);
      expect(r1.shouldNotify, isFalse);

      final r2 = await service.recordViolation(userId: testUserId, prohibitedWord: 'buang');
      expect(r2.count, 2);
      expect(r2.status, 'Active');
      expect(r2.isWarning, isFalse);
      expect(r2.isSuspended, isFalse);
      expect(r2.shouldNotify, isFalse);
      expect(await service.isUserSuspended(testUserId), isFalse);
    });

    test('violations 3 and 4 escalate status to Warning', () async {
      await service.recordViolation(userId: testUserId, prohibitedWord: 'buang');
      await service.recordViolation(userId: testUserId, prohibitedWord: 'buang');

      final r3 = await service.recordViolation(userId: testUserId, prohibitedWord: 'yawa');
      expect(r3.count, 3);
      expect(r3.status, 'Warning');
      expect(r3.isWarning, isTrue);
      expect(r3.isSuspended, isFalse);
      expect(r3.shouldNotify, isTrue);
      expect(await service.getUserStatus(testUserId), 'Warning');
      expect(await service.isUserSuspended(testUserId), isFalse);

      final r4 = await service.recordViolation(userId: testUserId, prohibitedWord: 'piste');
      expect(r4.count, 4);
      expect(r4.status, 'Warning');
      expect(r4.isWarning, isTrue);
      expect(r4.isSuspended, isFalse);
      expect(await service.isUserSuspended(testUserId), isFalse);
    });

    test('violation 5 escalates status to Suspended and locks account', () async {
      for (int i = 0; i < 4; i++) {
        await service.recordViolation(userId: testUserId, prohibitedWord: 'buang');
      }

      final r5 = await service.recordViolation(userId: testUserId, prohibitedWord: 'buang');
      expect(r5.count, 5);
      expect(r5.status, 'Suspended');
      expect(r5.isSuspended, isTrue);
      expect(r5.isWarning, isFalse);
      expect(r5.shouldNotify, isTrue);

      expect(await service.getUserStatus(testUserId), 'Suspended');
      expect(await service.isUserSuspended(testUserId), isTrue);
    });
  });
}
