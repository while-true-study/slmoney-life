import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/TransactionProvider.dart';
import '../models/Transaction.dart';
import 'package:intl/intl.dart';

class CategoryBreakdownScreen extends StatelessWidget {
  final DateTime month;
  final String type; // '수입' 또는 '지출'

  CategoryBreakdownScreen({required this.month, required this.type});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransactionProvider>(context);
    final formatter = NumberFormat('#,###원');

    final transactions = provider.getByMonth(month.year, month.month)
        .where((tx) => tx.type == type).toList();

    final Map<String, int> categoryTotals = {};
    for (var tx in transactions) {
      categoryTotals[tx.category] = (categoryTotals[tx.category] ?? 0) + tx.amount.abs();
    }

    final total = categoryTotals.values.fold(0, (sum, val) => sum + val);

    return Scaffold(
      appBar: AppBar(title: Text('카테고리별 $type')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 1.3,
              child: PieChart(
                PieChartData(
                  centerSpaceRadius: 50,
                  sections: categoryTotals.entries.map((entry) {
                    final percent = (entry.value / total * 100).toStringAsFixed(0);
                    return PieChartSectionData(
                      value: entry.value.toDouble(),
                      title: '$percent%',
                      radius: 50,
                      titleStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                    );
                  }).toList(),
                ),
              ),
            ),
            SizedBox(height: 20),
            ...categoryTotals.entries.map((entry) {
              final percent = (entry.value / total * 100).toStringAsFixed(0);
              return ListTile(
                leading: CircleAvatar(child: Text('$percent%')),
                title: Text(entry.key),
                subtitle: Text('금액 ${formatter.format(entry.value)}'),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
