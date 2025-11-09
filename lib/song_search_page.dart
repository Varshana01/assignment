import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart';
import 'package:sentiment_dart/sentiment_dart.dart';

import 'youtube_player_page.dart';
import 'lyrics_feedback_page.dart';
import 'audio_analysis.dart';
import 'youtube_audio_helper.dart';

class SongSearchPage extends StatefulWidget {
  const SongSearchPage({super.key});

  @override
  State<SongSearchPage> createState() => _SongSearchPageState();
}

class _SongSearchPageState extends State<SongSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;
  static const String geniusApiKey = 'cUowUrZ_N4P6drtJ8S3wy9x9HTSOFbukkN4LF4hKIUqyFC9JVORNIyjI_yti7Ozx'; // Replace with your Genius API key


  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() => _isLoading = true);
    final yt = YoutubeExplode();

    try {
      final results = await yt.search.getVideos(query);
      List<Map<String, dynamic>> songs = [];

      for (var video in results.take(5)) {
        songs.add({
          'title': video.title,
          'artist': video.author,
          'youtubeUrl': 'https://www.youtube.com/watch?v=${video.id}',
        });
      }

      yt.close();
      setState(() {
        _searchResults = songs;
        _isLoading = false;
      });
    } catch (e) {
      yt.close();
      setState(() => _isLoading = false);
      print('❌ YouTube search error: $e');
    }
  }

  Future<String> fetchLyrics(String title, String artist) async {
    // Sanitize and clean the title
    String cleanTitle(String input) {
      return input
          .replaceAll(RegExp(r'\(.*?\)'), '')
          .replaceAll(RegExp(r'\[.*?\]'), '')
          .replaceAll(RegExp(r'-'), '')
          .trim();
    }

    try {
      final cleanedTitle = cleanTitle(title);
      final searchQuery = Uri.encodeComponent('$cleanedTitle $artist');
      final searchUrl = 'https://api.genius.com/search?q=$searchQuery';

      final response = await http.get(
        Uri.parse(searchUrl),
        headers: {'Authorization': 'Bearer $geniusApiKey'},
      );

      if (response.statusCode != 200) {
        return '⚠️ Genius API error: ${response.statusCode}';
      }

      final jsonBody = jsonDecode(response.body);
      final hits = jsonBody['response']['hits'];
      if (hits == null || hits.isEmpty) {
        return '⚠️ No lyrics found for "$title" by "$artist".';
      }

      final path = hits[0]['result']['path'];
      final songUrl = 'https://genius.com$path';

      final songPage = await http.get(Uri.parse(songUrl));
      if (songPage.statusCode != 200) {
        return '⚠️ Failed to load Genius page.';
      }

      final document = parse(songPage.body);

      // Try modern Genius layout
      String lyrics = '';
      final containers = document.querySelectorAll('div[class^="Lyrics__Container"]');
      if (containers.isNotEmpty) {
        lyrics = containers.map((e) => e.text.trim()).join('\n\n');
      }

      // Try fallback legacy layout
      if (lyrics.isEmpty) {
        final legacy = document.querySelector('.lyrics');
        if (legacy != null) {
          lyrics = legacy.text.trim();
        }
      }

      // Final fallback
      if (lyrics.isEmpty) {
        return '⚠️ Lyrics not found or Genius layout changed.';
      }

      return lyrics;
    } catch (e) {
      return '❌ Error while fetching lyrics: $e';
    }
  }

  Future<void> _handleAddSong(Map<String, dynamic> song) async {
    final title = song['title'];
    final artist = song['artist'];
    final youtubeUrl = song['youtubeUrl'];

    if (youtubeUrl == null) return;

    setState(() => _isLoading = true);

    String lyrics = await fetchLyrics(title, artist);

    String suggestedEmotion = 'neutral';
    String? previewPath;
    try {
      previewPath = await YouTubeAudioHelper.downloadPreview(youtubeUrl);
    } catch (_) {
      previewPath = null;
    }

    try {
      if (previewPath != null) {
        final result = await AudioAnalyzer.analyzeAudio(previewPath);
        double bpm = result?.tempo ?? 0;
        double loudness = result?.loudness ?? -30;

        double sentimentScore = 0.0;
        if (lyrics.isNotEmpty) {
          final analysis = Sentiment.analysis(lyrics, emoji: true);
          sentimentScore = analysis.score?.toDouble() ?? 0.0;
        }

        if (bpm > 120 && loudness > -10 && sentimentScore >= 0) {
          suggestedEmotion = 'happy';
        } else if (bpm < 90 && loudness < -20 && sentimentScore <= 0) {
          suggestedEmotion = 'sad';
        } else if (loudness > -8) {
          suggestedEmotion = 'angry';
        } else if (bpm < 100) {
          suggestedEmotion = 'relaxed';
        }
      } else {
        final score = Sentiment.analysis(lyrics).score?.toDouble() ?? 0.0;
        if (score > 1) suggestedEmotion = 'happy';
        else if (score < -1) suggestedEmotion = 'sad';
      }
    } catch (e) {
      print('⚠️ Emotion analysis fallback: $e');
    }

    setState(() => _isLoading = false);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LyricsFeedbackPage(
          title: title,
          artist: artist,
          localPath: '',
          lyrics: lyrics,
          suggestedEmotion: suggestedEmotion,
          youtubeUrl: youtubeUrl,
        ),
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
        title: const Text('Search Songs'),
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
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        hintText: 'Search song...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _performSearch(),
                    ),
                    const SizedBox(height: 16),
                    _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Expanded(
                      child: ListView.builder(
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final song = _searchResults[index];
                          return Card(
                            color: Colors.white70,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: ListTile(
                              title: Text(song['title']),
                              subtitle: Text(song['artist']),
                              trailing: IconButton(
                                icon: const Icon(Icons.playlist_add),
                                onPressed: () => _handleAddSong(song),
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => YouTubePlayerPage(
                                      youtubeUrl: song['youtubeUrl'],
                                      title: song['title'],
                                      artist: song['artist'],
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
