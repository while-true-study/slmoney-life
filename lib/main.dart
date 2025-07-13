import 'package:flutter/material.dart';
import 'package:moneymanager/screens/AnalysisScreen2.dart';
import 'package:moneymanager/screens/SummaryScreen.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';

import 'models/transaction.dart';
import 'providers/TransactionProvider.dart';
import 'screens/CalendarScreen.dart';
import 'screens/AnalysisScreen.dart';
import 'screens/PredictionScreen.dart';
import 'providers/CategoryColorProvider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 로케일 초기화
  await initializeDateFormatting('ko_KR', null);

  // Hive 초기화 & 어댑터 등록
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
        defaultColor: Color(0xFF9D50ad),
        ledColor: Colors.white,
        importance: NotificationImportance.High,
      ),
    ],
    debug: true,
  );

  // 권한 요청
  if (!await AwesomeNotifications().isNotificationAllowed()) {
    await AwesomeNotifications().requestPermissionToSendNotifications();
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _selectedIndex = 0;
  final List<Widget> _screens = [
    CalendarScreen(),
    SummaryScreen(),
    AnalysisScreen(),
    // AnalysisScreen2()
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationPermissionChecker.checkAndRequestPermission(context);
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // TransactionProvider가 생성되며
        // 자동으로 Hive 로드 & 네이티브 알림 스트림을 구독합니다.
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => CategoryColorProvider()..loadColors()),
      ],
      child: MaterialApp(
        title: 'AI 가계부',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: Scaffold(
          appBar: AppBar(title: const Text('AI 가계부')),
          body: Consumer<TransactionProvider>(
            builder: (context, provider, child) {
              if (!provider.isLoaded) {
                return const Center(child: CircularProgressIndicator());
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

class NotificationPermissionChecker {
  static Future<void> checkAndRequestPermission(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('notification_permission_asked') == true) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('알림 접근 권한 필요'),
        content: const Text('이 앱은 다른 앱의 알림을 받아야 작동합니다.\n설정에서 권한을 허용해 주세요.'),
        actions: [
          TextButton(
            onPressed: () async {
              await AndroidIntent(
                action: 'android.settings.ACTION_NOTIFICATION_LISTENER_SETTINGS',
                flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
              ).launch();
              await prefs.setBool('notification_permission_asked', true);
              Navigator.of(context).pop();
            },
            child: const Text('설정으로 이동'),
          ),
        ],
      ),
    );
  }
}