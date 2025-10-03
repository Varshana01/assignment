import 'package:flutter/material.dart';

class PlaceDetailsPage extends StatefulWidget {
  final Map<String, dynamic> place; // Place info passed from NearbyPlacesPage

  const PlaceDetailsPage({super.key, required this.place});

  @override
  _PlaceDetailsPageState createState() => _PlaceDetailsPageState();
}

class _PlaceDetailsPageState extends State<PlaceDetailsPage> {
  bool isBookmarked = false; // Tracks if this place is bookmarked

  // Hardcoded reviews
  final List<Map<String, dynamic>> reviews = [
    {
      "username": "Alice",
      "rating": 5,
      "comment": "Amazing experience! Highly recommend visiting.",
    },
    {
      "username": "Bob",
      "rating": 4,
      "comment": "Great place, but can get crowded at times.",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.place['name']),
        backgroundColor: Colors.teal,
        actions: [
          // Bookmark button (heart icon)
          IconButton(
            icon: Icon(
              isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: Colors.white,
            ),
            onPressed: () {
              // Toggle bookmark state
              setState(() {
                isBookmarked = !isBookmarked;
              });

              // Show feedback to the user
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isBookmarked
                        ? "Added to bookmarks"
                        : "Removed from bookmarks",
                  ),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Place image
            Image.network(
              widget.place['imageUrl'],
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),

            const SizedBox(height: 16),

            // Place name
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                widget.place['name'],
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Place description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                widget.place['description'],
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              ),
            ),

            const SizedBox(height: 20),

            // Reviews Section
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "Reviews",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 10),

            // Show each review in a card
            ...reviews.map((review) {
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(review['username'][0]), // First letter of name
                  ),
                  title: Text(review['username']),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Star rating
                      Row(
                        children: List.generate(
                          5,
                          (index) => Icon(
                            index < review['rating']
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                            size: 18,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(review['comment']),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
