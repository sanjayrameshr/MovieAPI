import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'movie_detail_screen.dart'; // Import MovieDetailScreen

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isLoading = false;
  bool _hasSearched = false; // To differentiate between initial load and no results after search

  // Add a listener to clear search results when the text field is cleared manually
  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      if (_controller.text.isEmpty && _hasSearched) {
        setState(() {
          _searchResults = [];
          _hasSearched = false; // Reset to initial state if query is empty
        });
      }
      // This setState ensures the clear button visibility updates dynamically
      // as the text field content changes.
      setState(() {}); 
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _search(String query) async {
    // Trim query to handle accidental spaces
    final trimmedQuery = query.trim();

    if (trimmedQuery.isEmpty) {
      setState(() {
        _searchResults = [];
        _isLoading = false;
        _hasSearched = false; // Reset to initial state if query is empty
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasSearched = true; // Mark that a search has been initiated
      _searchResults = []; // Clear previous results immediately
    });

    try {
      final results = await ApiService.searchMovies(trimmedQuery);
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _searchResults = []; // Clear results on error
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to search movies. Please try again.')),
      );
      debugPrint('Error searching movies: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Movies'),
        centerTitle: true, // Center the app bar title
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0), // Slightly more padding
            child: TextField(
              controller: _controller,
              onSubmitted: _search,
              decoration: InputDecoration(
                hintText: 'Search by movie title...', // More descriptive hint
                prefixIcon: const Icon(Icons.search), // Search icon inside the field
                suffixIcon: _controller.text.isNotEmpty // Show clear button if text exists
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _controller.clear();
                          _search(''); // Clear results and reset
                        },
                      )
                    : null, // No suffix icon if text is empty
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0), // Rounded corners for text field
                  borderSide: BorderSide.none, // Remove default border
                ),
                filled: true,
                fillColor: Colors.grey[200], // Light background for the text field
                contentPadding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0), // Adjust padding
              ),
              textInputAction: TextInputAction.search, // Show search button on keyboard
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(), // Centered and padded progress indicator
            )
          else if (_hasSearched && _searchResults.isEmpty) // Show message only if a search was performed and no results
            Expanded( // Use Expanded to center the message vertically
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.sentiment_dissatisfied, size: 60, color: Colors.grey[400]),
                    const SizedBox(height: 10),
                    Text(
                      'No results found for "${_controller.text.trim()}".',
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
              ),
            )
          else if (!_hasSearched && _searchResults.isEmpty) // Initial state before any search
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.movie_filter, size: 60, color: Colors.grey[400]),
                    const SizedBox(height: 10),
                    Text(
                      'Start by searching for a movie title!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            )
          else // Display search results
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0), // Padding for the list
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final movie = _searchResults[index];
                  final imageUrl = movie['poster_path'] != null
                      ? 'https://image.tmdb.org/t/p/w185${movie['poster_path']}' // Larger thumbnail
                      : null;

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0), // Spacing between cards
                    elevation: 4, // Add subtle shadow
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                    child: InkWell(
                      onTap: () {
                        // Navigate to MovieDetailScreen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MovieDetailScreen(movie: movie),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(12.0), // Padding inside the card
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect( // Clip poster for rounded corners
                              borderRadius: BorderRadius.circular(8.0),
                              child: imageUrl != null
                                  ? CachedNetworkImage(
                                      imageUrl: imageUrl,
                                      width: 80, // Larger width for better visibility
                                      height: 120, // Corresponding height
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Container(
                                            width: 80, height: 120,
                                            color: Colors.grey.shade300,
                                            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                          ),
                                      errorWidget: (context, url, error) => Container(
                                            width: 80, height: 120,
                                            color: Colors.grey.shade300,
                                            child: Center(child: Icon(Icons.image_not_supported, size: 40, color: Colors.grey[500])),
                                          ),
                                    )
                                  : Container(
                                      width: 80, height: 120,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade300,
                                        borderRadius: BorderRadius.circular(8.0),
                                      ),
                                      child: Center(child: Icon(Icons.image_not_supported, size: 40, color: Colors.grey[500])),
                                    ),
                            ),
                            const SizedBox(width: 15), // Spacing between image and text
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    movie['title'] ?? 'No title',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 5),
                                  if (movie['release_date'] != null && movie['release_date'].toString().isNotEmpty)
                                    Text(
                                      'Release Date: ${movie['release_date']}',
                                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                                    ),
                                  const SizedBox(height: 5),
                                  Row(
                                    children: [
                                      Icon(Icons.star, color: Colors.amber, size: 20),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${movie['vote_average']?.toStringAsFixed(1) ?? 'N/A'} / 10', // Format rating
                                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    movie['overview'] != null && movie['overview'].toString().isNotEmpty
                                        ? movie['overview']
                                        : 'No overview available.',
                                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                                    maxLines: 3, // Show a snippet of the overview
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}