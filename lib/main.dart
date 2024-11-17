import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;



class Show {
  final String name;
  final String summary;
  final String imageUrl;
  final String showUrl;

  Show({required this.name, required this.summary, required this.imageUrl, required this.showUrl});

  factory Show.fromJson(Map<String, dynamic> json) {
    return Show(
      name: json['show']['name'] ?? 'N/A',
      summary: json['show']['summary'] ?? 'No summary available',
      imageUrl: json['show']['image'] != null ? json['show']['image']['medium'] : '',
      showUrl: json['show']['url'] ?? '',
    );
  }
}

void main() {
  runApp(const MyApp());

}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Netflix Clone',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.red,
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
        ),
      ),
      home: const ShowListScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ShowListScreen extends StatefulWidget {
  const ShowListScreen({super.key});

  @override
  _ShowListScreenState createState() => _ShowListScreenState();
}

class _ShowListScreenState extends State<ShowListScreen> {
  late Future<List<Show>> shows;
  final TextEditingController _searchController = TextEditingController();
  String _query = "all"; // Default query

  @override
  void initState() {
    super.initState();
    shows = fetchShows(_query);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Listener for search input changes
  void _onSearchChanged() {
    setState(() {
      _query = _searchController.text.trim();
      shows = fetchShows(_query.isEmpty ? "all" : _query);
    });
  }

  // Fetch shows with the given search query
  Future<List<Show>> fetchShows(String query) async {
    final response = await http.get(Uri.parse('https://api.tvmaze.com/search/shows?q=$query'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Show.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load shows');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Netflix',style: TextStyle(color: Colors.red,fontSize: 32),),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search shows...',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  border: InputBorder.none,
                  prefixIcon: const Icon(Icons.search, color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      ),
      body: FutureBuilder<List<Show>>(
        future: shows,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No data available'));
          } else {
            final shows = snapshot.data!;

            return GridView.builder(
              padding: const EdgeInsets.all(8.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 0.6,
              ),
              itemCount: shows.length,
              itemBuilder: (context, index) {
                final show = shows[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ShowDetailScreen(
                         // showUrl: show.showUrl,
                          showName: show.name,
                          showSummary: show.summary,
                          imageUrl: show.imageUrl,
                        ),
                      ),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4.0),
                          child: show.imageUrl.isNotEmpty
                              ? Image.network(
                            show.imageUrl,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          )
                              : Container(
                            color: Colors.grey[800],
                            child: const Icon(Icons.tv, color: Colors.white, size: 50),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        show.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
class ShowDetailScreen extends StatelessWidget {
  final String showName;
  final String showSummary;
  final String imageUrl;

  const ShowDetailScreen({
    super.key,
    required this.showName,
    required this.showSummary,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          showName,
          style: const TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Show Image
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10.0),
                child: imageUrl.isNotEmpty
                    ? Image.network(
                  imageUrl,
                  width: double.infinity,
                  height: 400,
                  fit: BoxFit.cover,
                )
                    : Container(
                  color: Colors.grey[800],
                  height: 400,
                  child: const Icon(Icons.tv, color: Colors.white, size: 100),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Show Title
            Text(
              showName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),

            // Summary
            const Text(
              "Summary",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.redAccent,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              showSummary.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ''), // Remove HTML tags
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
