import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({Key? key}) : super(key: key);

  @override
  _AnalysisScreenState createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  static const _uuidChannel = MethodChannel('moneymanager/uuid');

  String? _uuid;
  final List<_ChatEntry> chat = [];
  final ScrollController _scrollController = ScrollController();

  final Map<String, String> _endpoints = {
    '패턴 분석해줘': 'http://27.117.255.218:8000/GetConsumerBehaviorAnalyzer',
    '소비 현황 알려줘': 'http://27.117.255.218:8000/GetConsumptionPredictionAnalyzer',
    '어떻게 할까?': 'http://27.117.255.218:8000/GetAdviceAnalyzer',
  };

  @override
  void initState() {
    super.initState();
    _loadUuid();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final now = DateTime.now();
      setState(() {
        chat.add(_ChatEntry(
          isUser: false,
          text: '무엇을 도와드릴까요?',
          items: null,
          time: now,
        ));
      });
    });
  }

  Future<void> _loadUuid() async {
    try {
      final id = await _uuidChannel.invokeMethod<String>('getDeviceUuid');
      setState(() => _uuid = id);
    } on PlatformException catch (e) {
      debugPrint('UUID 로드 실패: ${e.message}');
    }
  }

  Future<Map<String, String>> _postToApi(String url) async {
    if (_uuid == null) throw Exception('UUID 미설정');
    final now = DateTime.now();
    final body = json.encode({
      'uuid': _uuid,
      'date': DateFormat('yyyy-MM-dd').format(now),
    });

    final res = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: body,
    );
    if (res.statusCode != 200) {
      throw Exception('서버 에러: ${res.statusCode}');
    }
    final data = json.decode(res.body) as Map<String, dynamic>;

    return data.map((k, v) {
      if (v is List) {
        return MapEntry(k, v.join('\n'));
      } else {
        return MapEntry(k, v.toString());
      }
    });
  }

  Future<void> _handleButton(String title) async {
    final now = DateTime.now();
    setState(() {
      // 사용자 메시지
      chat.add(_ChatEntry(isUser: true, text: title, items: null, time: now));
      // 로딩 표시
      chat.add(_ChatEntry(isUser: false, text: null, items: {}, time: now));
    });

    try {
      final result = await _postToApi(_endpoints[title]!);
      setState(() {
        // 로딩 항목 대체
        chat[chat.length - 1] =
            _ChatEntry(isUser: false, text: null, items: result, time: now);
      });
    } catch (e) {
      setState(() {
        chat[chat.length - 1] = _ChatEntry(
          isUser: false,
          text: '에러: ${e.toString()}',
          items: null,
          time: now,
        );
      });
    }

    // 자동 스크롤
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  final Map<String, String> labelMap = {
    'consumption_type': '소비 유형',
    'time_of_day_pattern': '시간대 패턴',
    'consumption_frequency': '소비 빈도',
    'category_diversity': '카테고리 다양성',
    'weekday_pattern': '요일 패턴',
    'consumption_trend': '소비 추세',
    'consumption_volatility': '소비 변동성',
    'consumption_trend_ratio': '추세 비율',
    'weekday_consumption_pattern': '요일별 소비',
    'category_proportion': '카테고리 비율',
    'category_transition_entropy': '카테고리 다양성',
    'predictions': '예측',
    'summary': '요약',
    'budget': '예산 사용율',
    'time_of_day_spending': '시간대 소비 추천',
    'cycle_balance': '주기 균형',
    'user_group_comparison': '그룹 비교',
  };

  Widget _buildBubble(_ChatEntry entry) {
    final theme = Theme.of(context);
    final isUser = entry.isUser;
    final bgColor = isUser ? const Color(0xFFFFE500) : Colors.white;
    final radius = isUser
        ? const BorderRadius.only(
      topLeft: Radius.circular(16),
      topRight: Radius.circular(16),
      bottomLeft: Radius.circular(16),
    )
        : const BorderRadius.only(
      topLeft: Radius.circular(16),
      topRight: Radius.circular(16),
      bottomRight: Radius.circular(16),
    );

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
        isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: CircleAvatar(radius: 14),
            ),
          Flexible(
            child: Column(
              crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Text(
                  isUser ? '나' : '도우미',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isUser ? theme.primaryColor : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: radius,
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 2,
                        offset: Offset(1, 1),
                      )
                    ],
                  ),
                  child: entry.items == null
                  // 텍스트 메시지
                      ? Text(entry.text!, style: const TextStyle(fontSize: 15))
                  // 로딩 인디케이터
                      : entry.items!.isEmpty
                      ? const SizedBox(
                    width: 16,
                    height: 16,
                    child:
                    CircularProgressIndicator(strokeWidth: 2),
                  )
                  // 키-값 리스트
                      : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: entry.items!.entries.map((e) {
                      final isSummary = e.key == 'summary';
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 4),
                        child: Text(
                          '${labelMap[e.key] ?? e.key}: ${e.value}',
                          style: TextStyle(
                            fontSize: isSummary ? 13 : 14,
                            fontStyle: isSummary
                                ? FontStyle.italic
                                : FontStyle.normal,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('HH:mm').format(entry.time),
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),
          if (isUser)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: CircleAvatar(
                radius: 14,
                backgroundColor: theme.primaryColor,
                child: const Icon(Icons.person,
                    size: 16, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: chat.length,
              itemBuilder: (_, i) => _buildBubble(chat[i]),
            ),
          ),
          const Divider(thickness: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              children: _endpoints.keys.map((title) {
                return ActionChip(
                  label: Text(title),
                  onPressed: () => _handleButton(title),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatEntry {
  final bool isUser;
  final String? text;
  final Map<String, String>? items;
  final DateTime time;

  _ChatEntry({
    required this.isUser,
    this.text,
    this.items,
    required this.time,
  });
}
