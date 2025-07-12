import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CategoryColorProvider with ChangeNotifier {
  final List<String> _fixedCategories = ['식비', '교통', '쇼핑', '생활', '문화', '건강', '기타'];
  Map<String, Color> _categoryColors = {};
  final _prefsKey = 'categoryColors';

  Future<void> loadColors() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);

    if (saved != null) {
      final Map<String, dynamic> map = jsonDecode(saved);
      _categoryColors = map.map((k, v) => MapEntry(k, Color(int.parse(v))));
    }

    // 고정 카테고리 누락된 색상 생성
    for (final category in _fixedCategories) {
      if (!_categoryColors.containsKey(category)) {
        _categoryColors[category] = _generateRandomColor();
      }
    }

    await _saveColors(); // 변경 사항 저장
  }

  Color getColor(String category) {
    return _categoryColors[category] ?? Colors.grey; // 없는 경우 회색 처리
  }

  Future<void> _saveColors() async {
    final prefs = await SharedPreferences.getInstance();
    final map = _categoryColors.map((k, v) => MapEntry(k, v.value.toString()));
    await prefs.setString(_prefsKey, jsonEncode(map));
  }

  Color _generateRandomColor() {
    final random = Random();
    return Color.fromARGB(
      255,
      random.nextInt(200) + 30,
      random.nextInt(200) + 30,
      random.nextInt(200) + 30,
    );
  }
}
