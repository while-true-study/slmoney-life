// lib/models/transaction.dart

import 'package:hive/hive.dart';

part 'transaction.g.dart';

@HiveType(typeId: 0)
class Transaction extends HiveObject {
  @HiveField(0)
  final String id;          // 고유 ID

  @HiveField(1)
  final String store;       // 구매 내역

  @HiveField(2)
  final int amount;         // 금액 (수입은 양수, 지출은 음수)

  @HiveField(3)
  final String category;    // 카테고리

  @HiveField(4)
  final DateTime date;      // 거래 일시

  @HiveField(5)
  final String type;        // '지출' , '수입'

  Transaction({
    required this.id,
    required this.store,
    required this.amount,
    required this.category,
    required this.date,
    required this.type,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      store: json['store'] as String,
      amount: (json['amount'] as num).toInt(),
      category: json['category'] as String,
      date: DateTime.parse(json['date'] as String),
      type: json['type'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'store': store,
    'amount': amount,
    'category': category,
    'date': date.toIso8601String(),
    'type': type,
  };
}
