import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'youtube_player_page.dart';
import 'LocalAudioPlayerPage.dart';

class EmotionMatcherPage extends StatefulWidget {
  final String detectedEmotion;

  const EmotionMatcherPage({Key? key, required this.detectedEmotion}) : super(key: key);

  @override
  _EmotionMatcherPageState createState() => _EmotionMatcherPageState();
}

class _EmotionMatcherPageState extends State<EmotionMatcherPage> {
  List<Map<String, dynamic>> _matchedSongs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMatchingSongs();
  }

  Future<void> _loadMatchingSongs() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final DatabaseReference dbRef = FirebaseDatabase.instance.ref();
    final snapshot = await dbRef.child('users/${user.uid}/playlists').get();

    if (snapshot.exists) {
      final Map<String, dynamic> data = Map<String, dynamic>.from(snapshot.value as Map);

      final List<Map<String, dynamic>> matchingSongs = [];

      data.forEach((key, value) {
        final song = Map<String, dynamic>.from(value);
        if (song['analyzedEmotion'] == widget.detectedEmotion) {
          matchingSongs.add(song);
        }
      });

      setState(() {
        _matchedSongs = matchingSongs;
        _isLoading = false;
      });
    } else {
      setState(() {
        _matchedSongs = [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Songs Matching Your Emotion')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _matchedSongs.isEmpty
          ? Center(child: Text('No matching songs found for ${widget.detectedEmotion}.'))
          : ListView.builder(
        itemCount: _matchedSongs.length,
        itemBuilder: (context, index) {
          final song = _matchedSongs[index];
          return Card(
            child: ListTile(
              title: Text(song['title'] ?? ''),
              subtitle: Text('Emotion: ${song['analyzedEmotion']}'),
              onTap: () {
                final youtubeUrl = song['youtubeUrl'] ?? '';
                final localPath = song['localPath'] ?? '';

                if (localPath.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LocalAudioPlayerPage(audioPath: localPath, title: song['title']),
                    ),
                  );
                } else if (youtubeUrl.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => YouTubePlayerPage(
                        youtubeUrl: song['youtubeUrl'] ?? '',
                        title: song['title'] ?? 'Unknown Title',
                        artist: song['artist'] ?? 'Unknown Artist',
                      ),
                    ),
                  );
                }
              },
            ),
          );
        },
      ),
    );
  }
}
