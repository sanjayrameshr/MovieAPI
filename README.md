Movies API App
	A Flutter application that displays trending movies using the TMDB (The Movie Database) API. Users can explore trending movies, search for films, and view detailed movie information.

Features
	View trending movies

	Search movies by name

	Movie details: overview, rating, release date

	Clean and responsive Flutter UI

	API integration using http package

Folder Structure

	lib/
	├── main.dart
	├── screens/
	│   ├── home_screen.dart
	│   ├── movie_detail_screen.dart
	│   └── search_screen.dart
	└── services/
		└── api_service.dart
Getting Started
	Prerequisites
		Flutter installed

		TMDB API key (Get one)

Setup
	Clone the repository:
		git clone https://github.com/sanjayrameshr/movies-api-app.git

		cd movies-api-app
	Add your TMDB API key in api_service.dart:
		const String apiKey = 'YOUR_TMDB_API_KEY';
	Install dependencies:
		flutter pub get
	Run the app:
		flutter run

Dependencies
	http

Author
	Sanjay Ramesh
	https://github.com/sanjayrameshr • 
	(https://www.linkedin.com/in/sanjayrameshr)
