import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/transaction.dart';
import '../providers/TransactionProvider.dart';

class AddTransactionScreen extends StatefulWidget {
  final DateTime selectedDate;
  const AddTransactionScreen({super.key, required this.selectedDate});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _storeController = TextEditingController();
  final _amountController = TextEditingController();
  String? _selectedCategory;
  String _inOutType = '지출';

  final List<String> _categories = [
    '식비', '교통', '쇼핑', '생활', '문화', '건강', '기타'
  ];

  void _submit() {
    final store = _storeController.text.trim();
    final amount = int.tryParse(_amountController.text.trim()) ?? 0;

    if (store.isEmpty || _selectedCategory == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모든 항목을 정확히 입력해주세요.')),
      );
      return;
    }

    final tx = Transaction(
      id: const Uuid().v4(),
      store: store,
      amount: _inOutType == '수입' ? amount.abs() : -amount.abs(),
      category: _selectedCategory!,
      date: widget.selectedDate,
      type: _inOutType,
    );

    Provider.of<TransactionProvider>(context, listen: false).addTransaction(tx);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('내역 추가하기'),
        centerTitle: true,
        backgroundColor: Colors.orange,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // 수입/지출 선택
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('지출'),
                      value: '지출',
                      groupValue: _inOutType,
                      activeColor: Colors.red,
                      onChanged: (val) => setState(() => _inOutType = val!),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('수입'),
                      value: '수입',
                      groupValue: _inOutType,
                      activeColor: Colors.blue,
                      onChanged: (val) => setState(() => _inOutType = val!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 내역 제목
              TextField(
                controller: _storeController,
                decoration: InputDecoration(
                  labelText: '내역 제목',
                  prefixIcon: const Icon(Icons.edit_note_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),

              // 금액
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: '금액',
                  prefixIcon: const Icon(Icons.attach_money),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),

              // 카테고리 선택
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: '카테고리 선택',
                  prefixIcon: const Icon(Icons.category_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedCategory = val),
              ),
              const SizedBox(height: 32),

              // 저장 버튼
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.save),
                  label: const Text('저장하기'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
