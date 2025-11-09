import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'dart:io';

class LocalAudioPlayerPage extends StatefulWidget {
  final String audioPath;
  final String title;

  const LocalAudioPlayerPage({
    Key? key,
    required this.audioPath,
    required this.title,
  }) : super(key: key);

  @override
  State<LocalAudioPlayerPage> createState() => _LocalAudioPlayerPageState();
}

class _LocalAudioPlayerPageState extends State<LocalAudioPlayerPage> {
  late AudioPlayer _player;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      if (!File(widget.audioPath).existsSync()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("⚠️ File not found: ${widget.audioPath}")),
        );
        return;
      }

      await _player.setFilePath(widget.audioPath);

      // Listen for position & duration changes
      _player.durationStream.listen((d) {
        if (d != null) setState(() => _duration = d);
      });
      _player.positionStream.listen((p) => setState(() => _position = p));

    } catch (e) {
      print('❌ Error initializing audio player: $e');
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return '$minutes:$seconds';
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
        title: Text(widget.title),
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
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.music_note, size: 80, color: Colors.white),
                    const SizedBox(height: 16),
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),

                    // Progress bar with times
                    ProgressBar(
                      progress: _position,
                      total: _duration,
                      progressBarColor: Colors.yellow,
                      baseBarColor: Colors.white.withOpacity(0.3),
                      bufferedBarColor: Colors.white38,
                      thumbColor: Colors.white,
                      barHeight: 6.0,
                      onSeek: (duration) {
                        _player.seek(duration);
                      },
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_formatDuration(_position),
                            style: const TextStyle(color: Colors.white)),
                        Text(_formatDuration(_duration),
                            style: const TextStyle(color: Colors.white)),
                      ],
                    ),
                    const SizedBox(height: 40),

                    // Play / Pause Button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(20),
                        backgroundColor: Colors.white.withOpacity(0.8),
                      ),
                      onPressed: () async {
                        if (_isPlaying) {
                          await _player.pause();
                        } else {
                          await _player.play();
                        }
                        setState(() => _isPlaying = !_isPlaying);
                      },
                      child: Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        size: 40,
                        color: Colors.blueAccent,
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
