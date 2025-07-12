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

    if (categoryTotals.isEmpty) {
      return Text('$type 데이터 없음');
    }

    final total = categoryTotals.values.fold(0, (sum, val) => sum + val);
    final categoryColors = {
      for (var key in categoryTotals.keys) key: getRandomColor()
    };

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
                  titleStyle: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
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

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransactionProvider>(context);
    final transactions = provider.getByMonth(selectedMonth.year, selectedMonth.month);

    final totalIncome = transactions
        .where((tx) => tx.type == '수입')
        .fold(0, (sum, tx) => sum + tx.amount);

    final totalExpense = transactions
        .where((tx) => tx.type == '지출')
        .fold(0, (sum, tx) => sum + tx.amount.abs());

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
                  items: List.generate(12, (index) => index + 1)
                      .map((month) => DropdownMenuItem(
                    value: month,
                    child: Text('${month}월'),
                  ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        selectedMonth = DateTime(selectedMonth.year, val);
                      });
                    }
                  },
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

  const SummaryCard({
    required this.title,
    required this.value,
    required this.subText,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
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


