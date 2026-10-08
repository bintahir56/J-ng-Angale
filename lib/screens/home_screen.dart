import 'package:flutter/material.dart';
import 'package:jang_angale/models/word_entry.dart';
import 'package:jang_angale/services/tts_service.dart';
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
  final TtsService _ttsService = TtsService();
  String? _playingWord;
  List<WordEntry> _searchResults = [];

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

  void _playAudio(String word) async {
    setState(() {
      _playingWord = word;
    });
    await _ttsService.speak(word);
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _playingWord = null;
        });
      }
    });
  }

  void _performSearch(List<WordEntry> allWords) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    final results = allWords
        .where((entry) =>
            entry.wolof.toLowerCase().startsWith(query) ||
            entry.wolof.toLowerCase().contains(query))
        .toList();

    setState(() {
      _searchResults = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jang Angale'),
        elevation: 0,
      ),
      body: FutureBuilder<List<WordEntry>>(
        future: _wordsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(
              child: Text('Error loading dictionary'),
            );
          }

          final allWords = snapshot.data!;

          return Column(
            children: [
              // Search Box
              Container(
                padding: const EdgeInsets.all(16),
                color: const Color(0xFF1B5E20),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => _performSearch(allWords),
                  decoration: InputDecoration(
                    hintText: 'Type Wolof word...',
                    hintStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  style: const TextStyle(color: Colors.black),
                ),
              ),

              // Results List
              Expanded(
                child: _searchController.text.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search,
                              size: 80,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Type a Wolof word to find English',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : _searchResults.isEmpty
                        ? Center(
                            child: Text(
                              'No words found',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              final entry = _searchResults[index];
                              final key =
                                  '${entry.wolof}::${entry.english}';
                              final isFavorite =
                                  _favoriteWords.contains(key);
                              final isPlaying =
                                  _playingWord == entry.english;

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                elevation: 3,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Wolof word + Favorite
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              entry.wolof,
                                              style: const TextStyle(
                                                fontSize: 32,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF1B5E20),
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            onPressed: () =>
                                                _toggleFavorite(key),
                                            icon: Icon(
                                              isFavorite
                                                  ? Icons.favorite
                                                  : Icons.favorite_border,
                                              color: isFavorite
                                                  ? Colors.red
                                                  : Colors.grey,
                                              size: 28,
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 14),

                                      // English + Listen Button
                                      Container(
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE8F5E9),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                            color: const Color(0xFFC8E6C9),
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const Text(
                                                    'English',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.grey,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Text(
                                                    entry.english,
                                                    style: const TextStyle(
                                                      fontSize: 24,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color:
                                                          Color(0xFF1B5E20),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            ElevatedButton.icon(
                                              onPressed: () =>
                                                  _playAudio(entry.english),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    const Color(0xFF1B5E20),
                                                foregroundColor: Colors.white,
                                                padding: const EdgeInsets
                                                    .symmetric(
                                                  horizontal: 14,
                                                  vertical: 12,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                              ),
                                              icon: Icon(
                                                isPlaying
                                                    ? Icons.volume_up
                                                    : Icons.play_arrow,
                                              ),
                                              label: Text(
                                                isPlaying
                                                    ? 'Playing...'
                                                    : 'Listen',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      const SizedBox(height: 12),

                                      // Category
                                      Text(
                                        'Category: ${entry.category}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),

                                      const SizedBox(height: 8),

                                      // Example
                                      RichText(
                                        text: TextSpan(
                                          children: [
                                            const TextSpan(
                                              text: 'Example: ',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.black87,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            TextSpan(
                                              text: entry.example,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      const SizedBox(height: 8),

                                      // Tip
                                      RichText(
                                        text: TextSpan(
                                          children: [
                                            const TextSpan(
                                              text: 'Tip: ',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.black54,
                                                fontWeight: FontWeight.bold,
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                            TextSpan(
                                              text: entry.note,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.black54,
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                          ],
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

  @override
  void dispose() {
    _searchController.dispose();
    _ttsService.stop();
    super.dispose();
  }
}
