import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:mymink/core/constants/app_routes.dart';
import 'package:mymink/core/constants/colors.dart';
import 'package:mymink/core/widgets/custom_app_bar.dart';
import 'package:mymink/core/widgets/progress_hud.dart';
import 'package:mymink/core/widgets/search_bar_with_button.dart';
import 'package:mymink/features/library/models/book_model.dart';
import 'epub_reader_page.dart';
import 'package:http/http.dart' as http;

class LibraryHomePage extends StatefulWidget {
  const LibraryHomePage({Key? key}) : super(key: key);

  @override
  State<LibraryHomePage> createState() => _LibraryHomePageState();
}

class _LibraryHomePageState extends State<LibraryHomePage> {
  final TextEditingController _searchController = TextEditingController();
  List<BookResult> _books = [];
  List<BookResult> _originalBooks = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchAllBooks();
  }

  /// 1) Initial load: top downloads
  Future<void> _fetchAllBooks() async {
    setState(() => _isLoading = true);
    const url = 'https://gutendex.com/books/?sort=downloads';
    try {
      final resp = await http.get(Uri.parse(url));
      if (resp.statusCode == 200) {
        final model = BookModel.fromJson(jsonDecode(resp.body));
        setState(() {
          _originalBooks = model.results;
          _books = List.of(_originalBooks);
        });
      }
    } catch (_) {
      // ignore
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 2) Called when user taps the search button or picks a letter
  Future<void> _applySearch() async {
    final query = _searchController.text.trim();
    if (query.length == 1) {
      // server-side search by a single letter
      await _searchByLetter(query.toUpperCase());
    } else if (query.isNotEmpty) {
      // local substring filter
      final lower = query.toLowerCase();
      setState(() {
        _books = _originalBooks
            .where((b) => b.title.toLowerCase().contains(lower))
            .toList();
      });
    } else {
      // empty → restore original
      setState(() => _books = List.of(_originalBooks));
    }
  }

  /// 3) Page through API until no more titles beginning with [letter]
  Future<void> _searchByLetter(String letter) async {
    setState(() => _isLoading = true);
    final List<BookResult> matches = [];
    int page = 1;
    while (true) {
      final url = 'https://gutendex.com/books/?page=$page&search=$letter';
      final resp = await http.get(Uri.parse(url));
      if (resp.statusCode != 200) break;
      final model = BookModel.fromJson(jsonDecode(resp.body));
      // only titles that start with the letter:
      final pageMatches = model.results
          .where((r) => r.title.toUpperCase().startsWith(letter))
          .toList();
      if (pageMatches.isEmpty) break;
      matches.addAll(pageMatches);
      page++;
      // optional: guard against infinite loops
      if (page > 5) break;
    }
    setState(() {
      _books = matches;
      _originalBooks = matches;
      _isLoading = false;
    });
  }

  void _openBook(Map<String, dynamic> formats) {
    final url = formats['text/plain; charset=us-ascii'] ??
        formats['text/plain'] ??
        formats['text/html; charset=utf-8'] ??
        formats['text/html'];
    if (url != null && url.toString().isNotEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => BookReaderPage(htmlUrl: url)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No readable version available")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Column(
            children: [
              CustomAppBar(
                title: 'Library',
                gestureDetector: GestureDetector(
                  onTap: () async {
                    // pick a letter and then run search
                    final letter =
                        await context.push<String>(AppRoutes.libraryAtoZPage);
                    if (letter != null) {
                      _searchController.text = letter;
                      await _applySearch();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.grey.withAlpha(80), blurRadius: 4)
                      ],
                    ),
                    child: const Icon(Symbols.sort_by_alpha, size: 22),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: SearchBarWithButton(
                  controller: _searchController,
                  hintText: 'Search Books',
                  onPressed: _applySearch,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: GridView.builder(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.only(
                      top: 8, bottom: 24, left: 25, right: 25),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.6,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 6,
                  ),
                  itemCount: _books.length,
                  itemBuilder: (ctx, i) {
                    final book = _books[i];
                    final imageUrl =
                        'https://www.gutenberg.org/cache/epub/${book.id}/pg${book.id}.cover.medium.jpg';
                    return GestureDetector(
                      onTap: () => _openBook(book.formats),
                      child: Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 1,
                        child: Column(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(12)),
                                child: Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const Icon(Icons.image),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(6),
                              child: Text(
                                book.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
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
          ),
          if (_isLoading)
            Center(
              child: ProgressHud(),
            )
        ],
      ),
    );
  }
}
