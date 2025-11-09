import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:sentiment_dart/sentiment_dart.dart';

import 'lyrics_feedback_page.dart';
import 'audio_analysis.dart'; // <- new file for audio analysis

class AddLocalSongPage extends StatefulWidget {
  const AddLocalSongPage({Key? key}) : super(key: key);

  @override
  State<AddLocalSongPage> createState() => _AddLocalSongPageState();
}

class _AddLocalSongPageState extends State<AddLocalSongPage> {
  String? _filePath;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _artistController = TextEditingController();
  bool _isLoading = false;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'm4a'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _filePath = result.files.single.path;
      });
    }
  }

  /// ✅ Fetch lyrics if any
  Future<String> fetchLyrics(String title, String artist) async {
    // Optional: You can implement Genius API here similar to online songs
    return ''; // For now assume offline songs have no lyrics
  }

  /// ✅ Suggest emotion using both lyrics and audio analysis
  Future<String> suggestEmotion(String filePath, String lyrics) async {
    final result = await AudioAnalyzer.analyzeAudio(filePath);
    if (result == null) return 'neutral';

    double bpm = result.tempo;
    double loudness = result.loudness;

    // Lyrics sentiment
    double sentimentScore = 0.0;
    if (lyrics.isNotEmpty) {
      final analysis = Sentiment.analysis(lyrics, emoji: true);
      sentimentScore = analysis.score?.toDouble() ?? 0.0;
    }

    // Simple rule-based combination
    if (bpm > 120 && loudness > -10 && sentimentScore >= 0) {
      return 'happy';
    } else if (bpm < 90 && loudness < -20 && sentimentScore <= 0) {
      return 'sad';
    } else if (loudness > -8) {
      return 'angry';
    } else if (bpm < 100) {
      return 'relaxed';
    }
    return 'neutral';
  }

  /// ✅ Proceed to Lyrics Feedback Page
  Future<void> _proceedWithLyricsFeedback() async {
    if (_filePath == null || _titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a file and enter a title.")),
      );
      return;
    }

    final file = File(_filePath!);
    if (!file.existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Selected file no longer exists.")),
      );
      return;
    }

    setState(() => _isLoading = true);

    final title = _titleController.text;
    final artist = _artistController.text;

    // Step 1: Copy audio file into internal app directory
    final appDir = await getApplicationDocumentsDirectory();
    final newPath = '${appDir.path}/$title.mp3';
    final copiedFile = await file.copy(newPath);

    // Step 2: Save metadata in SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('audio_$title', copiedFile.path);
    await prefs.setString('artist_$title', artist);
    List<String> playlist = prefs.getStringList('offline_playlist') ?? [];
    if (!playlist.contains(title)) {
      playlist.add(title);
      await prefs.setStringList('offline_playlist', playlist);
    }

    // Step 3: Get lyrics (if implemented)
    final lyrics = await fetchLyrics(title, artist);

    // Step 4: Analyze emotion
    final suggestedEmotion = await suggestEmotion(copiedFile.path, lyrics);

    setState(() => _isLoading = false);

    // Step 5: Navigate to Lyrics Feedback Page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LyricsFeedbackPage(
          title: title,
          artist: artist,
          localPath: copiedFile.path,
          lyrics: lyrics,
          suggestedEmotion: suggestedEmotion,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Add Local Song"),
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
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.library_music, size: 60,
                        color: Colors.blueAccent),
                    const SizedBox(height: 16),

                    ElevatedButton.icon(
                      onPressed: _pickFile,
                      icon: const Icon(Icons.folder_open),
                      label: const Text("Pick Audio File"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    TextField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: "Song Title",
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.music_note),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: _artistController,
                      decoration: InputDecoration(
                        labelText: "Artist (optional)",
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    _isLoading
                        ? const CircularProgressIndicator()
                        : ElevatedButton.icon(
                      onPressed: _proceedWithLyricsFeedback,
                      icon: const Icon(Icons.analytics),
                      label: const Text("Analyze & Continue"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    if (_filePath != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: Text(
                          "📁 Selected File:\n$_filePath",
                          style: const TextStyle(color: Colors.black54),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}