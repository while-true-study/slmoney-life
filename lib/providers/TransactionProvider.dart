// lib/providers/TransactionProvider.dart

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';

import '../models/transaction.dart';

class TransactionProvider extends ChangeNotifier {

  final List<Transaction> _transactions = [];
  bool _isLoaded = false;

  List<Transaction> get transactions => List.unmodifiable(_transactions);
  bool get isLoaded => _isLoaded;

  TransactionProvider() {
    _loadFromHive();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadFromHive() async {
    final box = Hive.box<Transaction>('transactions');
    _transactions
      ..clear()
      ..addAll(box.values);
    _isLoaded = true;
    notifyListeners();
  }

  void _onNativeEvent(dynamic event) {
    try {
      final data = json.decode(event as String) as Map<String, dynamic>;
      debugPrint('Native notification received: $data');
      handleNotification(data);
    } catch (e) {
      debugPrint('Notification parsing error: $e');
    }
  }

  /// 외부 알림으로부터 받은 데이터를 Transaction으로 변환해 저장
  Future<void> handleNotification(Map<String, dynamic> data) async {
    final dateStr = data['date'] as String? ?? '';
    final timeStr = data['time'] as String? ?? '';
    DateTime dateTime;
    try {
      dateTime = DateTime.parse('$dateStr $timeStr');
    } catch (_) {
      dateTime = DateTime.now();
    }

    final rawAmount = data['amount'];
    final amount = rawAmount is num
        ? rawAmount.toInt()
        : int.tryParse(rawAmount.toString()) ?? 0;

    final desc = data['description'] as String? ?? '';
    final typeStr = data['type'] as String?;
    final type = (typeStr == '수입' || typeStr == '지출')
        ? typeStr!
        : (amount >= 0 ? '수입' : '지출');

    final store = data['store'] as String? ?? desc;
    final category = data['category'] as String? ?? '';

    final id = DateTime.now().millisecondsSinceEpoch.toString();

    final txn = Transaction(
      id: id,
      store: store,
      amount: amount,
      category: category,
      date: dateTime,
      type: type,
    );

    final box = Hive.box<Transaction>('transactions');
    await box.put(txn.id, txn);
    _transactions.add(txn);
    notifyListeners();
  }

  /// 수동으로 화면에서 추가할 때 호출되는 메서드
  Future<void> addTransaction(Transaction tx) async {
    final box = Hive.box<Transaction>('transactions');
    await box.put(tx.id, tx);
    _transactions.add(tx);
    notifyListeners();
  }

  void deleteTransaction(String id) {
    final box = Hive.box<Transaction>('transactions');
    final map = box.toMap();
    final key = map.keys.firstWhere(
          (k) => map[k]!.id == id,
      orElse: () => null,
    );
    if (key != null) box.delete(key);
    _transactions.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  List<Transaction> getByMonth(int y, int m) =>
      _transactions.where((tx) => tx.date.year == y && tx.date.month == m).toList();

  int getTotalIncome(int y, int m) =>
      getByMonth(y, m).where((tx) => tx.amount > 0).fold(0, (s, tx) => s + tx.amount);

  int getTotalSpent(int y, int m) =>
      getByMonth(y, m).where((tx) => tx.amount < 0).fold(0, (s, tx) => s + tx.amount.abs());

  List<Transaction> getByCategory(int y, int m, String cat) =>
      getByMonth(y, m)
          .where((tx) => tx.category == cat && tx.amount < 0)
          .toList();

  int getCategorySpentTotal(int y, int m, String cat) =>
      getByCategory(y, m, cat).fold(0, (s, tx) => s + tx.amount.abs());
}
