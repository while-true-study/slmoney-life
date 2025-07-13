import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../providers/TransactionProvider.dart';
import '../models/transaction.dart';

class SummaryScreen extends StatefulWidget {
  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  final formatter = NumberFormat('#,###원');
  DateTime selectedMonth = DateTime.now();
  final Random random = Random();

  Color getRandomColor() {
    return Color.fromARGB(
      255,
      random.nextInt(200) + 30,
      random.nextInt(200) + 30,
      random.nextInt(200) + 30,
    );
  }

  Widget buildPieChart(String type, List<Transaction> transactions) {
    final filtered = transactions.where((tx) => tx.type == type).toList();
    final Map<String, int> categoryTotals = {};
    for (var tx in filtered) {
      categoryTotals[tx.category] =
          (categoryTotals[tx.category] ?? 0) + tx.amount.abs();
    }
    if (categoryTotals.isEmpty) return Text('$type 데이터 없음');

    final total = categoryTotals.values.fold(0, (sum, val) => sum + val);
    final categoryColors = {for (var key in categoryTotals.keys) key: getRandomColor()};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('카테고리별 $type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        AspectRatio(
          aspectRatio: 1.3,
          child: PieChart(
            PieChartData(
              centerSpaceRadius: 40,
              sections: categoryTotals.entries.map((entry) {
                final percent = (entry.value / total * 100).toStringAsFixed(0);
                return PieChartSectionData(
                  value: entry.value.toDouble(),
                  title: '$percent%',
                  color: categoryColors[entry.key],
                  radius: 50,
                  titleStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                );
              }).toList(),
            ),
          ),
        ),
        ...categoryTotals.entries.map((entry) {
          final percent = (entry.value / total * 100).toStringAsFixed(0);
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: categoryColors[entry.key],
              child: Text('$percent%', style: TextStyle(fontSize: 12, color: Colors.white)),
            ),
            title: Text(entry.key),
            subtitle: Text('금액 ${formatter.format(entry.value)}'),
          );
        }).toList(),
      ],
    );
  }

  Widget buildCombinedLineChart(List<Transaction> transactions) {
    final days = DateTime(selectedMonth.year, selectedMonth.month + 1, 0).day;
    final income = List<double>.filled(days, 0);
    final expense = List<double>.filled(days, 0);

    // 일별 수입·지출 집계
    for (var tx in transactions) {
      if (tx.date.year == selectedMonth.year && tx.date.month == selectedMonth.month) {
        if (tx.type == '수입') {
          income[tx.date.day - 1] += tx.amount.toDouble();
        } else if (tx.type == '지출') {
          expense[tx.date.day - 1] += tx.amount.abs().toDouble();
        }
      }
    }

    // Y축 20만원 단위 설정
    const double step = 200000.0;
    // 실제 최대값을 20만원 배수로 올림
    final rawMax = [...income, ...expense].fold(0.0, (a, b) => a > b ? a : b);
    final double maxY = rawMax == 0 ? step : (rawMax / step).ceil() * step;

    final spotsIncome = List<FlSpot>.generate(days, (i) => FlSpot(i + 1.0, income[i]));
    final spotsExpense = List<FlSpot>.generate(days, (i) => FlSpot(i + 1.0, expense[i]));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('일별 수입·지출 (Line)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        AspectRatio(
          aspectRatio: 1.7,
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: maxY,
              gridData: FlGridData(show: true),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 5,
                    getTitlesWidget: (v, _) =>
                        Text('${v.toInt()}일', style: TextStyle(fontSize: 10)),
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: step,
                    reservedSize: 40,
                    getTitlesWidget: (v, _) {
                      final danwi = (v / 10000).toInt();
                      return Text(
                      v == 0 ? '0' : '${danwi}만',
                      style: TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spotsIncome,
                  isCurved: false,
                  barWidth: 2,
                  color: Colors.blue,
                  dotData: FlDotData(show: false),
                ),
                LineChartBarData(
                  spots: spotsExpense,
                  isCurved: false,
                  barWidth: 2,
                  color: Colors.redAccent,
                  dotData: FlDotData(show: false),
                ),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  tooltipBgColor: Colors.grey.shade700,
                  getTooltipItems: (spots) => spots.map((s) {
                    final day = s.x.toInt();
                    final amount = s.y.toInt();
                    return LineTooltipItem(
                      '$day일\n${formatter.format(amount)}',
                      TextStyle(color: Colors.white),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }


  Widget buildBarChart(List<Transaction> transactions) {
    final days = DateTime(selectedMonth.year, selectedMonth.month + 1, 0).day;
    final income = List<double>.filled(days, 0);
    final expense = List<double>.filled(days, 0);

    // 일별 수입·지출 집계
    for (var tx in transactions) {
      if (tx.date.year == selectedMonth.year && tx.date.month == selectedMonth.month) {
        if (tx.type == '수입') {
          income[tx.date.day - 1] += tx.amount.toDouble();
        } else if (tx.type == '지출') {
          expense[tx.date.day - 1] += tx.amount.abs().toDouble();
        }
      }
    }

    // Y축 10만원 단계 설정 (원하는 단위로 조정 가능)
    const double step = 100000;
    // 실제 최대값을 10만원 배수로 올림
    final rawMax = [...income, ...expense].fold(0.0, (a, b) => a > b ? a : b);
    final double maxY = rawMax == 0 ? step : (rawMax / step).ceil() * step;

    // BarChart 그룹 생성
    final groups = List<BarChartGroupData>.generate(days, (i) {
      return BarChartGroupData(
        x: i + 1,
        barRods: [
          BarChartRodData(toY: income[i], color: Colors.blue, width: 6),
          BarChartRodData(toY: expense[i], color: Colors.redAccent, width: 6),
        ],
        barsSpace: 4,
      );
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('일별 수입·지출 (Bar)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        AspectRatio(
          aspectRatio: 1.7,
          child: BarChart(
            BarChartData(
              minY: 0,
              maxY: maxY,
              barGroups: groups,
              gridData: FlGridData(show: true),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 5,
                    getTitlesWidget: (v, _) => v.toInt() % 5 == 0
                        ? Text('${v.toInt()}일', style: TextStyle(fontSize: 10))
                        : const SizedBox.shrink(),
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: step,
                    reservedSize: 40,
                    getTitlesWidget: (v, _) {
                      final mandan = (v / 10000).toInt();
                      return Text(
                      v == 0 ? '0' : '${mandan}만',
                      style: TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  tooltipBgColor: Colors.grey.shade700,
                  getTooltipItem: (group, _, rod, __) {
                    final day = group.x;
                    final amount = rod.toY.toInt();
                    return BarTooltipItem(
                      '$day일\n${formatter.format(amount)}',
                      TextStyle(color: Colors.white),
                    );
                  },
                ),
              ),
              alignment: BarChartAlignment.spaceBetween,
            ),
          ),
        ),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransactionProvider>(context);
    final transactions = provider.getByMonth(selectedMonth.year, selectedMonth.month);
    final totalIncome = transactions.where((tx) => tx.type == '수입').fold(0, (sum, tx) => sum + tx.amount);
    final totalExpense = transactions.where((tx) => tx.type == '지출').fold(0, (sum, tx) => sum + tx.amount.abs());

    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                DropdownButton<int>(
                  value: selectedMonth.month,
                  items: List.generate(12, (i) => i + 1)
                      .map((m) => DropdownMenuItem(value: m, child: Text('$m월')))
                      .toList(),
                  onChanged: (val) => val != null
                      ? setState(() => selectedMonth = DateTime(selectedMonth.year, val))
                      : null,
                ),
                Spacer(),
                Icon(Icons.refresh, size: 18, color: Colors.grey),
                SizedBox(width: 4),
                Text('업데이트됨', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: SummaryCard(
                    title: '총 수입',
                    value: formatter.format(totalIncome),
                    subText: '',
                    color: Colors.blue,
                  ),
                ),
                SizedBox(width: 15),
                Expanded(
                  child: SummaryCard(
                    title: '총 지출',
                    value: formatter.format(totalExpense),
                    subText: '',
                    color: Colors.redAccent,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: buildPieChart('지출', transactions),
          ),
          SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: buildPieChart('수입', transactions),
          ),
          SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: buildCombinedLineChart(transactions),
          ),
          SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: buildBarChart(transactions),
          ),
          SizedBox(height: 30),
        ],
      ),
    );
  }
}

class SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String subText;
  final Color color;

  const SummaryCard({required this.title, required this.value, required this.subText, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          SizedBox(height: 4),
          Text(value, style: TextStyle(color: Colors.white, fontSize: 18)),
          SizedBox(height: 2),
          Text(subText, style: TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}
