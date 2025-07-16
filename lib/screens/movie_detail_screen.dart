import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

class MovieDetailScreen extends StatelessWidget {
  final Map<String, dynamic> movie;

  const MovieDetailScreen({super.key, required this.movie});

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final imageUrl = movie['poster_path'] != null
        ? 'https://image.tmdb.org/t/p/w500${movie['poster_path']}'
        : null;

    final backdropUrl = movie['backdrop_path'] != null
        ? 'https://image.tmdb.org/t/p/w780${movie['backdrop_path']}'
        : null;

    // Safely get release date
    String? releaseDate = movie['release_date'];
    String formattedReleaseDate = 'N/A';
    if (releaseDate != null && releaseDate.isNotEmpty) {
      try {
        final DateTime parsedDate = DateTime.parse(releaseDate);
        formattedReleaseDate = DateFormat.yMMMd().format(parsedDate); // e.g., "Jan 1, 2023"
      } catch (e) {
        debugPrint('Error parsing release date: $e');
      }
    }

    // Safely get runtime (assuming 'runtime' key exists in your movie data for full details)
    // The search results from TMDB usually don't include 'runtime'. You'd need to fetch
    // movie details using the movie ID if you want runtime here.
    // For now, we'll display 'N/A' if it's not present.
    String? runtime = movie['runtime'] != null ? '${movie['runtime']} min' : 'N/A';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: mediaQuery.size.height * 0.45, // Make header larger
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (backdropUrl != null)
                    CachedNetworkImage(
                      imageUrl: backdropUrl,
                      fit: BoxFit.cover,
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
                  // Dark overlay for better text readability
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
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          movie['title'] ?? 'Movie Details',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        if (movie['tagline'] != null && movie['tagline'].toString().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              movie['tagline'],
                              style: TextStyle(
                                fontSize: 16,
                                fontStyle: FontStyle.italic,
                                color: Colors.white.withOpacity(0.8),
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
                      // Movie Poster
                      if (imageUrl != null)
                        Hero(
                          tag: movie['id'].toString(),
                          child: ClipRRect( // ClipRRect for rounded corners
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: imageUrl,
                              // Define explicit width and height for the image container
                              width: mediaQuery.size.width * 0.4, // Keep the width as a proportion of screen width
                              height: mediaQuery.size.height * 0.25, // Keep the height as a proportion of screen height
                              fit: BoxFit.cover, // This is crucial: scale the image to cover the box, cropping if necessary
                              placeholder: (context, url) => Container( // Placeholder should match dimensions
                                width: mediaQuery.size.width * 0.4,
                                height: mediaQuery.size.height * 0.25,
                                color: Colors.grey.shade300,
                                child: const Center(child: CircularProgressIndicator()),
                              ),
                              errorWidget: (context, url, error) => Container( // Error widget should match dimensions
                                width: mediaQuery.size.width * 0.4,
                                height: mediaQuery.size.height * 0.25,
                                color: Colors.grey.shade300,
                                child: Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey[500])),
                              ),
                            ),
                          ),
                        )
                      else
                        Container( // Fallback for no image, also define explicit dimensions
                          width: mediaQuery.size.width * 0.4,
                          height: mediaQuery.size.height * 0.25,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey[500])),
                        ),
                      const SizedBox(width: 20),
                      // Details next to poster
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (movie['vote_average'] != null)
                              _buildInfoRow(
                                icon: Icons.star_rate_rounded,
                                label: 'Rating:',
                                value: '${movie['vote_average'].toStringAsFixed(1)} / 10', // Format to one decimal
                                valueStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            const SizedBox(height: 8),
                            _buildInfoRow(
                              icon: Icons.calendar_today,
                              label: 'Release Date:',
                              value: formattedReleaseDate,
                            ),
                            const SizedBox(height: 8),
                            // Display runtime (will be 'N/A' if not available in initial search data)
                            _buildInfoRow(
                              icon: Icons.access_time,
                              label: 'Runtime:',
                              value: runtime,
                            ),
                            const SizedBox(height: 8),
                            // Add more details here if available, e.g., genres, director
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
                  if (movie['overview'] != null && movie['overview'].toString().trim().isNotEmpty)
                    Text(
                      movie['overview'],
                      style: const TextStyle(fontSize: 16, height: 1.5), // Increased line height
                      textAlign: TextAlign.justify, // Justify text for better readability
                    )
                  else
                    const Text(
                      'No description available for this movie.',
                      style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.grey),
                    ),
                  const SizedBox(height: 20),
                  // You can add more sections here, e.g., Cast, Crew, Trailer
                  // Example:
                  // const Text(
                  //   'Cast',
                  //   style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  // ),
                  // const SizedBox(height: 8),
                  // Text('Coming soon...', style: TextStyle(fontStyle: FontStyle.italic)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget to build consistent info rows
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