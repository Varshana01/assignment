import 'dart:io';
import 'package:emo_sik/EmotionBasedSongsPage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:emo_sik/statistics_helper.dart';

class EmotionDetectionPage extends StatefulWidget {
  const EmotionDetectionPage({Key? key}) : super(key: key);

  @override
  State<EmotionDetectionPage> createState() => _EmotionDetectionPageState();
}

class _EmotionDetectionPageState extends State<EmotionDetectionPage> {
  File? _image;
  String _detectedEmotion = 'No emotion detected';
  late Interpreter _interpreter1;
  late Interpreter _interpreter2;
  bool _modelsLoaded = false;
  List<double> _emotionScores = List.filled(7, 0.0);

  final FaceDetector _mlkitDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableClassification: true,
      enableLandmarks: true,
    ),
  );

  final List<String> _labels = [
    'angry', 'disgust', 'fear', 'happy', 'sad', 'surprise', 'neutral',
  ];

  @override
  void initState() {
    super.initState();
    _loadTFLiteModels();
  }

  Future<void> _loadTFLiteModels() async {
    try {
      _interpreter1 = await Interpreter.fromAsset('assets/emotion_model.tflite');
      _interpreter2 = await Interpreter.fromAsset('assets/emotion_model_2.tflite');
      setState(() => _modelsLoaded = true);
    } catch (e) {
      setState(() => _detectedEmotion = '❌ Model Load Error: $e');
    }
  }

  void _showModelSelectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.insights, size: 60, color: Color(0xFF00BFFF)),
                const SizedBox(height: 16),
                const Text(
                  'Choose Detection Mode',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00BFFF),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Select which emotion detection model to use:',
                  style: TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                ElevatedButton.icon(
                  icon: const Icon(Icons.memory),
                  onPressed: () {
                    Navigator.pop(context);
                    _runDetectionMode('tflite');
                  },
                  label: const Text('Use TFLite Model'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF87CEEB),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(45),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                ElevatedButton.icon(
                  icon: const Icon(Icons.face_retouching_natural),
                  onPressed: () {
                    Navigator.pop(context);
                    _runDetectionMode('mlkit');
                  },
                  label: const Text('Use ML Kit Model'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00BFFF),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(45),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                ElevatedButton.icon(
                  icon: const Icon(Icons.auto_mode),
                  onPressed: () {
                    Navigator.pop(context);
                    _runDetectionMode('combined');
                  },
                  label: const Text('Use Combined Mode'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFECB3),
                    foregroundColor: Colors.black87,
                    minimumSize: const Size.fromHeight(45),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _runDetectionMode(String mode) async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.camera);
    if (pickedFile == null) return;

    setState(() {
      _image = File(pickedFile.path);
      _detectedEmotion = 'Detecting...';
      _emotionScores = List.filled(7, 0.0);
    });

    final imageFile = File(pickedFile.path);
    final bytes = await imageFile.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) {
      setState(() => _detectedEmotion = '❌ Image decode failed');
      return;
    }

    final resized = img.copyResize(image, width: 48, height: 48);
    final grayscale = img.grayscale(resized);
    final input = List.generate(1, (_) => List.generate(48, (y) =>
        List.generate(48, (x) {
          final pixel = grayscale.getPixel(x, y).r.toDouble();
          return [pixel / 255.0];
        })));

        final output1 = List.filled(1 * 7, 0.0).reshape([1, 7]);
    final output2 = List.filled(1 * 7, 0.0).reshape([1, 7]);

    if (mode != 'mlkit') {
      _interpreter1.run(input, output1);
      _interpreter2.run(input, output2);
    }

    final avgScores = List.generate(7, (i) => (output1[0][i] + output2[0][i]) / 2);
    final tfliteTopEmotion = _labels[avgScores.indexOf(avgScores.reduce((a, b) => a > b ? a : b))];

    String? mlkitEmotion;
    if (mode != 'tflite') {
      final mlkitInput = InputImage.fromFilePath(imageFile.path);
      final faces = await _mlkitDetector.processImage(mlkitInput);
      if (faces.isNotEmpty) {
        await incrementFaceDetection();
        final face = faces.first;
        final smileProb = face.smilingProbability ?? -1.0;

        if (smileProb >= 0.7) {
          mlkitEmotion = 'happy';
        } else if (smileProb <= 0.3) {
          mlkitEmotion = 'sad';
        } else {
          mlkitEmotion = 'neutral';
        }
      }
    }

    final finalEmotion = switch (mode) {
      'mlkit' => mlkitEmotion ?? 'neutral',
      'tflite' => tfliteTopEmotion,
      'combined' => mlkitEmotion ?? tfliteTopEmotion,
      _ => 'neutral'
    };

    setState(() {
      _detectedEmotion = 'Detected: $finalEmotion';
      _emotionScores = avgScores.cast<double>();
    });

    await updateEmotionStats(finalEmotion, true);
  }

  @override
  void dispose() {
    _mlkitDetector.close();
    _interpreter1.close();
    _interpreter2.close();
    super.dispose();
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
        title: const Text('Emotion Detection'),
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
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (_image != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.file(_image!, height: 200),
                        ),
                      const SizedBox(height: 30),

                      Text(
                        _detectedEmotion,
                        style: const TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 20),

                      if (_emotionScores.any((e) => e > 0))
                        Column(
                          children: List.generate(_labels.length, (i) {
                            final percent = (_emotionScores[i] * 100).toStringAsFixed(1);
                            return Text(
                              '${_labels[i]}: $percent%',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            );
                          }),
                        ),

                      const SizedBox(height: 30),

                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFECB3),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        onPressed: _showModelSelectionDialog,
                        child: const Text('Detect Emotion'),
                      ),

                      const SizedBox(height: 20),

                      if (_detectedEmotion.startsWith("Detected:"))
                        ElevatedButton.icon(
                          icon: const Icon(Icons.music_note),
                          label: const Text("See Suggested Songs"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.blueAccent,
                            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          onPressed: () {
                            final emotion = _detectedEmotion.replaceFirst('Detected: ', '');
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EmotionBasedSongListPage(emotion: emotion),
                              ),
                            );
                          },
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
