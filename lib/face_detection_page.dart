import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'dart:io';

class FaceDetectionPage extends StatefulWidget {
  const FaceDetectionPage({Key? key}) : super(key: key);

  @override
  State<FaceDetectionPage> createState() => _FaceDetectionPageState();
}

class _FaceDetectionPageState extends State<FaceDetectionPage> {
  final ImagePicker _picker = ImagePicker();
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableClassification: true,
      enableLandmarks: true,
    ),
  );

  String _result = 'No face detected';

  Future<void> _detectFaces() async {
    final XFile? imageFile = await _picker.pickImage(source: ImageSource.camera);
    if (imageFile == null) return;

    final inputImage = InputImage.fromFilePath(imageFile.path);
    final faces = await _faceDetector.processImage(inputImage);

    if (faces.isNotEmpty) {
      final face = faces.first;
      final smile = face.smilingProbability ?? 0.0;
      final leftEye = face.leftEyeOpenProbability ?? 0.0;
      final rightEye = face.rightEyeOpenProbability ?? 0.0;

      String mood;
      if (smile > 0.8 && leftEye > 0.5 && rightEye > 0.5) {
        mood = 'Happy';
      } else if (smile < 0.2) {
        mood = 'Sad';
      } else {
        mood = 'Neutral';
      }

      setState(() {
        _result = '😊 Smile: ${(smile * 100).toStringAsFixed(1)}%\n'
            '👁️ Left Eye Open: ${(leftEye * 100).toStringAsFixed(1)}%\n'
            '👁️ Right Eye Open: ${(rightEye * 100).toStringAsFixed(1)}%\n'
            '🎭 Emotion: $mood';
      });
    } else {
      setState(() {
        _result = 'No face detected';
      });
    }
  }

  @override
  void dispose() {
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Face Detection (ML Kit)")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(_result, style: const TextStyle(fontSize: 16)),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _detectFaces,
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}
