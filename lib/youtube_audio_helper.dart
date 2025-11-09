import 'dart:io';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:path_provider/path_provider.dart';

class YouTubeAudioHelper {
  static final yt = YoutubeExplode();

  /// Downloads first 30s of YouTube audio for analysis
  static Future<String?> downloadPreview(String youtubeUrl) async {
    try {
      final videoId = VideoId(youtubeUrl);

      final manifest = await yt.videos.streamsClient.getManifest(videoId);
      final audioStreamInfo = manifest.audioOnly.withHighestBitrate();
      if (audioStreamInfo == null) return null;

      final dir = await getTemporaryDirectory();
      final savePath = '${dir.path}/$videoId.mp3';

      final audioStream = yt.videos.streamsClient.get(audioStreamInfo);
      final file = File(savePath);
      final sink = file.openWrite();

      int bytesWritten = 0;
      await for (final data in audioStream) {
        sink.add(data);
        bytesWritten += data.length;

        // Stop after ~30 seconds worth of audio (~500KB at 128kbps)
        if (bytesWritten > 500 * 1024) break;
      }

      await sink.close();
      return savePath;
    } catch (e) {
      print('❌ Failed to download preview: $e');
      return null;
    }
  }

  static Future<void> dispose() async {
    yt.close();
  }
}
