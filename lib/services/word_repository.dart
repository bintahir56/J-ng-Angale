import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:jang_angale/models/word_entry.dart';

class WordRepository {
  static Future<List<WordEntry>> loadWords() async {
    final raw = await rootBundle.loadString('assets/data/wolof_words.json');
    final decoded = jsonDecode(raw) as List<dynamic>;

    return decoded
        .map((item) => WordEntry.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
