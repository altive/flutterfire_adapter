import 'dart:async';

import 'package:altfire_messenger/altfire_messenger.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFirebaseMessaging extends Mock implements FirebaseMessaging {}

class MockNotificationSettings extends Mock implements NotificationSettings {}

class MockRemoteMessage extends Mock implements RemoteMessage {}

class MockFlutterLocalNotificationsPlugin extends Mock
    implements FlutterLocalNotificationsPlugin {}

class MockNotificationResponse extends Mock implements NotificationResponse {}

void main() {
  group('Messenger', () {
    setUpAll(() {
      registerFallbackValue(
        InitializationSettings(
          android: AndroidInitializationSettings(''),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
      );
    });

    test(
        'requestPermission should call '
        'setForegroundNotificationPresentationOptions and '
        'requestPermission on messaging', () async {
      final messaging = MockFirebaseMessaging();
      final messenger = Messenger(messaging: messaging);
      final settings = MockNotificationSettings();

      when(
        () => messaging.setForegroundNotificationPresentationOptions(
          alert: any(named: 'alert'),
          badge: any(named: 'badge'),
          sound: any(named: 'sound'),
        ),
      ).thenAnswer((_) async {});
      when(messaging.requestPermission).thenAnswer((_) async => settings);

      final got = await messenger.requestPermission();

      expect(got, settings);

      verify(
        () => messaging.setForegroundNotificationPresentationOptions(
          alert: any(named: 'alert'),
          badge: any(named: 'badge'),
          sound: any(named: 'sound'),
        ),
      ).called(1);
      verify(messaging.requestPermission).called(1);
    });

    test(
        'getNotificationSettings should call getNotificationSettings on messaging',
        () async {
      final messaging = MockFirebaseMessaging();
      final messenger = Messenger(messaging: messaging);
      final settings = MockNotificationSettings();

      when(messaging.getNotificationSettings).thenAnswer((_) async => settings);

      final got = await messenger.getNotificationSettings();

      expect(got, settings);

      verify(messaging.getNotificationSettings).called(1);
    });

    test('getInitialMessage should call getInitialMessage on messaging',
        () async {
      final messaging = MockFirebaseMessaging();
      final messenger = Messenger(messaging: messaging);
      final message = MockRemoteMessage();

      when(messaging.getInitialMessage).thenAnswer((_) async => message);

      final got = await messenger.getInitialMessage();

      expect(got, message);

      verify(messaging.getInitialMessage).called(1);
    });

    test('getToken should call getToken on messaging', () async {
      final messaging = MockFirebaseMessaging();
      final messenger = Messenger(messaging: messaging);
      const token = 'test_token';

      when(messaging.getToken).thenAnswer((_) async => token);

      final got = await messenger.getToken();

      expect(got, token);

      verify(messaging.getToken).called(1);
    });

    test('subscribeToTopic should call subscribeToTopic on messaging',
        () async {
      final messaging = MockFirebaseMessaging();
      final messenger = Messenger(messaging: messaging);
      const topic = 'test_topic';

      when(() => messaging.subscribeToTopic(any())).thenAnswer((_) async {});

      await messenger.subscribeToTopic(topic);

      verify(() => messaging.subscribeToTopic(topic)).called(1);
    });

    test('initializeNotifications should initialize notifications correctly',
        () async {
      final messaging = MockFirebaseMessaging();
      final notifications = MockFlutterLocalNotificationsPlugin();
      final messenger = Messenger(
        messaging: messaging,
        notifications: notifications,
      );

      when(() => notifications.initialize(
            any(),
            onDidReceiveNotificationResponse:
                any(named: 'onDidReceiveNotificationResponse'),
          )).thenAnswer((_) async => true);

      await messenger.initializeNotifications(
        androidDefaultIcon: 'test_icon',
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      verify(
        () => notifications.initialize(
          any(
            that: predicate((InitializationSettings settings) =>
                settings.android?.defaultIcon == 'test_icon' &&
                settings.iOS?.requestAlertPermission == true &&
                settings.iOS?.requestBadgePermission == true &&
                settings.iOS?.requestSoundPermission == true),
          ),
          onDidReceiveNotificationResponse:
              any(named: 'onDidReceiveNotificationResponse'),
        ),
      ).called(1);
    });

    test('onForegroundNotificationTapped should handle payload correctly',
        () async {
      final messaging = MockFirebaseMessaging();
      final notifications = MockFlutterLocalNotificationsPlugin();
      final messenger = Messenger(
        messaging: messaging,
        notifications: notifications,
      );
      final mockResponse = MockNotificationResponse();
      final mockPayload = '{"key": "value"}';

      when(() => mockResponse.payload).thenReturn(mockPayload);

      final completer = Completer<Map<String, dynamic>>();

      messenger.onForegroundNotificationTapped(
        notificationResponse: mockResponse,
        onNotificationTapped: (map) {
          completer.complete(map);
        },
      );

      final result = await completer.future;
      expect(result, {'key': 'value'});
    });

    test('showNotification should call show on notifications', () async {
      final messaging = MockFirebaseMessaging();
      final notifications = MockFlutterLocalNotificationsPlugin();
      final messenger = Messenger(
        messaging: messaging,
        notifications: notifications,
      );

      when(() => notifications.show(
            any(),
            any(),
            any(),
            any(),
            payload: any(named: 'payload'),
          )).thenAnswer((_) async {});

      await messenger.showNotification(
        channelId: 'test_channel',
        channelName: 'Test Channel',
        channelDescription: 'Test Description',
        icon: 'test_icon',
        color: const Color(0xFF000000),
        id: 1,
        title: 'Test Title',
        body: 'Test Body',
        payloadJsonMap: {'key': 'value'},
      );

      verify(() => notifications.show(
            1,
            'Test Title',
            'Test Body',
            any(),
            payload: any(named: 'payload'),
          )).called(1);
    });
  });
}
