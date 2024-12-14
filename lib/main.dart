import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MovieSpotApp());
}

class MovieSpotApp extends StatelessWidget {
  const MovieSpotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.red,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          elevation: 0,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.black,
          selectedItemColor: Colors.red,
          unselectedItemColor: Colors.grey,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

// Splash Screen
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  SplashScreenState createState() => SplashScreenState();
}
class SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/logo.png', // Replace with your splash image/logo
              width: 250,
              height: 250,
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(color: Colors.red),
          ],
        ),
      ),
    );
  }
}


// Home Screen
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  List<dynamic> movies = [];
  int currentPage = 0; // Tracks the current page of results
  bool isLoading = true;
  bool isFetchingMore = false; // Prevents multiple simultaneous fetches
  final ScrollController _scrollController =
      ScrollController(); // For detecting scroll

  @override
  void initState() {
    super.initState();
    fetchMovies(); // Fetch initial data
    _scrollController.addListener(_onScroll); // Listen for scroll events
  }

  @override
  void dispose() {
    _scrollController.dispose(); // Clean up the controller
    super.dispose();
  }

  Future<void> fetchMovies() async {
    setState(() {
      isLoading =
          currentPage == 0; // Only show initial loader for the first load
      isFetchingMore =
          currentPage > 0; // Show "loading more" only for additional pages
    });

    final response = await http.get(
      Uri.parse('https://api.tvmaze.com/shows?page=$currentPage'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> fetchedMovies = json.decode(response.body);
      setState(() {
        movies.addAll(fetchedMovies); // Append new movies to the list
        currentPage++; // Increment page for the next API call
        isLoading = false;
        isFetchingMore = false;
      });
    } else {
      setState(() {
        isLoading = false;
        isFetchingMore = false;
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!isFetchingMore) {
        fetchMovies(); // Fetch more movies when near the bottom
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'MovieSpot',
          style: TextStyle(
              fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchScreen()),
              );
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.red))
          : Column(
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      int crossAxisCount = 2; // Default for mobile
                      double childAspectRatio = 2 / 3;

                      if (constraints.maxWidth >= 1200) {
                        // Desktop
                        crossAxisCount = 6;
                        childAspectRatio = 3 / 4;
                      } else if (constraints.maxWidth >= 800) {
                        // Tablet
                        crossAxisCount = 4;
                        childAspectRatio = 2 / 3;
                      }

                      return GridView.builder(
                        controller:
                            _scrollController, // Attach scroll controller
                        padding: const EdgeInsets.all(8),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: childAspectRatio,
                        ),
                        itemCount: movies.length,
                        itemBuilder: (context, index) {
                          final movie = movies[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      DetailsScreen(movie: movie),
                                ),
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(
                                  image: NetworkImage(
                                    movie['image']?['medium'] ??
                                        'https://via.placeholder.com/150',
                                  ),
                                  fit: BoxFit.cover,
                                ),
                              ),
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 8, horizontal: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.7),
                                    borderRadius: const BorderRadius.vertical(
                                      bottom: Radius.circular(8),
                                    ),
                                  ),
                                  child: Text(
                                    movie['name'],
                                    style: TextStyle(
                                      fontSize:
                                          MediaQuery.of(context).size.width *
                                              0.02,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                if (isFetchingMore)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(color: Colors.red),
                  ),
              ],
            ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
        ],
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          } else if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SearchScreen()),
            );
          }
        },
      ),
    );
  }
}


// Search Screen
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  SearchScreenState createState() => SearchScreenState();
}


class SearchScreenState extends State<SearchScreen> {
  List<dynamic> searchResults = [];
  TextEditingController searchController = TextEditingController();
  bool isLoading = false;

