import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/TransactionProvider.dart';
import '../models/Transaction.dart';
import 'package:uuid/uuid.dart';

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
  String? _selectedType = '변동'; // 기본값
  String _inOutType = '지출';     // 수입 or 지출
  bool _planned = false;

  final List<String> _categories = [
    '식비', '교통', '쇼핑', '카페', '문화생활', '기타'
  ];

  final List<String> _types = [
    '정기', '변동', '할부'
  ];

  void _submit() {
    final store = _storeController.text;
    final amount = int.tryParse(_amountController.text) ?? 0;

    if (store.isEmpty || _selectedCategory == null || _selectedType == null) return;

    final tx = Transaction(
      id: Uuid().v4(),
      store: store,
      amount: _inOutType == '수입' ? amount.abs() : -amount.abs(), // ✅ 금액 처리
      category: _selectedCategory!,
      date: widget.selectedDate,
      type: _inOutType, // '수입' 또는 '지출'
      planned: _planned,
    );

    Provider.of<TransactionProvider>(context, listen: false).addTransaction(tx);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('소비 내역 추가')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // 수입/지출 선택
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: Text('지출'),
                      value: '지출',
                      groupValue: _inOutType,
                      onChanged: (value) {
                        setState(() {
                          _inOutType = value!;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: Text('수입'),
                      value: '수입',
                      groupValue: _inOutType,
                      onChanged: (value) {
                        setState(() {
                          _inOutType = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),

              TextField(
                controller: _storeController,
                decoration: InputDecoration(labelText: '내역 이름'),
              ),
              TextField(
                controller: _amountController,
                decoration: InputDecoration(labelText: '금액'),
                keyboardType: TextInputType.number,
              ),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                hint: Text('카테고리 선택'),
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedCategory = val;
                  });
                },
              ),
              // 지출일 때만 유형 선택 노출
              if (_inOutType == '지출')
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  decoration: InputDecoration(labelText: '지출 유형'),
                  items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedType = val;
                    });
                  },
                ),
              if (_inOutType == '지출')
                SwitchListTile(
                  title: Text('예정된 지출인가요?'),
                  value: _planned,
                  onChanged: (val) {
                    setState(() {
                      _planned = val;
                    });
                  },
                ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _submit,
                child: Text('추가하기'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
