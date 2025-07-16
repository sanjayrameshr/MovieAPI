import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/api_service.dart';
import 'movie_detail_screen.dart'; // Import MovieDetailScreen

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> _movies = [];
  String _currentMode = 'Popular'; // Tracks the currently displayed category: 'Popular', 'TopRated', or 'Search'
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();
  
  // New state variable to explicitly track if the current display is a result of a search query.
  // This helps in showing specific empty states for searches vs. category Browse.
  bool _isDisplayingSearchResults = false; 

  @override
  void initState() {
    super.initState();
    _loadPopularMovies(); // Load popular movies initially

    // Listener for the search text field.
    // It updates the UI (e.g., shows/hides clear button) and manages state
    // when the search text is manually cleared by the user.
    _searchController.addListener(() {
      // Trigger a rebuild to update the suffixIcon (clear button) visibility.
      setState(() {}); 

      // If the search bar becomes empty and we were previously displaying search results,
      // it implies the user cleared the search. Revert to showing popular movies.
      if (_searchController.text.isEmpty && _isDisplayingSearchResults) {
        _isDisplayingSearchResults = false; // No longer in search results mode
        _loadPopularMovies(); // Revert to loading popular movies
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose(); // Dispose the controller to prevent memory leaks
    super.dispose();
  }

  // Fetches popular movies
  void _loadPopularMovies() async {
    try {
      setState(() {
        _isLoading = true;
        _currentMode = 'Popular';
        _isDisplayingSearchResults = false; // Not displaying search results
        _movies = []; // Clear existing movies to show loading indicator immediately
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

  // Fetches top-rated movies
  void _loadTopRatedMovies() async {
    try {
      setState(() {
        _isLoading = true;
        _currentMode = 'TopRated';
        _isDisplayingSearchResults = false; // Not displaying search results
        _movies = []; // Clear existing movies to show loading indicator immediately
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

  // Searches for movies based on the provided query
  void _searchMovies(String query) async {
    final trimmedQuery = query.trim();

    // If the query is empty, treat it as clearing the search and revert state
    if (trimmedQuery.isEmpty) {
      setState(() {
        _movies = []; // Clear results
        _isDisplayingSearchResults = false; // No longer displaying search results
        _isLoading = false; // Stop any loading animation
        _currentMode = 'Popular'; // Reset mode for clarity
      });
      _loadPopularMovies(); // Reload popular movies after clearing search
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _currentMode = 'Search';
        _isDisplayingSearchResults = true; // We are now in search results mode
        _movies = []; // Clear previous results to show loading state for new search
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

  // Centralized error handling and snackbar display
  void _handleError(String contextText, Object e) {
    setState(() => _isLoading = false);
    debugPrint('Error while fetching $contextText: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to load $contextText. Please try again.')),
    );
  }

  // Builds the movie grid or appropriate empty/loading state message
  Widget _buildMovieGrid() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Handle empty states based on the current mode and search status
    if (_movies.isEmpty) {
      if (_isDisplayingSearchResults && _searchController.text.isNotEmpty) {
        // Case: A search was performed, but no results were found.
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
        // Case: No popular movies available (e.g., API error or empty data for this category).
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
        // Case: No top-rated movies available.
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
        // Default message for an unexpected empty state or before any content is loaded.
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

    // If movies are available, display the grid
    return GridView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: _movies.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2 / 3, // Standard poster aspect ratio (width/height)
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (context, index) {
        final movie = _movies[index];
        final imageUrl = movie['poster_path'] != null
            ? 'https://image.tmdb.org/t/p/w500${movie['poster_path']}' // w500 is a good size for grid
            : null;

        return Card(
          clipBehavior: Clip.antiAlias, // Ensures content respects card's rounded corners
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 3, // Subtle shadow for card effect
          child: InkWell(
            onTap: () {
              // Navigate to MovieDetailScreen, passing the movie data (which will then fetch full details)
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
                            fit: BoxFit.cover, // Scales and crops image to fill the space
                            placeholder: (context, url) =>
                                const Center(child: CircularProgressIndicator()),
                            errorWidget: (context, url, error) => Center(
                              child: Icon(Icons.broken_image,
                                  size: 40, color: Colors.grey[400]),
                            ),
                          ),
                        )
                      : Container(
                          color: Colors.grey.shade200, // Background for no image
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
                    maxLines: 2, // Allow title to span two lines
                    overflow: TextOverflow.ellipsis, // Truncate with ellipsis if longer
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
          // Buttons for categories and Search Bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    _searchController.clear(); // Clear search field when switching category
                    _loadPopularMovies();
                  },
                  // Style button to indicate active mode
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
                    _searchController.clear(); // Clear search field when switching category
                    _loadTopRatedMovies();
                  },
                  // Style button to indicate active mode
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
                    onSubmitted: _searchMovies, // Trigger search on submit
                    decoration: InputDecoration(
                      hintText: 'Search...',
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear(); // Clearing text triggers listener
                              },
                            )
                          : null, // No clear button if text is empty
                      border: const OutlineInputBorder(),
                    ),
                    textInputAction: TextInputAction.search, // Keyboard action button
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1), // Thinner divider
          // The main content area: movie grid or empty/loading state
          Expanded(
            child: _buildMovieGrid(),
          ),
        ],
      ),
    );
  }
}