import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/TransactionProvider.dart';
import '../widgets/TransactionCard.dart';

class TransactionListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final txList = Provider.of<TransactionProvider>(context).transactions;
    return ListView.builder(
      itemCount: txList.length,
      itemBuilder: (ctx, i) => TransactionCard(tx: txList[i]),
    );
  }
}
