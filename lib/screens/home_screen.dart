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
    if (query.trim().isEmpty) return;
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
      return const Center(child: Text('No movies found.'));
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

        return InkWell(
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
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.broken_image),
                        ),
                      )
                    : Container(
                        color: Colors.grey.shade800,
                        child: const Center(child: Icon(Icons.image_not_supported)),
                      ),
              ),
              const SizedBox(height: 5),
              Text(
                movie['title'] ?? 'No Title',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Movie Browser')),
      body: Column(
        children: [
          // Buttons and Search Bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: _loadPopularMovies,
                  child: const Text('Popular'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _loadTopRatedMovies,
                  child: const Text('Top Rated'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onSubmitted: _searchMovies,
                    decoration: InputDecoration(
                      hintText: 'Search...',
                      suffixIcon: IconButton(
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

          const Divider(),

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
