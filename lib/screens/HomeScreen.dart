import 'package:flutter/material.dart';
import '../widgets/CustomBottomNav.dart';
import '../widgets/TransactionCard.dart';
import 'AddTransactionScreen.dart';
import 'TransactionListScreen.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('AI 가계부')),
      body: TransactionListScreen(),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddTransactionScreen()),
          );
        },
      ),
      bottomNavigationBar: CustomBottomNav(),
    );
  }
}