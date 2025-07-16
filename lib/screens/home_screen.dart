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
  
  // New variable to track if the current view is a search result
  // This helps differentiate between an empty initial state and no search results found.
  bool _isDisplayingSearchResults = false; 

  @override
  void initState() {
    super.initState();
    _loadPopularMovies();
    // Add listener to search controller for clear button visibility
    _searchController.addListener(() {
      // This setState ensures the clear button visibility updates dynamically
      // as the text field content changes.
      setState(() {}); 

      // If the search bar is cleared by the user, revert to popular movies
      if (_searchController.text.isEmpty && _isDisplayingSearchResults) {
        _isDisplayingSearchResults = false; // No longer displaying search results
        _loadPopularMovies(); // Load popular movies
      }
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
        _isDisplayingSearchResults = false; // Not search results
        _movies = []; // Clear current movies before loading new ones
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
        _isDisplayingSearchResults = false; // Not search results
        _movies = []; // Clear current movies before loading new ones
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
    final trimmedQuery = query.trim();

    if (trimmedQuery.isEmpty) {
      // If query is empty, treat it as clearing the search.
      setState(() {
        _movies = [];
        _isDisplayingSearchResults = false; // No search results to display
        _isLoading = false;
        _currentMode = 'Popular'; // Revert to popular mode
      });
      _loadPopularMovies(); // Optionally reload popular movies
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _currentMode = 'Search';
        _isDisplayingSearchResults = true; // Actively displaying search results
        _movies = []; // Clear previous results immediately
      });
      final results = await ApiService.searchMovies(trimmedQuery);
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_movies.isEmpty) {
      if (_isDisplayingSearchResults && _searchController.text.isNotEmpty) {
        // No results for a specific search query
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.sentiment_dissatisfied, size: 60, color: Colors.grey[400]),
              const SizedBox(height: 10),
              Text(
                'No results found for "${_searchController.text.trim()}".',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 5),
              Text(
                'Try a different movie title!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ],
          ),
        );
      } else if (!_isDisplayingSearchResults && _currentMode == 'Popular') {
        // No popular movies found (e.g., API error or empty data)
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.movie_filter, size: 60, color: Colors.grey[400]),
              const SizedBox(height: 10),
              Text(
                'No popular movies available at the moment.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 5),
              Text(
                'Check your internet connection or try again later.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ],
          ),
        );
      } else if (!_isDisplayingSearchResults && _currentMode == 'TopRated') {
        // No top-rated movies found
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.movie_filter, size: 60, color: Colors.grey[400]),
              const SizedBox(height: 10),
              Text(
                'No top-rated movies available at the moment.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 5),
              Text(
                'Check your internet connection or try again later.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ],
          ),
        );
      } else {
        // Initial state or search cleared with no previous category selected
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search, size: 60, color: Colors.grey[400]),
              const SizedBox(height: 10),
              Text(
                'Search for movies or browse categories above!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ],
          ),
        );
      }
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
                          tag: movie['id'].toString(), // Unique tag for Hero animation
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
                                // The listener in initState will handle the _isDisplayingSearchResults and _loadPopularMovies
                              },
                            )
                          : null,
                      border: const OutlineInputBorder(),
                    ),
                    textInputAction: TextInputAction.search,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildMovieGrid(),
          ),
        ],
      ),
    );
  }
}