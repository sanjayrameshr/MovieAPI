import 'package:flutter/material.dart';

class MovieDetailScreen extends StatelessWidget {
  final Map<String, dynamic> movie;

  const MovieDetailScreen({super.key, required this.movie});

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final imageUrl = movie['poster_path'] != null
        ? 'https://image.tmdb.org/t/p/w500${movie['poster_path']}'
        : null;

    return Scaffold(
      appBar: AppBar(title: Text(movie['title'] ?? 'Movie Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl != null)
              Center(
                child: Image.network(imageUrl, height: mediaQuery.size.height * 0.6, fit: BoxFit.cover),
              ),
            const SizedBox(height: 20),
            Text(
              movie['title'] ?? 'No Title',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            if (movie['vote_average'] != null)
              Text(
                'Rating: ${movie['vote_average'].toString()} ⭐',
                style: const TextStyle(fontSize: 18),
              ),
            const SizedBox(height: 10),
            if (movie['overview'] != null && movie['overview'].toString().trim().isNotEmpty)
              Text(
                movie['overview'],
                style: const TextStyle(fontSize: 16),
              )
            else
              const Text(
                'No description available.',
                style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
              ),
          ],
        ),
      ),
    );
  }
}
