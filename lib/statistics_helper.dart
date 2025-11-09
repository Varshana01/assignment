import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

Future<void> incrementStat(String path) async {
  final ref = FirebaseDatabase.instance.ref(path);

  await ref.runTransaction((currentData) {
    final current = (currentData as int?) ?? 0;
    return Transaction.success(current + 1);
  });
}

Future<void> updateEmotionStats(String finalEmotion, bool userAgreed) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;
  final uid = user.uid;

  await incrementStat('users/$uid/stats/emotionDistribution/$finalEmotion');

  if (userAgreed) {
    await incrementStat('users/$uid/stats/emotionFeedback/correct');
  } else {
    await incrementStat('users/$uid/stats/emotionFeedback/incorrect');
  }

  await incrementStat('users/$uid/stats/activity/songsAdded');
}

Future<void> incrementPlayCount() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;
  await incrementStat('users/${user.uid}/stats/activity/songsPlayed');
}

Future<void> incrementFaceDetection() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;
  await incrementStat('users/${user.uid}/stats/activity/faceDetectedCount');
}
