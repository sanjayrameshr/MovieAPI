import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart'; // For debugPrint

class ApiService {
  static const String _apiKey = 'a76a6d736785c8171e40906b0886cb93';
  static const String _baseUrl = 'https://api.themoviedb.org/3';

  // Private helper method for making API requests
  static Future<List<dynamic>> _fetchData(String endpoint, {String? query}) async {
    Uri uri;
    if (query != null && query.isNotEmpty) {
      uri = Uri.parse('$_baseUrl$endpoint?api_key=$_apiKey&query=$query');
    } else {
      uri = Uri.parse('$_baseUrl$endpoint?api_key=$_apiKey');
    }

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Add basic validation for 'results' key
        if (data.containsKey('results') && data['results'] is List) {
          return data['results'];
        } else {
          debugPrint('API response does not contain a "results" list: ${response.body}');
          throw Exception('Invalid API response format');
        }
      } else {
        // More specific error messages based on status code
        String errorMessage;
        switch (response.statusCode) {
          case 401:
            errorMessage = 'Unauthorized: Invalid API key or access token.';
            break;
          case 404:
            errorMessage = 'Resource not found.';
            break;
          case 500:
            errorMessage = 'Server error. Please try again later.';
            break;
          default:
            errorMessage = 'Failed to load data. Status code: ${response.statusCode}';
        }
        debugPrint('API Error for $uri: $errorMessage - ${response.body}');
        throw Exception(errorMessage);
      }
    } catch (e) {
      // Catch network or parsing errors
      debugPrint('Network or decoding error for $uri: $e');
      throw Exception('An error occurred: Please check your internet connection.');
    }
  }

  /// Fetches a list of popular movies.
  /// Throws an [Exception] if the API call fails.
  static Future<List<dynamic>> fetchPopularMovies() async {
    return _fetchData('/movie/popular');
  }

  /// Searches for movies based on a query string.
  /// Throws an [Exception] if the API call fails.
  static Future<List<dynamic>> searchMovies(String query) async {
    if (query.isEmpty) {
      // Return empty list immediately for empty queries without making API call
      return [];
    }
    return _fetchData('/search/movie', query: Uri.encodeComponent(query)); // Encode query
  }

  /// Fetches a list of top-rated movies.
  /// Throws an [Exception] if the API call fails.
  static Future<List<dynamic>> fetchTopRatedMovies() async {
    return _fetchData('/movie/top_rated');
  }

  /// Fetches detailed information for a specific movie.
  /// Returns a Map<String, dynamic> representing the movie details.
  /// Throws an [Exception] if the API call fails.
  static Future<Map<String, dynamic>> fetchMovieDetails(int movieId) async {
    final uri = Uri.parse('$_baseUrl/movie/$movieId?api_key=$_apiKey');

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        String errorMessage;
        switch (response.statusCode) {
          case 401:
            errorMessage = 'Unauthorized: Invalid API key or access token.';
            break;
          case 404:
            errorMessage = 'Movie not found.';
            break;
          case 500:
            errorMessage = 'Server error. Please try again later.';
            break;
          default:
            errorMessage = 'Failed to load movie details. Status code: ${response.statusCode}';
        }
        debugPrint('API Error for $uri: $errorMessage - ${response.body}');
        throw Exception(errorMessage);
      }
    } catch (e) {
      debugPrint('Network or decoding error for $uri: $e');
      throw Exception('An error occurred while fetching movie details. Please check your internet connection.');
    }
  }
}