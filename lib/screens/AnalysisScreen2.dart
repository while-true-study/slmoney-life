import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AnalysisScreen2 extends StatefulWidget {
  const AnalysisScreen2({Key? key}) : super(key: key);

  @override
  _AnalysisScreen2State createState() => _AnalysisScreen2State();
}

class _AnalysisScreen2State extends State<AnalysisScreen2> {
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

  @override
  Widget build(BuildContext context) {
    // 1) 헤더에 쓸 타입 이름
    final String typeName = consumptionPatterns['consumption_type']!;

    // 2) 소비 특징만 뽑아서 새 맵 생성
    final Map<String, String> features = Map.of(consumptionPatterns)
      ..remove('consumption_type');

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ──────────────────────────────────────────
            // 당신의 소비 성향 헤더
            Text(
              '당신의 소비 성향은 $typeName입니다.',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 16),

            // ──────────────────────────────────────────
            // 유형 이미지 (assets 경로에 맞춰 교체)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/images/eco_whale.png',
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 24),

            // ──────────────────────────────────────────
            // 섹션: 소비 특징
            _buildSection('소비 특징', features),
            const SizedBox(height: 24),

            // ──────────────────────────────────────────
            // 섹션: 소비 추세 & 변동성
            _buildSection('소비 추세 & 변동성', trendData),
            const SizedBox(height: 24),

            // ──────────────────────────────────────────
            // 섹션: 맞춤형 추천
            _buildSection('맞춤형 추천', recommendations),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, Map<String, String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 섹션 제목
        Text(
          title,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        // 각 항목을 • 목록으로
        ...items.entries.map((e) {
          final label = labelMap[e.key] ?? e.key;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(fontSize: 16)),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(color: Colors.black87, fontSize: 16),
                      children: [
                        TextSpan(
                          text: '$label: ',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        TextSpan(text: e.value),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }
}
