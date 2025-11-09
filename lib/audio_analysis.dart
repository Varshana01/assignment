import 'dart:async';
import 'dart:io';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';

class AudioAnalysisResult {
  final double tempo;      // BPM
  final double loudness;   // dB
  final Duration duration;

  AudioAnalysisResult({required this.tempo, required this.loudness, required this.duration});
}

class AudioAnalyzer {
  /// Analyze the local MP3/WAV file for tempo, loudness, and duration
  static Future<AudioAnalysisResult?> analyzeAudio(String filePath) async {
    if (!File(filePath).existsSync()) return null;

    // 1️⃣ Get tempo using ffmpeg's `astats`
    final tempoCmd = '''
    ffmpeg -i "$filePath" -af "astats=metadata=1:reset=1" -f null -
    ''';

    String tempoOutput = "";
    await FFmpegKit.executeAsync(tempoCmd, (session) async {
      tempoOutput = (await session.getOutput()) ?? "";
    });

    // Estimate BPM (mock logic: count peaks) → Real BPM detection needs librosa/Python
    double bpm = _estimateBPM(tempoOutput);

    // 2️⃣ Get loudness (average volume in dB)
    final loudnessCmd = '''
    ffmpeg -i "$filePath" -af "volumedetect" -f null /dev/null
    ''';
    String loudnessOutput = "";
    await FFmpegKit.executeAsync(loudnessCmd, (session) async {
      loudnessOutput = (await session.getOutput()) ?? "";
    });

    double loudness = _extractLoudness(loudnessOutput);

    // 3️⃣ Get duration
    final duration = await _getAudioDuration(filePath);

    return AudioAnalysisResult(
      tempo: bpm,
      loudness: loudness,
      duration: duration,
    );
  }

  /// Dummy BPM estimation (improve with real DSP)
  static double _estimateBPM(String output) {
    final peakMatches = RegExp(r'RMS_peak:\s*([\d.]+)').allMatches(output);
    return 60 + peakMatches.length.toDouble(); // rough BPM guess
  }

  /// Extract loudness from volumedetect output
  static double _extractLoudness(String output) {
    final match = RegExp(r'mean_volume:\s*(-?\d+\.\d+) dB').firstMatch(output);
    return match != null ? double.tryParse(match.group(1)!) ?? -30.0 : -30.0;
  }

  /// Extract duration using ffprobe
  static Future<Duration> _getAudioDuration(String filePath) async {
    final result = await FFmpegKit.execute('-i "$filePath"');
    final output = await result.getOutput() ?? "";
    final match = RegExp(r'Duration: (\d+):(\d+):(\d+\.\d+)').firstMatch(output);
    if (match != null) {
      final hours = int.parse(match.group(1)!);
      final minutes = int.parse(match.group(2)!);
      final seconds = double.parse(match.group(3)!);
      return Duration(
        hours: hours,
        minutes: minutes,
        seconds: seconds.toInt(),
        milliseconds: ((seconds % 1) * 1000).toInt(),
      );
    }
    return Duration.zero;
  }
}
