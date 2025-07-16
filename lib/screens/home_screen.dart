import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/api_service.dart';
import 'movie_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> _movies = [];
  String _currentMode = 'Popular'; // or TopRated or Search
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPopularMovies();
    // Add listener to search controller for clear button visibility
    _searchController.addListener(() {
      setState(() {
        // This setState is to rebuild the UI and show/hide the clear icon
        // No explicit action needed here, just triggers a rebuild.
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose(); // Dispose controller to prevent memory leaks
    super.dispose();
  }

  void _loadPopularMovies() async {
    try {
      setState(() {
        _isLoading = true;
        _currentMode = 'Popular';
      });
      final movies = await ApiService.fetchPopularMovies();
      setState(() {
        _movies = movies;
        _isLoading = false;
      });
    } catch (e) {
      _handleError('popular movies', e);
    }
  }

  void _loadTopRatedMovies() async {
    try {
      setState(() {
        _isLoading = true;
        _currentMode = 'TopRated';
      });
      final movies = await ApiService.fetchTopRatedMovies();
      setState(() {
        _movies = movies;
        _isLoading = false;
      });
    } catch (e) {
      _handleError('top-rated movies', e);
    }
  }

  void _searchMovies(String query) async {
    if (query.trim().isEmpty) {
      // If query is empty, revert to Popular movies (or clear results)
      _loadPopularMovies();
      return;
    }
    try {
      setState(() {
        _isLoading = true;
        _currentMode = 'Search';
      });
      final results = await ApiService.searchMovies(query.trim());
      setState(() {
        _movies = results;
        _isLoading = false;
      });
    } catch (e) {
      _handleError('search', e);
    }
  }

  void _handleError(String contextText, Object e) {
    setState(() => _isLoading = false);
    debugPrint('Error while fetching $contextText: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to load $contextText')),
    );
  }

  Widget _buildMovieGrid() {
    if (_movies.isEmpty && !_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.movie_filter, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 10),
            Text(
              _currentMode == 'Search' && _searchController.text.isNotEmpty
                  ? 'No results for "${_searchController.text}". Try a different search term!'
                  : 'No movies found.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: _movies.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2 / 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (context, index) {
        final movie = _movies[index];
        final imageUrl = movie['poster_path'] != null
            ? 'https://image.tmdb.org/t/p/w500${movie['poster_path']}'
            : null;

        return Card(
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 3, // Added slight elevation for card effect
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MovieDetailScreen(movie: movie),
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: imageUrl != null
                      ? Hero(
                          tag: movie['id'].toString(),
                          child: CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) =>
                                const Center(child: CircularProgressIndicator()),
                            errorWidget: (context, url, error) => Center(
                              child: Icon(Icons.broken_image,
                                  size: 40, color: Colors.grey[400]),
                            ),
                          ),
                        )
                      : Container(
                          color: Colors.grey.shade200,
                          child: Center(
                            child: Icon(Icons.image_not_supported,
                                size: 40, color: Colors.grey[400]),
                          ),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    movie['title'] ?? 'No Title',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Movie Browser'),
        centerTitle: true, // Center the app bar title
      ),
      body: Column(
        children: [
          // Buttons and Search Bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    _searchController.clear(); // Clear search on category change
                    _loadPopularMovies();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _currentMode == 'Popular'
                        ? Theme.of(context).primaryColor
                        : null,
                    foregroundColor: _currentMode == 'Popular'
                        ? Theme.of(context).colorScheme.onPrimary
                        : null,
                  ),
                  child: const Text('Popular'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    _searchController.clear(); // Clear search on category change
                    _loadTopRatedMovies();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _currentMode == 'TopRated'
                        ? Theme.of(context).primaryColor
                        : null,
                    foregroundColor: _currentMode == 'TopRated'
                        ? Theme.of(context).colorScheme.onPrimary
                        : null,
                  ),
                  child: const Text('Top Rated'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onSubmitted: _searchMovies,
                    decoration: InputDecoration(
                      hintText: 'Search...',
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _movies = []; // Clear current search results
                                  // Optionally keep _currentMode as 'Search' to show empty state for search
                                  // or revert to 'Popular' and load popular movies immediately.
                                  // For a complete clear, let's revert to popular.
                                  _currentMode = 'Popular';
                                });
                                _loadPopularMovies();
                              },
                            )
                          : IconButton( // Always show an icon, either search or clear
                              icon: const Icon(Icons.search),
                              onPressed: () =>
                                  _searchMovies(_searchController.text),
                            ),
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 1), // Thinner divider

          // Movie Grid or Loading Spinner
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildMovieGrid(),
          ),
        ],
      ),
    );
  }
}