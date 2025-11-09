import 'package:flutter/material.dart';
import 'offline_audio_player_page.dart'; // Make sure this exists

class OfflineLibraryPage extends StatelessWidget {
  final List<Map<String, dynamic>> offlineLyrics;

  const OfflineLibraryPage({super.key, required this.offlineLyrics});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Offline Library'),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF87CEEB), Color(0xFF00BFFF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.bottomCenter,
              child: Image.asset(
                'assets/beach_music_scene.png',
                fit: BoxFit.cover,
                height: 700,
              ),
            ),
            ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 16),
              itemCount: offlineLyrics.length,
              itemBuilder: (context, index) {
                final song = offlineLyrics[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.play_arrow),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade100,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    label: Text(
                      song['title'],
                      overflow: TextOverflow.ellipsis,
                    ),
                    onPressed: () {
                      final localPath = song['localPath'];
                      if (localPath != null && localPath.isNotEmpty) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LocalAudioPlayerPage(
                              audioPath: localPath,
                              title: song['title'],
                            ),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('No local file found.')),
                        );
                      }
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
