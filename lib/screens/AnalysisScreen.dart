import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({Key? key}) : super(key: key);

  @override
  _AnalysisScreenState createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  final Map<String, String> consumptionPatterns = {
    'consumption_type': '루틴형',
    'time_of_day_pattern': '주로 점심 시간에 소비가 집중됩니다.',
    'consumption_frequency': '매일 일정하게 소비합니다.',
    'category_diversity': '소비하는 카테고리가 몇 가지로 제한되어 있습니다.',
    'weekday_pattern': '특정 요일에만 소비가 이루어집니다.',
  };

  final Map<String, String> trendData = {
    'consumption_trend': '일일 평균 100,485원 → 최근 평균 90,928원 (소비 감소)',
    'consumption_volatility': '70,098원 (다소 변동적)',
    'consumption_trend_ratio': '0.9049 (감소 추세)',
    'weekday_consumption_pattern': '금·월↑, 일·수↓',
    'category_proportion': '쇼핑 50.58%, 식비 24.53%, 문화 9.62%',
    'category_transition_entropy': '11.69 (높은 분산)',
    'predictions': '보수: 999,214원 / 낙관: 1,770,030원',
  };

  final Map<String, String> recommendations = {
    'budget': '예산의 24.76% 사용 (여유롭게 계획하세요)',
    'category_diversity': '쇼핑 비중 높음 → 다른 카테고리도 고려',
    'time_of_day_spending': '밤 시간대 집중 → 분산 필요',
    'cycle_balance': '주기성 불균형 → 일정 패턴 유지 권장',
    'user_group_comparison': '전체 대비 소비 낮음 → 필요 시 여유 고려',
  };

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
    'budget': '예산 사용율',
    'time_of_day_spending': '시간대 소비 추천',
    'cycle_balance': '주기 균형',
    'user_group_comparison': '그룹 비교',
  };

  final List<_ChatEntry> chat = [];
  final ScrollController _scrollController = ScrollController();

  void _addSection(String title, Map<String, String> items) {
    final timestamp = DateTime.now();
    setState(() {
      chat.add(_ChatEntry(isUser: true, text: title, time: timestamp));
      chat.add(_ChatEntry(isUser: false, items: items, time: timestamp));
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('소비 습관 분석'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16.0),
                itemCount: chat.length,
                itemBuilder: (context, index) {
                  final entry = chat[index];
                  final bubbleColor = entry.isUser
                      ? theme.colorScheme.secondary.withOpacity(0.2)
                      : theme.cardColor;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    margin: const EdgeInsets.symmetric(vertical: 6.0),
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: bubbleColor,
                      borderRadius: BorderRadius.circular(16.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(2, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: entry.isUser
                              ? MainAxisAlignment.end
                              : MainAxisAlignment.start,
                          children: [
                            if (!entry.isUser) ...[
                              const Icon(Icons.analytics, size: 20),
                              const SizedBox(width: 8),
                            ],
                            Expanded(
                              child: entry.isUser
                                  ? Text(entry.text!, style: const TextStyle(fontSize: 16.0))
                                  : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: entry.items!.entries.map((e) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Icon(Icons.arrow_right, size: 18, color: theme.primaryColor),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            '${labelMap[e.key] ?? e.key}: ${e.value}',
                                            style: const TextStyle(fontSize: 14.5),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            if (entry.isUser) ...[
                              const SizedBox(width: 8),
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: theme.primaryColor,
                                child: const Icon(Icons.person, size: 16, color: Colors.white),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        Align(
                          alignment: entry.isUser
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Text(
                            DateFormat('HH:mm').format(entry.time),
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const Divider(thickness: 1),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: AnimatedOpacity(
                opacity: 1.0,
                duration: const Duration(milliseconds: 500),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _addSection('기본 패턴', consumptionPatterns),
                      icon: const Icon(Icons.timeline),
                      label: const Text('기본 패턴'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 3,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _addSection('소비 현황', trendData),
                      icon: const Icon(Icons.show_chart),
                      label: const Text('소비 현황'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 3,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _addSection('추천', recommendations),
                      icon: const Icon(Icons.recommend),
                      label: const Text('추천'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatEntry {
  final bool isUser;
  final String? text;
  final Map<String, String>? items;
  final DateTime time;

  _ChatEntry({required this.isUser, this.text, this.items, required this.time});
}
