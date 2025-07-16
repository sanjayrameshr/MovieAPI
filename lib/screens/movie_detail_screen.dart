import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart'; // Required for date formatting
import '../services/api_service.dart'; // Import ApiService

class MovieDetailScreen extends StatefulWidget {
  // Initial movie data, typically from a list/search result.
  // This might only contain basic info (id, title, poster, overview).
  final Map<String, dynamic> movie; 

  const MovieDetailScreen({super.key, required this.movie});

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  // This will store the full movie details fetched from the API
  Map<String, dynamic>? _fullMovieDetails; 
  bool _isLoadingDetails = true; // To show loading state for details fetch
  String _errorMessage = ''; // To display error message if details fetch fails

  @override
  void initState() {
    super.initState();
    _fetchFullMovieDetails(); // Start fetching full details when screen initializes
  }

  // Fetches comprehensive movie details using the movie ID
  Future<void> _fetchFullMovieDetails() async {
    try {
      setState(() {
        _isLoadingDetails = true;
        _errorMessage = '';
      });
      // Call ApiService to get full details for the movie using its ID
      final details = await ApiService.fetchMovieDetails(widget.movie['id']);
      setState(() {
        _fullMovieDetails = details; // Update state with full details
        _isLoadingDetails = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load movie details: ${e.toString()}'; // Capture error message
        _isLoadingDetails = false;
      });
      debugPrint('Error fetching full movie details: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    
    // Use _fullMovieDetails if it has been successfully loaded; otherwise,
    // fallback to the partial 'widget.movie' data passed from the previous screen.
    final movieData = _fullMovieDetails ?? widget.movie;

    // Construct image URLs safely
    final imageUrl = movieData['poster_path'] != null
        ? 'https://image.tmdb.org/t/p/w500${movieData['poster_path']}'
        : null;

    final backdropUrl = movieData['backdrop_path'] != null
        ? 'https://image.tmdb.org/t/p/w780${movieData['backdrop_path']}' // Larger size for backdrop
        : null;

    // Safely format release date
    String? releaseDate = movieData['release_date'];
    String formattedReleaseDate = 'N/A';
    if (releaseDate != null && releaseDate.isNotEmpty) {
      try {
        final DateTime parsedDate = DateTime.parse(releaseDate);
        formattedReleaseDate = DateFormat.yMMMd().format(parsedDate); // e.g., "Jul 16, 2025"
      } catch (e) {
        debugPrint('Error parsing release date: $e');
      }
    }

    // Safely get runtime from the fetched full details (if available)
    String runtime = movieData['runtime'] != null
        ? '${movieData['runtime']} min'
        : 'N/A';

    // Safely get tagline from the fetched full details (if available)
    String tagline = movieData['tagline'] != null && movieData['tagline'].toString().isNotEmpty
        ? movieData['tagline']
        : '';

    // Safely get genres from the fetched full details (if available)
    String genres = 'N/A';
    if (movieData['genres'] != null && movieData['genres'] is List) {
      List<dynamic> genreList = movieData['genres'];
      if (genreList.isNotEmpty) {
        genres = genreList.map((g) => g['name']).join(', '); // Join genre names with comma
      }
    }

    return Scaffold(
      body: _isLoadingDetails // Show loading indicator while details are being fetched
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty // Show error message if fetching failed
              ? Center(child: Text(_errorMessage, textAlign: TextAlign.center, style: TextStyle(color: Colors.red)))
              : CustomScrollView( // Use CustomScrollView for the flexible app bar effect
                  slivers: [
                    SliverAppBar(
                      expandedHeight: mediaQuery.size.height * 0.45, // Dynamic header height
                      floating: false, // Does not float over content
                      pinned: true, // Stays visible at the top after collapsing
                      flexibleSpace: FlexibleSpaceBar(
                        // Title will be shown when app bar is collapsed
                        title: Text(
                          movieData['title'] ?? 'Movie Details',
                          style: TextStyle(
                            fontSize: 18, // Smaller font when collapsed
                            color: Colors.white,
                            // Add a shadow for better readability over busy backdrops
                            shadows: [
                              Shadow(
                                blurRadius: 4.0,
                                color: Colors.black.withOpacity(0.5),
                                offset: Offset(2.0, 2.0),
                              ),
                            ],
                          ),
                          overflow: TextOverflow.ellipsis, // Prevent overflow
                        ),
                        centerTitle: true, // Center the title in the collapsed app bar
                        background: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (backdropUrl != null)
                              CachedNetworkImage(
                                imageUrl: backdropUrl,
                                fit: BoxFit.cover, // Ensures backdrop fills the space, cropping if needed
                                placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                                errorWidget: (context, url, error) => Container(
                                  color: Colors.grey.shade900,
                                  child: Center(
                                    child: Icon(Icons.broken_image, size: 60, color: Colors.grey[600]),
                                  ),
                                ),
                              )
                            else
                              Container(
                                color: Colors.grey.shade900,
                                child: Center(
                                  child: Icon(Icons.movie, size: 80, color: Colors.grey[600]),
                                ),
                              ),
                            // Gradient overlay for better text readability on backdrop
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withOpacity(0.3),
                                    Colors.black.withOpacity(0.7),
                                  ],
                                ),
                              ),
                            ),
                            // Positioned title and tagline when app bar is expanded
                            Positioned(
                              bottom: 16,
                              left: 16,
                              right: 16,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    movieData['title'] ?? 'Movie Details',
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      shadows: [ // Add shadows for readability
                                        Shadow(blurRadius: 4.0, color: Colors.black, offset: Offset(2.0, 2.0)),
                                      ],
                                    ),
                                  ),
                                  if (tagline.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Text(
                                        tagline,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontStyle: FontStyle.italic,
                                          color: Colors.white.withOpacity(0.8),
                                          shadows: [ // Add shadows for readability
                                            Shadow(blurRadius: 4.0, color: Colors.black, offset: Offset(1.0, 1.0)),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Movie Poster (left side)
                                if (imageUrl != null)
                                  Hero( // Maintain Hero for smooth transition
                                    tag: movieData['id'].toString(),
                                    child: ClipRRect( // Rounded corners for poster
                                      borderRadius: BorderRadius.circular(8),
                                      child: CachedNetworkImage(
                                        imageUrl: imageUrl,
                                        // Explicit dimensions for poster to ensure fit
                                        width: mediaQuery.size.width * 0.4, 
                                        height: mediaQuery.size.height * 0.25,
                                        fit: BoxFit.cover, // Scales to cover, cropping if necessary
                                        placeholder: (context, url) => Container(
                                          width: mediaQuery.size.width * 0.4,
                                          height: mediaQuery.size.height * 0.25,
                                          color: Colors.grey.shade300,
                                          child: const Center(child: CircularProgressIndicator()),
                                        ),
                                        errorWidget: (context, url, error) => Container(
                                          width: mediaQuery.size.width * 0.4,
                                          height: mediaQuery.size.height * 0.25,
                                          color: Colors.grey.shade300,
                                          child: Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey[500])),
                                        ),
                                      ),
                                    ),
                                  )
                                else
                                  Container( // Fallback for no image
                                    width: mediaQuery.size.width * 0.4,
                                    height: mediaQuery.size.height * 0.25,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade300,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Center(child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey[500])),
                                  ),
                                const SizedBox(width: 20),
                                // Details next to poster (right side)
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (movieData['vote_average'] != null)
                                        _buildInfoRow(
                                          icon: Icons.star_rate_rounded,
                                          label: 'Rating:',
                                          value: '${movieData['vote_average'].toStringAsFixed(1)} / 10',
                                          valueStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                      const SizedBox(height: 8),
                                      _buildInfoRow(
                                        icon: Icons.calendar_today,
                                        label: 'Release Date:',
                                        value: formattedReleaseDate,
                                      ),
                                      const SizedBox(height: 8),
                                      _buildInfoRow(
                                        icon: Icons.access_time,
                                        label: 'Runtime:',
                                        value: runtime,
                                      ),
                                      const SizedBox(height: 8),
                                      _buildInfoRow(
                                        icon: Icons.category,
                                        label: 'Genres:',
                                        value: genres,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Overview',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            if (movieData['overview'] != null && movieData['overview'].toString().trim().isNotEmpty)
                              Text(
                                movieData['overview'],
                                style: const TextStyle(fontSize: 16, height: 1.5),
                                textAlign: TextAlign.justify,
                              )
                            else
                              const Text(
                                'No description available for this movie.',
                                style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.grey),
                              ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  // Helper widget to build consistent info rows (reusable across details)
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    TextStyle labelStyle = const TextStyle(fontSize: 16, color: Colors.grey),
    TextStyle valueStyle = const TextStyle(fontSize: 16),
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.orange), // Accent color for icons
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: labelStyle),
              Text(value, style: valueStyle),
            ],
          ),
        ),
      ],
    );
  }
}