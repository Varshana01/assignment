import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:emo_sik/statistics_helper.dart';


class LyricsFeedbackPage extends StatefulWidget {
  final String title;
  final String artist;
  final String localPath;       // empty string for online songs
  final String lyrics;          // empty string if not found
  final String suggestedEmotion;
  final String? youtubeUrl;     // <-- added to support online songs

  const LyricsFeedbackPage({
    Key? key,
    required this.title,
    required this.artist,
    required this.localPath,
    required this.lyrics,
    required this.suggestedEmotion,
    this.youtubeUrl,
  }) : super(key: key);

  @override
  State<LyricsFeedbackPage> createState() => _LyricsFeedbackPageState();
}

class _LyricsFeedbackPageState extends State<LyricsFeedbackPage> {
  String _finalEmotion = '';
  bool _showManualSelection = false;

  final List<String> _emotions = ['happy', 'sad', 'angry', 'relaxed', 'neutral'];

  /// ✅ Save song to Firebase & SharedPreferences
  Future<void> _saveSong() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final DatabaseReference dbRef = FirebaseDatabase.instance.ref();

    final bool isLocal = widget.localPath.isNotEmpty;
    if (_finalEmotion.isEmpty) _finalEmotion = widget.suggestedEmotion;

    final Map<String, dynamic> songData = {
      'title': widget.title,
      'artist': widget.artist,
      'lyrics': widget.lyrics,
      'analyzedEmotion': _finalEmotion, // ✅ use final emotion
      'localPath': isLocal ? widget.localPath : '',
      'youtubeUrl': isLocal ? '' : (widget.youtubeUrl ?? ''), // ✅ safe access
    };

    // Save to Firebase playlist
    await dbRef.child('users/${user.uid}/playlists').push().set(songData);

    // Optional: Save offline if it's a local song
    final prefs = await SharedPreferences.getInstance();
    if (isLocal) {
      await prefs.setString('audio_${widget.title}', widget.localPath);
      await prefs.setString('lyrics_${widget.title}', widget.lyrics);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Song saved to playlist')),
    );

    Navigator.pop(context); // return to previous page
  }

  /// ✅ Builds either confirmation or manual selection UI
  Widget _buildEmotionSelection(bool hasLyrics) {
    if (!_showManualSelection && hasLyrics) {
      // Show Yes/No confirmation first
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton(
            onPressed: () {
              setState(() {
                _finalEmotion = widget.suggestedEmotion;
              });
              _saveSong();
            },
            child: const Text("Yes, Save"),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _showManualSelection = true;
              });
            },
            child: const Text("No, Choose"),
          ),
        ],
      );
    } else {
      // Show dropdown for manual selection
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            value: _emotions.first,
            items: _emotions.map((emotion) {
              return DropdownMenuItem<String>(
                value: emotion,
                child: Text(emotion),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _finalEmotion = value!;
              });
            },
            decoration: const InputDecoration(
              labelText: "Select Emotion",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () async {
              await updateEmotionStats(
                _finalEmotion,
                _finalEmotion == widget.suggestedEmotion,
              );
              _saveSong();
            },
            icon: const Icon(Icons.save),
            label: const Text("Save Song"),
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasLyrics = widget.lyrics.trim().isNotEmpty;
    final suggested = widget.suggestedEmotion;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Lyrics Feedback'),
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.title,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                Text(widget.artist,
                    style: const TextStyle(fontSize: 16, color: Colors.white70)),
                const SizedBox(height: 16),

                // ✅ Show lyrics or fallback
                if (hasLyrics)
                  Container(
                    height: 200,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SingleChildScrollView(
                      child: Text(widget.lyrics,
                          style: const TextStyle(fontSize: 14, color: Colors.black87)),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '⚠️ No lyrics found.\nPlease choose an emotion manually.',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
                    ),
                  ),

                const SizedBox(height: 16),

                if (hasLyrics)
                  Text(
                    "Suggested Emotion: $suggested",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                  ),

                const SizedBox(height: 16),

                _buildEmotionSelection(hasLyrics),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
