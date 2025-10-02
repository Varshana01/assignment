import 'package:flutter/material.dart';
import 'PlaceDetails.dart';

class BookmarksPage extends StatelessWidget {
  const BookmarksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF87CEEB),
        title: const Text(
          "BOOKMARKS",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Times New Roman',
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildBookmarkCard(
            context,
            title: "Le Morne Brabant",
            imagePath: "assets/images/lemorne.png",
          ),
          _buildBookmarkCard(
            context,
            title: "Ferney Falaise Rouge",
            imagePath: "assets/images/ferney.png",
          ),
          _buildBookmarkCard(
            context,
            title: "Chamarel",
            imagePath: "assets/images/chamarel.png",
          ),
          _buildBookmarkCard(
            context,
            title: "Rochester Falls",
            imagePath: "assets/images/rochester.png",
          ),
        ],
      ),
    );
  }

  Widget _buildBookmarkCard(BuildContext context,
      {required String title, required String imagePath}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Background image
            Image.asset(
              imagePath,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
            ),

            // Semi-transparent overlay
            Container(
              height: 180,
              color: Colors.grey.withOpacity(0.35),
            ),

            // Title + icon row
            Positioned(
              left: 12,
              top: 12,
              right: 12,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 6),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                                color: Colors.black38,
                                offset: Offset(1, 1),
                                blurRadius: 3),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // Close (remove) button
                  Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black54,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.close,
                          size: 16, color: Colors.white),
                      onPressed: () {
                        // TODO: handle remove bookmark
                      },
                      padding: EdgeInsets.zero,
                      constraints:
                      const BoxConstraints(minWidth: 28, minHeight: 28),
                    ),
                  ),
                ],
              ),
            ),

            // Place Details button
            Positioned(
              left: 12,
              bottom: 12,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PlaceDetailsPage(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.arrow_right_alt, color: Colors.black),
                label: const Text(
                  "Place Details",
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
