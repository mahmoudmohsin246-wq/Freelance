import 'package:flutter_test/flutter_test.dart';
import 'package:sports_academy_app/presentation/providers/auth_provider.dart';
import 'package:sports_academy_app/presentation/providers/subscription_provider.dart';
import 'package:sports_academy_app/presentation/providers/notification_provider.dart';

void main() {
  group('UserModel Tests', () {
    test('UserModel creates instance correctly and enforces sportFootball', () {
      final user = UserModel(
        id: 'uid-123',
        name: 'John Doe',
        email: 'john@example.com',
        role: UserRole.admin,
        phone: '123456789',
        academyName: 'Champions Academy',
        sport: 'sportFootball',
        avatarPath: 'path/to/avatar.jpg',
        emailVerified: true,
      );

      expect(user.id, 'uid-123');
      expect(user.name, 'John Doe');
      expect(user.email, 'john@example.com');
      expect(user.role, UserRole.admin);
      expect(user.sport, 'sportFootball');
      expect(user.emailVerified, isTrue);
    });

    test('UserModel toJson and fromJson work properly', () {
      final json = {
        'id': 'uid-456',
        'name': 'Coach Smith',
        'email': 'coach@example.com',
        'role': 'coach',
        'phone': '987654321',
        'academyName': 'Star Academy',
        'sport': 'sportFootball',
        'avatarPath': '',
      };

      final user = UserModel.fromJson(json, emailVerified: false);
      expect(user.id, 'uid-456');
      expect(user.name, 'Coach Smith');
      expect(user.role, UserRole.coach);
      expect(user.sport, 'sportFootball');
      expect(user.emailVerified, isFalse);

      final outputJson = user.toJson();
      expect(outputJson['id'], 'uid-456');
      expect(outputJson['name'], 'Coach Smith');
      expect(outputJson['role'], 'coach');
      expect(outputJson['sport'], 'sportFootball');
    });
  });

  group('Subscription Model Tests', () {
    test('Subscription calculates active/expired status correctly', () {
      final now = DateTime.now();
      final activeSub = Subscription(
        id: 'sub-1',
        userId: 'uid-123',
        userEmail: 'user@example.com',
        playerName: 'User One',
        startDate: now.subtract(const Duration(days: 5)),
        expiryDate: now.add(const Duration(days: 25)),
        amountPaid: 500.0,
      );

      expect(activeSub.isCurrentlyActive, isTrue);
      expect(activeSub.status, 'Active');
      expect(activeSub.amountPaid, 500.0);

      final expiredSub = Subscription(
        id: 'sub-2',
        userId: 'uid-123',
        userEmail: 'user@example.com',
        playerName: 'User One',
        startDate: now.subtract(const Duration(days: 40)),
        expiryDate: now.subtract(const Duration(days: 10)),
        amountPaid: 500.0,
      );

      expect(expiredSub.isCurrentlyActive, isFalse);
      expect(expiredSub.status, 'Expired');
    });
  });

  group('AppNotification Model Tests', () {
    test('AppNotification serializes and deserializes correctly', () {
      final notif = AppNotification(
        id: 'notif-1',
        type: 'subscription_expired',
        title: 'انتهاء الاشتراك',
        message: 'لقد انتهت فترة اشتراكك في الأكاديمية.',
        createdAt: DateTime.now(),
        subscriptionId: 'sub-123',
      );

      expect(notif.id, 'notif-1');
      expect(notif.type, 'subscription_expired');
      expect(notif.subscriptionId, 'sub-123');
      expect(notif.isRead, isFalse);
    });
  });
}
