// BookReaderPage: Simple 1-page vertical reader using PageView
// Renders plain text from Gutenberg .txt and splits into scrollable pages

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:mymink/core/widgets/custom_app_bar.dart';

class BookReaderPage extends StatefulWidget {
  final String htmlUrl;
  const BookReaderPage({super.key, required this.htmlUrl});

  @override
  State<BookReaderPage> createState() => _BookReaderPageState();
}

class _BookReaderPageState extends State<BookReaderPage> {
  List<String> _pages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTextContent();
  }

  Future<void> _loadTextContent() async {
    try {
      final response = await http.get(Uri.parse(widget.htmlUrl));
      if (response.statusCode == 200) {
        final text = response.body;
        setState(() {
          _pages = _splitTextToPages(text);
          _isLoading = false;
        });
      } else {
        throw Exception("Failed to load book");
      }
    } catch (e) {
      debugPrint("Error: $e");
      setState(() => _isLoading = false);
    }
  }

  List<String> _splitTextToPages(String text) {
    const int maxChars = 1400;
    List<String> chunks = [];
    for (int i = 0; i < text.length; i += maxChars) {
      final end = (i + maxChars < text.length) ? i + maxChars : text.length;
      chunks.add(text.substring(i, end));
    }
    return chunks;
  }

  Widget _buildSinglePage(String text) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: SingleChildScrollView(
        child: Text(
          text,
          style: const TextStyle(fontSize: 16, height: 1.5),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                CustomAppBar(title: 'Book Reader'),
                const SizedBox(
                  height: 10,
                ),
                Expanded(
                  child: PageView.builder(
                    itemCount: _pages.length,
                    itemBuilder: (_, index) => _buildSinglePage(_pages[index]),
                  ),
                ),
              ],
            ),
    );
  }
}
