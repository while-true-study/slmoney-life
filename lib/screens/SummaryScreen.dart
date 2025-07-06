import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/TransactionProvider.dart';
import '../models/Transaction.dart';

class SummaryScreen extends StatefulWidget {
  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  final formatter = NumberFormat('#,###원');
  DateTime selectedMonth = DateTime.now();

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

    final regularExpenses = transactions
        .where((tx) => tx.category == '정기지출' && tx.type == '지출')
        .toList();
    final variableExpenses = transactions
        .where((tx) => tx.category == '변동지출' && tx.type == '지출')
        .toList();
    final installmentExpenses = transactions
        .where((tx) => tx.category == '할부지출' && tx.type == '지출')
        .toList();

    Widget buildExpenseBlock(String title, List<Transaction> list, int budget) {
      final planned = list.where((tx) => tx.planned).toList();
      final completed = list.where((tx) => !tx.planned).toList();
      final usedAmount = completed.fold(0, (sum, tx) => sum + tx.amount.abs());

      return Container(
        margin: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 8)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('지출 예정 ${planned.length}건'),
                Text(formatter.format(planned.fold(0, (sum, tx) => sum + tx.amount.abs()))),
              ],
            ),
            SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('지출 완료 ${completed.length}건'),
                Text(formatter.format(usedAmount)),
              ],
            ),
          ],
        ),
      );
    }

    return Column(
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
                  subText: '예정 0,000원',
                  color: Colors.blue,
                ),
              ),
              SizedBox(width: 15),
              Expanded(
                child: SummaryCard(
                  title: '총 지출',
                  value: formatter.format(totalExpense),
                  subText: '예산 0,000원',
                  color: Colors.redAccent,
                ),
              ),
            ],
          ),
        ),
        buildExpenseBlock('정기지출', regularExpenses, 925000),
        buildExpenseBlock('변동지출', variableExpenses, 1865000),
        buildExpenseBlock('할부지출', installmentExpenses, 975000),
      ],
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
