class WordEntry {
  final String wolof;
  final String english;
  final String category;
  final String example;
  final String note;

  const WordEntry({
    required this.wolof,
    required this.english,
    required this.category,
    required this.example,
    required this.note,
  });

  factory WordEntry.fromJson(Map<String, dynamic> json) {
    return WordEntry(
      wolof: json['wolof'] as String? ?? '',
      english: json['english'] as String? ?? '',
      category: json['category'] as String? ?? 'General',
      example: json['example'] as String? ?? '',
      note: json['note'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'wolof': wolof,
      'english': english,
      'category': category,
      'example': example,
      'note': note,
    };
  }
}
