import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:http/http.dart' as http;

class NotificationHandler extends StatefulWidget {
  @override
  _NotificationHandlerState createState() => _NotificationHandlerState();
}

class _NotificationHandlerState extends State<NotificationHandler> {
  static const platform = MethodChannel('notification_channel');

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  Future<void> _startListening() async {
    const eventChannel = EventChannel("notification_event_channel");

    eventChannel.receiveBroadcastStream().listen((event) {
      final title = event['title'];
      final text = event['text'];
      final pkg = event['package'];

      print("알림 수신: $title / $text");

      _sendToBackend(title, text);
    });
  }

  Future<void> _sendToBackend(String title, String text) async {
    final response = await http.post(
      Uri.parse('https://your-backend-api.com/notifications'),
      body: {
        "title": title,
        "text": text,
      },
    );

    print("전송 상태: ${response.statusCode}");
  }

  @override
  Widget build(BuildContext context) {
    return Container(); // UI 없음, 백그라운드 전용
  }
}
