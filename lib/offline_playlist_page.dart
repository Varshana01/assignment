
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'offline_audio_player_page.dart';

class OfflinePlaylistPage extends StatefulWidget {
  const OfflinePlaylistPage({Key? key}) : super(key: key);

  @override
  State<OfflinePlaylistPage> createState() => _OfflinePlaylistPageState();
}

class _OfflinePlaylistPageState extends State<OfflinePlaylistPage> {
  List<Map<String, String>> _offlineSongs = [];

  @override
  void initState() {
    super.initState();
    _loadOfflineSongs();
  }

  Future<void> _loadOfflineSongs() async {
    final prefs = await SharedPreferences.getInstance();
    final titles = prefs.getStringList('offline_playlist') ?? [];

    final List<Map<String, String>> songs = [];

    for (var title in titles) {
      final path = prefs.getString('audio_$title') ?? '';
      final artist = prefs.getString('artist_$title') ?? 'Unknown Artist';

      if (path.isNotEmpty) {
        songs.add({
          'title': title,
          'artist': artist,
          'path': path,
        });
      }
    }

    setState(() {
      _offlineSongs = songs;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Offline Playlist',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF87CEEB), Color(0xFF00BFFF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: _offlineSongs.isEmpty
              ? const Center(
            child: Text(
              'No offline songs available.',
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
              ),
            ),
          )
              : ListView.builder(
            itemCount: _offlineSongs.length,
            itemBuilder: (context, index) {
              final song = _offlineSongs[index];
              return Card(
                color: Colors.white.withOpacity(0.8),
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  title: Text(song['title'] ?? ''),
                  subtitle: Text(song['artist'] ?? ''),
                  trailing: const Icon(Icons.play_arrow),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LocalAudioPlayerPage(
                          audioPath: song['path']!,
                          title: song['title']!,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}