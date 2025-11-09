import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart';

const String geniusApiKey = 'cUowUrZ_N4P6drtJ8S3wy9x9HTSOFbukkN4LF4hKIUqyFC9JVORNIyjI_yti7Ozx'; // Replace with your Genius API key

Future<String> fetchLyrics(String title, String artist) async {
  // Clean the title to improve search accuracy
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

    // Step 1: Search for the song using Genius API
    final response = await http.get(
      Uri.parse(searchUrl),
      headers: {'Authorization': 'Bearer $geniusApiKey'},
    );

    if (response.statusCode != 200) {
      return '⚠️ Genius API error: ${response.statusCode}';
    }

    final responseBody = jsonDecode(response.body);
    final hits = responseBody['response']['hits'] ?? [];

    if (hits.isEmpty) {
      return '⚠️ No lyrics found for "$title" by "$artist".';
    }

    // Step 2: Get the song page URL from the first hit
    final path = hits[0]['result']['path'];
    final songUrl = 'https://genius.com$path';

    // Step 3: Fetch the song page HTML
    final songPage = await http.get(Uri.parse(songUrl));
    if (songPage.statusCode != 200) {
      return '⚠️ Failed to load Genius page.';
    }

    // Step 4: Parse lyrics from HTML
    final document = parse(songPage.body);

    String lyrics = '';

    // New Genius layout (preferred)
    final containers = document.querySelectorAll('div[class^="Lyrics__Container"]');
    if (containers.isNotEmpty) {
      lyrics = containers.map((e) => e.text.trim()).join('\n\n');
    }

    // Old Genius layout fallback
    if (lyrics.isEmpty) {
      final legacy = document.querySelector('.lyrics');
      if (legacy != null) {
        lyrics = legacy.text.trim();
      }
    }

    // Final fallback
    if (lyrics.isEmpty) {
      return '⚠️ Lyrics not found. Genius layout might have changed.';
    }

    return lyrics;
  } catch (e) {
    return '❌ Error while fetching lyrics: $e';
  }
}
