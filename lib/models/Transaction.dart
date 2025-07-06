import 'package:hive/hive.dart';

part 'Transaction.g.dart';

@HiveType(typeId: 0)
class Transaction extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String store;

  @HiveField(2)
  final int amount;

  @HiveField(3)
  final String category;

  @HiveField(4)
  final DateTime date;

  @HiveField(5)
  String type; // '정기', '변동', '할부', 지출이나 소비같은거

  @HiveField(6)
  bool planned; // 예정 여부

  Transaction({
    required this.id,
    required this.store,
    required this.amount,
    required this.category,
    required this.date,
    required this.type,
    required this.planned,
  });

  // JSON에서 객체로 변환
  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      store: json['store'],
      amount: json['amount'],
      category: json['category'],
      date: DateTime.parse(json['date']),
      type: json['type'] ?? '기타',
      planned: json['planned'] ?? false,
    );
  }

  // JSON 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'store': store,
      'amount': amount,
      'category': category,
      'date': date.toIso8601String(),
      'type': type,
      'planned': planned,
    };
  }
}
