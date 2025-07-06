import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/Transaction.dart';

class TransactionProvider with ChangeNotifier {
  List<Transaction> _transactions = [];
  bool _isLoaded = false; // 로드 여부

  List<Transaction> get transactions => _transactions;
  bool get isLoaded => _isLoaded; // 로드 상태 확인용 getter

  void addTransaction(Transaction tx) {
    _transactions.add(tx);
    Hive.box<Transaction>('transactions').add(tx);
    notifyListeners();
  }

  void setTransactions(List<Transaction> txList) {
    _transactions = txList;
    _isLoaded = true; // 수동 설정 시에도 true 처리
    notifyListeners();
  }

  void deleteTransaction(String id) {
    final box = Hive.box<Transaction>('transactions');
    final Map<dynamic, Transaction> all = box.toMap();
    final keyToDelete = all.keys.firstWhere(
          (key) => all[key]!.id == id,
      orElse: () => null,
    );
    if (keyToDelete != null) {
      box.delete(keyToDelete);
    }

    _transactions.removeWhere((tx) => tx.id == id);
    notifyListeners();
  }

  void loadTransactions() {
    final box = Hive.box<Transaction>('transactions');
    _transactions = box.values.toList();
    _isLoaded = true; // 데이터 로딩 완료 표시
    notifyListeners();
  }

  List<Transaction> getByMonth(int year, int month) {
    return _transactions
        .where((tx) => tx.date.year == year && tx.date.month == month)
        .toList();
  }

  int getTotalIncome(int year, int month) {
    return getByMonth(year, month)
        .where((tx) => tx.amount > 0)
        .fold(0, (sum, tx) => sum + tx.amount);
  }

  int getTotalSpent(int year, int month) {
    return getByMonth(year, month)
        .where((tx) => tx.amount < 0)
        .fold(0, (sum, tx) => sum + tx.amount.abs());
  }

  List<Transaction> getByCategory(int year, int month, String category) {
    return getByMonth(year, month)
        .where((tx) => tx.category == category && tx.amount < 0)
        .toList();
  }

  int getCategorySpentTotal(int year, int month, String category) {
    return getByCategory(year, month, category)
        .fold(0, (sum, tx) => sum + tx.amount.abs());
  }

  int getSpentByType(int year, int month, String type) {
    return getByMonth(year, month)
        .where((tx) => tx.amount < 0 && tx.type == type)
        .fold(0, (sum, tx) => sum + tx.amount.abs());
  }
}
