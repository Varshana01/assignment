import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'add_local_song_page.dart';
import 'offline_audio_player_page.dart';
import 'offline_playlist_page.dart';
import 'song_search_page.dart';
import 'playlist_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({Key? key}) : super(key: key);

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }


  Future<void> downloadLyricsOffline() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final DatabaseReference dbRef = FirebaseDatabase.instance.ref();
    final snapshot = await dbRef.child('users/${user.uid}/playlists').get();

    if (!snapshot.exists) {
      print('⚠️ No playlist found');
      return;
    }

    final Map<String, dynamic> data = Map<String, dynamic>.from(snapshot.value as Map);

    final prefs = await SharedPreferences.getInstance();

    for (var entry in data.values) {
      final song = Map<String, dynamic>.from(entry);
      final title = song['title'];
      final lyrics = song['lyrics'] ?? '';

      await prefs.setString('lyrics_$title', lyrics);
      print('✅ Saved lyrics for "$title" offline');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    final ButtonStyle buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFFFFECB3),
      foregroundColor: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
    );

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
        title: const Text('Profile'),
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
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '🎧 Logged in as: ${user?.email ?? "Unknown"}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 30),

                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const SongSearchPage()),
                          );
                        },
                        icon: const Icon(Icons.library_music),
                        label: const Text('Search and Add Songs'),
                        style: buttonStyle,
                      ),
                      const SizedBox(height: 15),

                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const PlaylistPage()),
                          );
                        },
                        icon: const Icon(Icons.queue_music),
                        label: const Text('View Your Playlist'),
                        style: buttonStyle,
                      ),
                      const SizedBox(height: 15),

                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const AddLocalSongPage()),
                          );
                        },
                        icon: const Icon(Icons.library_add),
                        label: const Text('Add Local Song'),
                        style: buttonStyle,
                      ),
                      const SizedBox(height: 15),

                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const OfflinePlaylistPage()),
                          );
                        },
                        icon: const Icon(Icons.music_note),
                        label: const Text('Offline Playlist'),
                        style: buttonStyle,
                      ),

                      const SizedBox(height: 15),

                      ElevatedButton.icon(
                        onPressed: () => _logout(context),
                        icon: const Icon(Icons.logout),
                        label: const Text('Logout'),
                        style: buttonStyle,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
