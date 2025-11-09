import 'package:emo_sik/youtube_player_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import 'LocalAudioPlayerPage.dart';

class EmotionBasedSongListPage extends StatefulWidget {
  final String emotion; // from detection
  const EmotionBasedSongListPage({super.key, required this.emotion});

  @override
  State<EmotionBasedSongListPage> createState() => _EmotionBasedSongListPageState();
}

class _EmotionBasedSongListPageState extends State<EmotionBasedSongListPage> {
  List<Map<String, dynamic>> _filteredSongs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserSongs();
  }

  Future<void> _fetchUserSongs() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final dbRef = FirebaseDatabase.instance.ref('users/${user.uid}/playlists');
    final snapshot = await dbRef.get();

    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      final List<Map<String, dynamic>> filtered = [];

      data.forEach((_, value) {
        final song = Map<String, dynamic>.from(value);
        if ((song['analyzedEmotion'] ?? '').toLowerCase() == widget.emotion.toLowerCase()) {
          filtered.add(song);
        }
      });

      setState(() {
        _filteredSongs = filtered;
        _loading = false;
      });
    } else {
      setState(() {
        _filteredSongs = [];
        _loading = false;
      });
    }
  }

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
        title: Text('${widget.emotion.capitalize()} Songs'),
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
              child: FractionallySizedBox(
                widthFactor: 1,
                child: Image.asset(
                  'assets/beach_music_scene.png',
                  fit: BoxFit.cover,
                  height: 700, // Adjust as needed
                ),
              ),
            ),
            SafeArea(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                  : _filteredSongs.isEmpty
                  ? Center(
                child: Text(
                  'No songs found for "${widget.emotion}" emotion.',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: _filteredSongs.length,
                itemBuilder: (context, index) {
                  final song = _filteredSongs[index];
                  return Card(
                    color: Colors.white70,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      title: Text(song['title'] ?? 'No Title'),
                      subtitle: Text(song['artist'] ?? 'Unknown Artist'),
                      onTap: () {
                        final localPath = song['localPath'] ?? '';
                        final youtubeUrl = song['youtubeUrl'] ?? '';
                        final title = song['title'] ?? '';
                        final artist = song['artist'] ?? '';

                        if (localPath.isNotEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LocalAudioPlayerPage(
                                audioPath: localPath,
                                title: title,
                              ),
                            ),
                          );
                        } else if (youtubeUrl.isNotEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => YouTubePlayerPage(
                                youtubeUrl: youtubeUrl,
                                title: title,
                                artist: artist,
                              ),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('No valid source to play this song')),
                          );
                        }
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

}

extension StringCap on String {
  String capitalize() => isNotEmpty ? '${this[0].toUpperCase()}${substring(1)}' : this;
}
