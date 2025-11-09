import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'youtube_player_page.dart';
import 'LocalAudioPlayerPage.dart';

class PlaylistPage extends StatefulWidget {
  const PlaylistPage({Key? key}) : super(key: key);

  @override
  State<PlaylistPage> createState() => _PlaylistPageState();
}

class _PlaylistPageState extends State<PlaylistPage> {
  List<Map<String, dynamic>> _playlist = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlaylist();
  }

  Future<void> _loadPlaylist() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final DatabaseReference dbRef = FirebaseDatabase.instance.ref();
    final snapshot = await dbRef.child('users/${user.uid}/playlists').get();

    if (snapshot.exists) {
      final Map<String, dynamic> data = Map<String, dynamic>.from(snapshot.value as Map);

      final List<Map<String, dynamic>> loadedPlaylist = [];

      data.forEach((key, value) {
        final song = Map<String, dynamic>.from(value);
        song['id'] = key;
        loadedPlaylist.add(song);
      });

      setState(() {
        _playlist = loadedPlaylist;
        _isLoading = false;
      });
    } else {
      setState(() {
        _playlist = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _removeSong(String songId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final DatabaseReference dbRef = FirebaseDatabase.instance.ref();
    await dbRef.child('users/${user.uid}/playlists/$songId').remove();

    setState(() {
      _playlist.removeWhere((song) => song['id'] == songId);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('❌ Song removed from playlist')),
    );
  }

  /// Handles song playback for local or online
  void _onSongTap(Map<String, dynamic> song) {
    final youtubeUrl = song['youtubeUrl'] ?? '';
    final localPath = song['localPath'] ?? '';

    if (localPath.isNotEmpty && File(localPath).existsSync()) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LocalAudioPlayerPage(
            audioPath: localPath,
            title: song['title'] ?? 'Unknown Song',
          ),
        ),
      );
    } else if (youtubeUrl.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => YouTubePlayerPage(
            youtubeUrl: youtubeUrl,
            title: song['title'] ?? 'Unknown Title',
            artist: song['artist'] ?? 'Unknown Artist',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ No valid source to play this song.')),
      );
    }
  }

  /// Builds emotion badge for each song
  Widget _buildEmotionBadge(String emotion) {
    Color color;
    switch (emotion) {
      case 'happy':
        color = Colors.yellow.shade700;
        break;
      case 'sad':
        color = Colors.blue.shade400;
        break;
      case 'angry':
        color = Colors.red.shade400;
        break;
      case 'relaxed':
        color = Colors.green.shade400;
        break;
      default:
        color = Colors.grey.shade400;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        emotion,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
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
        title: const Text('Your Playlist'),
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
                  height: 700,
                ),
              ),
            ),
            SafeArea(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                  : _playlist.isEmpty
                  ? const Center(
                child: Text(
                  'No songs in your playlist.',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              )
                  : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: ListView.builder(
                  itemCount: _playlist.length,
                  itemBuilder: (context, index) {
                    final song = _playlist[index];
                    final emotion = song['analyzedEmotion'] ?? 'neutral';

                    return Card(
                      color: Colors.white70,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        title: Text(song['title'] ?? ''),
                        subtitle: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(song['artist'] ?? ''),
                            _buildEmotionBadge(emotion),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _removeSong(song['id']),
                        ),
                        onTap: () => _onSongTap(song),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
