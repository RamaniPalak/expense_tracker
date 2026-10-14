import 'package:flutter_test/flutter_test.dart';

/// Test class reproducing the guarded reload pattern used in HomeContent.
class HomeContentReloadGuard {
  String? userEmail;
  String? userName;
  bool isReloadingName = false;
  int setStateCallCount = 0;

  Future<void> reloadUserName(Future<String?> Function() fetchName) async {
    if (isReloadingName) return;
    isReloadingName = true;
    try {
      final name = await fetchName();
      if (name != userName) {
        setStateCallCount++;
        userName = name;
      }
    } finally {
      isReloadingName = false;
    }
  }

  Future<void> loadUserAndData(
    Future<String?> Function() fetchEmail,
    Future<String?> Function() fetchName,
  ) async {
    final email = await fetchEmail();
    final name = await fetchName();
    if (userEmail != email || userName != name) {
      setStateCallCount++;
      userEmail = email;
      userName = name;
    }
  }
}

void main() {
  group('HomeContent didChangeDependencies Guard Tests', () {
    late HomeContentReloadGuard guard;

    setUp(() {
      guard = HomeContentReloadGuard();
      guard.userName = 'Palak';
      guard.userEmail = 'palak@example.com';
    });

    test(
        'didChangeDependencies does NOT trigger setState if user name is unchanged',
        () async {
      expect(guard.setStateCallCount, 0);

      // Simulate tab switch or theme change triggering didChangeDependencies
      await guard.reloadUserName(() async => 'Palak');

      expect(guard.setStateCallCount, 0); // No setState triggered!
      expect(guard.userName, 'Palak');
    });

    test(
        'didChangeDependencies triggers setState when user name actually changes',
        () async {
      expect(guard.setStateCallCount, 0);

      // User changed their name in profile screen
      await guard.reloadUserName(() async => 'Palak Ramani');

      expect(guard.setStateCallCount, 1);
      expect(guard.userName, 'Palak Ramani');

      // Subsequent tab switches with the new name do not trigger further setState calls
      await guard.reloadUserName(() async => 'Palak Ramani');
      expect(guard.setStateCallCount, 1);
    });

    test(
        'loadUserAndData avoids redundant setState if credentials already match',
        () async {
      expect(guard.setStateCallCount, 0);

      await guard.loadUserAndData(
        () async => 'palak@example.com',
        () async => 'Palak',
      );

      expect(guard.setStateCallCount, 0);
    });

    test('Concurrent reload calls are safely coalesced by isReloadingName flag',
        () async {
      int fetchCalls = 0;

      final future1 = guard.reloadUserName(() async {
        fetchCalls++;
        await Future.delayed(const Duration(milliseconds: 20));
        return 'Updated Name';
      });

      final future2 = guard.reloadUserName(() async {
        fetchCalls++;
        return 'Updated Name';
      });

      await Future.wait([future1, future2]);

      expect(fetchCalls, 1); // Second call returned early!
      expect(guard.setStateCallCount, 1);
      expect(guard.userName, 'Updated Name');
    });
  });
}
