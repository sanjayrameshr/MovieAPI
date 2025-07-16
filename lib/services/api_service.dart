import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart'; // For debugPrint

class ApiService {
  // IMPORTANT: Replace with your actual TMDb API key
  // You can get one from https://www.themoviedb.org/documentation/api
  static const String _apiKey = 'a76a6d736785c8171e40906b0886cb93';
  static const String _baseUrl = 'https://api.themoviedb.org/3';

  // Private helper method for making API requests that return a list of results
  static Future<List<dynamic>> _fetchMovieListData(String endpoint, {String? query}) async {
    Uri uri;
    if (query != null && query.isNotEmpty) {
      // Ensure query parameters are properly encoded for URLs
      uri = Uri.parse('$_baseUrl$endpoint?api_key=$_apiKey&query=${Uri.encodeComponent(query)}');
    } else {
      uri = Uri.parse('$_baseUrl$endpoint?api_key=$_apiKey');
    }

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Validate if the response contains the expected 'results' list
        if (data.containsKey('results') && data['results'] is List) {
          return data['results'];
        } else {
          debugPrint('API response for $endpoint does not contain a "results" list: ${response.body}');
          throw Exception('Invalid API response format for movie list');
        }
      } else {
        // Handle various HTTP error codes with specific messages
        String errorMessage;
        switch (response.statusCode) {
          case 401:
            errorMessage = 'Unauthorized: Invalid API key or access token. Please check your API key.';
            break;
          case 404:
            errorMessage = 'Resource not found at $endpoint.';
            break;
          case 500:
            errorMessage = 'Server error. Please try again later.';
            break;
          default:
            errorMessage = 'Failed to load data for $endpoint. Status code: ${response.statusCode}';
        }
        debugPrint('API Error for $uri: $errorMessage - Response Body: ${response.body}');
        throw Exception(errorMessage);
      }
    } catch (e) {
      // Catch network-related errors (e.g., no internet, DNS lookup failed) or JSON parsing errors
      debugPrint('Network or decoding error for $uri: $e');
      throw Exception('An error occurred: Please check your internet connection and try again.');
    }
  }

  /// Fetches a list of popular movies from the API.
  /// Throws an [Exception] if the API call fails.
  static Future<List<dynamic>> fetchPopularMovies() async {
    return _fetchMovieListData('/movie/popular');
  }

  /// Searches for movies based on a provided query string.
  /// Returns an empty list immediately if the query is empty.
  /// Throws an [Exception] if the API call fails.
  static Future<List<dynamic>> searchMovies(String query) async {
    if (query.isEmpty) {
      return []; // No API call needed for empty query
    }
    return _fetchMovieListData('/search/movie', query: query);
  }

  /// Fetches a list of top-rated movies from the API.
  /// Throws an [Exception] if the API call fails.
  static Future<List<dynamic>> fetchTopRatedMovies() async {
    return _fetchMovieListData('/movie/top_rated');
  }

  /// Fetches detailed information for a specific movie using its ID.
  /// This includes fields like 'runtime', 'genres', 'tagline', etc.,
  /// which might not be present in list results.
  /// Returns a Map<String, dynamic> representing the movie details.
  /// Throws an [Exception] if the API call fails.
  static Future<Map<String, dynamic>> fetchMovieDetails(int movieId) async {
    final uri = Uri.parse('$_baseUrl/movie/$movieId?api_key=$_apiKey');

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data; // This response directly contains all the movie details
      } else {
        String errorMessage;
        switch (response.statusCode) {
          case 401:
            errorMessage = 'Unauthorized: Invalid API key or access token.';
            break;
          case 404:
            errorMessage = 'Movie with ID $movieId not found.';
            break;
          case 500:
            errorMessage = 'Server error. Please try again later.';
            break;
          default:
            errorMessage = 'Failed to load movie details for ID $movieId. Status code: ${response.statusCode}';
        }
        debugPrint('API Error for $uri: $errorMessage - Response Body: ${response.body}');
        throw Exception(errorMessage);
      }
    } catch (e) {
      debugPrint('Network or decoding error for $uri: $e');
      throw Exception('An error occurred while fetching movie details. Please check your internet connection.');
    }
  }
}