import 'package:flutter/material.dart';
import '../models/Transaction.dart';

class TransactionCard extends StatelessWidget {
  final Transaction tx;
  TransactionCard({required this.tx});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8),
      child: ListTile(
        title: Text(tx.store),
        subtitle: Text('${tx.category} - ${tx.date.toLocal()}'),
        trailing: Text('${tx.amount}원'),
      ),
    );
  }
}
