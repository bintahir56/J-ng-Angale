import 'package:flutter/material.dart';
import 'package:jang_angale/models/word_entry.dart';
import 'package:jang_angale/services/word_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<WordEntry>> _wordsFuture;
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _favoriteWords = <String>{};
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _wordsFuture = WordRepository.loadWords();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('favorite_words') ?? <String>[];

    setState(() {
      _favoriteWords.addAll(saved);
    });
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorite_words', _favoriteWords.toList());
  }

  void _toggleFavorite(String wordKey) {
    setState(() {
      if (_favoriteWords.contains(wordKey)) {
        _favoriteWords.remove(wordKey);
      } else {
        _favoriteWords.add(wordKey);
      }
    });
    _saveFavorites();
  }

  List<WordEntry> _filterWords(List<WordEntry> words) {
    final query = _searchController.text.trim().toLowerCase();
    final filtered = words.where((entry) {
      final matchesQuery = query.isEmpty ||
          entry.wolof.toLowerCase().contains(query) ||
          entry.english.toLowerCase().contains(query);
      final matchesCategory =
          _selectedCategory == 'All' || entry.category == _selectedCategory;
      return matchesQuery && matchesCategory;
    }).toList();

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jang Angale'),
      ),
      body: FutureBuilder<List<WordEntry>>(
        future: _wordsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(
              child: Text('Could not load the dictionary. Please try again.'),
            );
          }

          final words = snapshot.data!;
          final categories = <String>{'All'};
          for (final word in words) {
            categories.add(word.category);
          }

          final visibleWords = _filterWords(words);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search Wolof or English',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: SizedBox(
                  height: 48,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: categories.map((category) {
                      final isSelected = _selectedCategory == category;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(category),
                          selected: isSelected,
                          selectedColor: const Color(0xFFB7E4C7),
                          onSelected: (_) {
                            setState(() {
                              _selectedCategory = category;
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: visibleWords.isEmpty
                    ? const Center(
                        child: Text('No words match your search.'),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                        itemCount: visibleWords.length,
                        itemBuilder: (context, index) {
                          final entry = visibleWords[index];
                          final key = '${entry.wolof}::${entry.english}';
                          final isFavorite = _favoriteWords.contains(key);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              entry.wolof,
                                              style: const TextStyle(
                                                fontSize: 26,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              entry.english,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                color: Colors.green,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () => _toggleFavorite(key),
                                        icon: Icon(
                                          isFavorite
                                              ? Icons.favorite
                                              : Icons.favorite_border,
                                          color: isFavorite
                                              ? Colors.red
                                              : Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Category: ${entry.category}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Example: ${entry.example}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Tip: ${entry.note}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
