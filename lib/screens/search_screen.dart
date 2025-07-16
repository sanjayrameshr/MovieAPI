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
  // This flag helps differentiate between initial screen load and
  // an empty result set after a user has performed a search.
  bool _hasSearched = false; 

  @override
  void initState() {
    super.initState();
    // Add a listener to the search controller to manage the UI state.
    // This allows for dynamic showing/hiding of the clear button and
    // resetting the results if the user clears the text manually.
    _controller.addListener(() {
      // Trigger a rebuild to update the suffixIcon (clear button) visibility.
      setState(() {}); 

      // If the text field becomes empty and a search was previously performed,
      // clear the search results and reset the 'hasSearched' flag.
      if (_controller.text.isEmpty && _hasSearched) {
        setState(() {
          _searchResults = [];
          _hasSearched = false; // Revert to initial state message
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose(); // Dispose the controller to prevent memory leaks
    super.dispose();
  }

  // Initiates a movie search based on the provided query.
  void _search(String query) async {
    final trimmedQuery = query.trim(); // Remove leading/trailing whitespace

    // If the query is empty, clear current results and reset to initial state.
    if (trimmedQuery.isEmpty) {
      setState(() {
        _searchResults = [];
        _isLoading = false;
        _hasSearched = false; // No active search
      });
      return;
    }

    // Set loading state and clear previous results before making the API call.
    setState(() {
      _isLoading = true;
      _hasSearched = true; // Mark that a search has been initiated
      _searchResults = []; // Clear previous results immediately for new search
    });

    try {
      final results = await ApiService.searchMovies(trimmedQuery);
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      // Handle API errors during search
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
            padding: const EdgeInsets.all(12.0), // Consistent padding
            child: TextField(
              controller: _controller,
              onSubmitted: _search, // Trigger search when user presses enter/done
              decoration: InputDecoration(
                hintText: 'Search by movie title...', // Descriptive hint
                prefixIcon: const Icon(Icons.search), // Search icon inside the field
                suffixIcon: _controller.text.isNotEmpty // Show clear button if there's text
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _controller.clear(); // Clearing text will trigger the listener
                          // The listener handles the _search('') call to reset results
                        },
                      )
                    : null, // No suffix icon if text is empty
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0), // Rounded corners
                  borderSide: BorderSide.none, // No visible border lines
                ),
                filled: true, // Enable fill color
                fillColor: Colors.grey[200], // Light background for the text field
                contentPadding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0), // Adjust text padding
              ),
              textInputAction: TextInputAction.search, // Keyboard shows a 'Search' button
            ),
          ),
          if (_isLoading)
            // Show loading indicator
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(), 
            )
          else if (_hasSearched && _searchResults.isEmpty) 
            // Message when a search was performed but yielded no results
            Expanded(
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
          else if (!_hasSearched && _searchResults.isEmpty) 
            // Initial state: user hasn't searched yet, show a prompt
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
          else 
            // Display search results in a list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final movie = _searchResults[index];
                  // Use w185 for search list thumbnails
                  final imageUrl = movie['poster_path'] != null
                      ? 'https://image.tmdb.org/t/p/w185${movie['poster_path']}' 
                      : null;

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    elevation: 4, // Add subtle shadow for card effect
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                    child: InkWell(
                      onTap: () {
                        // Navigate to MovieDetailScreen when a movie card is tapped
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MovieDetailScreen(movie: movie),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start, // Align content to the top
                          children: [
                            ClipRRect( // Clip image for rounded corners
                              borderRadius: BorderRadius.circular(8.0),
                              child: imageUrl != null
                                  ? CachedNetworkImage(
                                      imageUrl: imageUrl,
                                      width: 80, // Fixed width for consistent layout
                                      height: 120, // Fixed height for consistent layout (aspect ratio 2:3)
                                      fit: BoxFit.cover, // Scales and crops to fill the box
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
                                  : Container( // Fallback for no poster image
                                      width: 80, height: 120,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade300,
                                        borderRadius: BorderRadius.circular(8.0),
                                      ),
                                      child: Center(child: Icon(Icons.image_not_supported, size: 40, color: Colors.grey[500])),
                                    ),
                            ),
                            const SizedBox(width: 15), // Spacing between image and text details
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
                                    maxLines: 2, // Allow title to span up to two lines
                                    overflow: TextOverflow.ellipsis, // Truncate with ellipsis if longer
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
                                        '${movie['vote_average']?.toStringAsFixed(1) ?? 'N/A'} / 10', // Format rating to one decimal
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
                                    maxLines: 3, // Show a brief snippet of the overview
                                    overflow: TextOverflow.ellipsis, // Truncate with ellipsis if longer
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