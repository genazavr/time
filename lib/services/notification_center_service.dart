import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

import '../models/user_notification.dart';
import 'firebase_service.dart';
import 'notification_service.dart';

class NotificationCenterService {
  NotificationCenterService._internal();

  static final NotificationCenterService _instance = NotificationCenterService._internal();
  factory NotificationCenterService() => _instance;

  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final NotificationService _localNotifications = NotificationService();

  StreamSubscription<DatabaseEvent>? _newNotificationSubscription;
  String? _activeUserId;
  final Set<String> _deliveredNotifications = <String>{};

  Stream<List<UserNotification>> watchNotifications() {
    final userId = _firebaseService.getCurrentUser()?.uid;
    if (userId == null) {
      return Stream<List<UserNotification>>.value(const <UserNotification>[]);
    }

    final ref = _database.ref('users/$userId/notifications');
    return ref.onValue.map((event) {
      final notifications = _parseNotifications(event);
      notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return notifications;
    });
  }

  Future<void> start(String userId) async {
    if (_activeUserId == userId && _newNotificationSubscription != null) {
      return;
    }

    await stop();

    _activeUserId = userId;
    final ref = _database.ref('users/$userId/notifications');

    _newNotificationSubscription = ref.onChildAdded.listen((event) async {
      final notification = _mapNotification(event);
      if (notification == null) return;

      if (notification.isRead || notification.deliveredAt != null) {
        _deliveredNotifications.add(notification.id);
        return;
      }

      if (_deliveredNotifications.contains(notification.id)) {
        return;
      }

      _deliveredNotifications.add(notification.id);

      try {
        await _localNotifications.showImmediateNotification(
          id: notification.localId,
          title: notification.title,
          body: notification.message,
          payload: notification.action,
        );
        await _markDelivered(userId, notification.id);
      } catch (error, stackTrace) {
        debugPrint('Failed to display notification: $error');
        debugPrint('$stackTrace');
      }
    });
  }

  Future<void> stop() async {
    if (_newNotificationSubscription != null) {
      await _newNotificationSubscription!.cancel();
      _newNotificationSubscription = null;
    }
    _activeUserId = null;
    _deliveredNotifications.clear();
  }

  Future<void> markAsRead(String notificationId) async {
    final userId = _firebaseService.getCurrentUser()?.uid;
    if (userId == null) return;

    await _database.ref('users/$userId/notifications/$notificationId').update({
      'isRead': true,
      'readAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> markAllAsRead() async {
    final userId = _firebaseService.getCurrentUser()?.uid;
    if (userId == null) return;

    final snapshot = await _database.ref('users/$userId/notifications').get();
    if (!snapshot.exists) return;

    final futures = <Future<void>>[];
    final nowIso = DateTime.now().toIso8601String();

    if (snapshot.value is Map) {
      final map = Map<dynamic, dynamic>.from(snapshot.value as Map);
      for (final entry in map.entries) {
        final data = entry.value;
        final isRead = data is Map ? data['isRead'] as bool? ?? false : false;
        if (!isRead) {
          futures.add(
            _database.ref('users/$userId/notifications/${entry.key}').update({
                  'isRead': true,
                  'readAt': nowIso,
                }),
          );
        }
      }
    } else if (snapshot.value is List) {
      final list = List<dynamic>.from(snapshot.value as List);
      for (var index = 0; index < list.length; index++) {
        final data = list[index];
        final isRead = data is Map ? data['isRead'] as bool? ?? false : false;
        if (!isRead) {
          futures.add(
            _database.ref('users/$userId/notifications/$index').update({
                  'isRead': true,
                  'readAt': nowIso,
                }),
          );
        }
      }
    }

    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }
  }

  Future<void> addNotification(UserNotification notification) async {
    final userId = _firebaseService.getCurrentUser()?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    await _database
        .ref('users/$userId/notifications/${notification.id}')
        .set(notification.toMap());
  }

  List<UserNotification> _parseNotifications(DatabaseEvent event) {
    final value = event.snapshot.value;
    final notifications = <UserNotification>[];

    if (value is Map) {
      value.forEach((key, raw) {
        final notification = _mapNotificationEntry(key.toString(), raw);
        if (notification != null) {
          notifications.add(notification);
        }
      });
    } else if (value is List) {
      for (var index = 0; index < value.length; index++) {
        final raw = value[index];
        final notification = _mapNotificationEntry(index.toString(), raw);
        if (notification != null) {
          notifications.add(notification);
        }
      }
    }

    return notifications;
  }

  UserNotification? _mapNotification(DatabaseEvent event) {
    final key = event.snapshot.key;
    if (key == null) return null;
    return _mapNotificationEntry(key, event.snapshot.value);
  }

  UserNotification? _mapNotificationEntry(String id, dynamic raw) {
    if (raw is Map) {
      try {
        final data = Map<String, dynamic>.from(raw);
        return UserNotification.fromMap(data, id);
      } catch (error, stackTrace) {
        debugPrint('Unable to parse notification $id: $error');
        debugPrint('$stackTrace');
      }
    }
    return null;
  }

  Future<void> _markDelivered(String userId, String notificationId) async {
    await _database
        .ref('users/$userId/notifications/$notificationId')
        .update({'deliveredAt': DateTime.now().toIso8601String()});
  }
}