  Future<void> searchMovies(String query) async {
    if (query.isEmpty) return;

    setState(() {
      isLoading = true;
    });

    final response = await http
        .get(Uri.parse('https://api.tvmaze.com/search/shows?q=$query'));
    if (response.statusCode == 200) {
      setState(() {
        searchResults = json.decode(response.body);
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 1200;
    final isTablet = size.width >= 800 && size.width < 1200;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Expanded(
              child: TextField(
                controller: searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search movies...',
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.black,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search, color: Colors.white),
                    onPressed: () => searchMovies(searchController.text),
                  ),
                ),
                onSubmitted: (value) {
                  searchMovies(value); // Trigger search when "Enter" is pressed
                },
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () {
                setState(() {
                  searchController.clear();
                  searchResults = [];
                });
              },
            ),
          ],
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.red),
            )
          : searchResults.isEmpty
              ? const Center(
                  child: Text(
                    'No results found. Start searching!',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(8),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      int crossAxisCount = 2;
                      double childAspectRatio = 2 / 3;

                      if (isDesktop) {
                        crossAxisCount = 6;
                        childAspectRatio = 3 / 4;
                      } else if (isTablet) {
                        crossAxisCount = 4;
                        childAspectRatio = 2 / 3;
                      }

                      return GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: childAspectRatio,
                        ),
                        itemCount: searchResults.length,
                        itemBuilder: (context, index) {
                          final movie = searchResults[index]['show'];
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      DetailsScreen(movie: movie),
                                ),
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(
                                  image: NetworkImage(
                                    movie['image']?['medium'] ??
                                        'https://via.placeholder.com/150',
                                  ),
                                  fit: BoxFit.cover,
                                ),
                              ),
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 8, horizontal: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.7),
                                    borderRadius: const BorderRadius.vertical(
                                      bottom: Radius.circular(8),
                                    ),
                                  ),
                                  child: Text(
                                    movie['name'],
                                    style: TextStyle(
                                      fontSize: isDesktop
                                          ? 16
                                          : isTablet
                                              ? 14
                                              : 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
    );
  }
}


class DetailsScreen extends StatelessWidget {
  final dynamic movie;
  const DetailsScreen({super.key, required this.movie});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 1200;
    final isTablet = size.width >= 800 && size.width < 1200;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          movie['name'],
          style: TextStyle(
              fontSize: isDesktop
                  ? 28
                  : isTablet
                  ? 22
                  : 18),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: size.width * 0.05),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Section
              SizedBox(
                width: double.infinity,
                height: isDesktop
                    ? size.height * 0.5
                    : isTablet
                    ? size.height * 0.4
                    : size.height * 0.3,
                child: movie['image'] != null
                    ? Image.network(movie['image']['original'],
                    fit: BoxFit.cover)
                    : Image.network(
                  'https://via.placeholder.com/300',
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 16),

              // Title Section
              Text(
                movie['name'],
                style: TextStyle(
                  fontSize: isDesktop
                      ? 36
                      : isTablet
                      ? 28
                      : 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Summary Section
              Text(
                movie['summary'] != null
                    ? _stripHtmlTags(movie['summary'])
                    : 'No description available',
                style: TextStyle(
                  fontSize: isDesktop
                      ? 18
                      : isTablet
                      ? 16
                      : 14,
                ),textAlign: TextAlign.justify,
              ),
              const SizedBox(height: 16),

              // Additional Details Section
              if (movie['rating'] != null)
                Text(
                  'Rating: ${movie['rating']['average'] ?? 'N/A'}',
                  style: TextStyle(
                    fontSize: isDesktop
                        ? 18
                        : isTablet
                        ? 16
                        : 14,
                  ),
                ),
              const SizedBox(height: 8),

              // Network
              Text(
                'Network: ${movie['network'] != null ? movie['network']['name'] : 'N/A'}',
                style: TextStyle(
                  fontSize: isDesktop
                      ? 18
                      : isTablet
                      ? 16
                      : 14,
                ),
              ),
              const SizedBox(height: 8),

            ],
          ),
        ),
      ),
    );
  }

  String _stripHtmlTags(String htmlText) {
    final RegExp exp = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);
    return htmlText.replaceAll(exp, '');
  }


}
