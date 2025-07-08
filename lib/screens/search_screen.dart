import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isLoading = false;

  void _search(String query) async {
    setState(() => _isLoading = true);
    final results = await ApiService.searchMovies(query);
    setState(() {
      _searchResults = results;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Search Movies')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: _controller,
              onSubmitted: _search,
              decoration: InputDecoration(
                hintText: 'Enter movie title...',
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () => _search(_controller.text),
                ),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          if (_isLoading) CircularProgressIndicator(),
          if (!_isLoading && _searchResults.isEmpty && _controller.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('No results found.'),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final movie = _searchResults[index];
                return ListTile(
                  leading: movie['poster_path'] != null
                      ? CachedNetworkImage(
                          imageUrl: 'https://image.tmdb.org/t/p/w92${movie['poster_path']}',
                          width: 50,
                          fit: BoxFit.cover,
                        )
                      : Icon(Icons.image_not_supported),
                  title: Text(movie['title'] ?? 'No title'),
                  subtitle: Text('Rating: ${movie['vote_average']}'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
