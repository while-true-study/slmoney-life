import 'package:flutter/material.dart';
import 'package:moneymanager/screens/SummaryScreen.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';

import 'models/Transaction.dart';
import 'providers/TransactionProvider.dart';
import 'screens/CalendarScreen.dart';
import 'screens/AnalysisScreen.dart';
import 'screens/PredictionScreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('ko_KR', null);
  await Hive.initFlutter();
  Hive.registerAdapter(TransactionAdapter());
  await Hive.openBox<Transaction>('transactions');

  // Awesome Notifications 초기화
  await AwesomeNotifications().initialize(
    null,
    [
      NotificationChannel(
        channelKey: 'basic_channel',
        channelName: '기본 채널',
        channelDescription: '기본 알림 채널',
        defaultColor: Color(0xFF9D50DD),
        ledColor: Colors.white,
        importance: NotificationImportance.High,
      ),
    ],
    debug: true,
  );

  // 일반 알림 권한 요청
  bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
  if (!isAllowed) {
    await AwesomeNotifications().requestPermissionToSendNotifications();
  }

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    CalendarScreen(),
    SummaryScreen(),
    AnalysisScreen(),

  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // 알림 접근 권한 안내 다이얼로그
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationPermissionChecker.checkAndRequestPermission(context);
    });

  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<TransactionProvider>(
      create: (_) => TransactionProvider()..loadTransactions(),
      child: MaterialApp(
        title: 'AI 가계부',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: Scaffold(
          appBar: AppBar(title: Text('AI 가계부')),
          body: Consumer<TransactionProvider>(
            builder: (context, provider, child) {
              if (!provider.isLoaded) {
                return Center(child: CircularProgressIndicator());
              }
              return _screens[_selectedIndex];
            },
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: '캘린더'),
              BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: '요약'),
              BottomNavigationBarItem(icon: Icon(Icons.analytics), label: '분석'),
            ],
          ),
        ),
      ),
    );
  }

}

// 알림 접근 권한 다이얼로그 클래스
class NotificationPermissionChecker {
  static Future<void> checkAndRequestPermission(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final alreadyAsked = prefs.getBool('notification_permission_asked') ?? false;

    if (alreadyAsked) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('알림 접근 권한 필요'),
        content: Text('이 앱은 다른 앱의 알림을 받아야 작동합니다.\n설정에서 권한을 허용해 주세요.'),
        actions: [
          TextButton(
            onPressed: () async {
              // 설정으로 이동
              final intent = AndroidIntent(
                action: 'android.settings.ACTION_NOTIFICATION_LISTENER_SETTINGS',
                flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
              );
              await intent.launch();

              prefs.setBool('notification_permission_asked', true);
              Navigator.of(context).pop();
            },
            child: Text('설정으로 이동'),
          ),
        ],
      ),
    );
  }
}
