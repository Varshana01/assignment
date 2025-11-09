import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({Key? key}) : super(key: key);

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}
class EmotionPieChart extends StatelessWidget {
  const EmotionPieChart({super.key});

  @override
  Widget build(BuildContext context) {
    final statsState = context.findAncestorStateOfType<_StatisticsPageState>();
    final emotions = Map<String, dynamic>.from(statsState?.stats['emotionDistribution'] ?? {});

    final colors = [
      Colors.red,
      Colors.green,
      Colors.blue,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.yellow,
    ];

    return PieChart(
      PieChartData(
        sections: List.generate(emotions.length, (i) {
          final key = emotions.keys.elementAt(i);
          final value = double.tryParse(emotions[key].toString()) ?? 0;
          return PieChartSectionData(
            value: value,
            color: colors[i % colors.length],
            title: "$key\n$value",
            titleStyle: const TextStyle(fontSize: 12, color: Colors.white),
          );
        }),
      ),
    );
  }
}

class UserActivityBarChart extends StatelessWidget {
  const UserActivityBarChart({super.key});

  @override
  Widget build(BuildContext context) {
    final statsState = context.findAncestorStateOfType<_StatisticsPageState>();
    final activity = Map<String, dynamic>.from(statsState?.stats['activity'] ?? {});

    final data = {
      'Played': activity['songsPlayed'] ?? 0,
      'Added': activity['songsAdded'] ?? 0,
      'Feedback': (statsState?.stats['emotionFeedback']?['correct'] ?? 0) +
          (statsState?.stats['emotionFeedback']?['incorrect'] ?? 0),
      'Detected': activity['faceDetectedCount'] ?? 0,
    };

    return BarChart(
      BarChartData(
        barGroups: List.generate(data.length, (i) {
          final value = (data.values.elementAt(i) as num).toDouble();
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: value,
                color: Colors.white,
                width: 20,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        }),
        titlesData: FlTitlesData(
          topTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, _) {
                final index = value.toInt();
                final count = (data.values.elementAt(index) as num).toDouble();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    count.toStringAsFixed(0),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, _) {
                final index = value.toInt();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    data.keys.elementAt(index),
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(show: false),
      ),
    );
  }
}


class _StatisticsPageState extends State<StatisticsPage> {
  Map<String, dynamic> stats = {};
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchStats();
  }

  Future<void> fetchStats() async {
    final user = FirebaseAuth.instance.currentUser;
    final snapshot =
    await FirebaseDatabase.instance.ref('users/${user!.uid}/stats').get();

    if (snapshot.exists) {
      setState(() {
        stats = Map<String, dynamic>.from(snapshot.value as Map);
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final correct = stats['emotionFeedback']?['correct'] ?? 0;
    final incorrect = stats['emotionFeedback']?['incorrect'] ?? 0;
    final total = correct + incorrect;
    final accuracy = total == 0 ? 0 : ((correct / total) * 100).toStringAsFixed(1);

    final emotions = Map<String, dynamic>.from(stats['emotionDistribution'] ?? {});
    final activity = Map<String, dynamic>.from(stats['activity'] ?? {});

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("📊 Your Stats"),
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Icon(Icons.insights, size: 100, color: Colors.white),
                const SizedBox(height: 40),

                Text(
                  "🧠 Emotion Accuracy: $accuracy%",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 30),
                const Text(
                  "🎭 Emotion Distribution",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
                const SizedBox(height: 200, child: EmotionPieChart()),

                const SizedBox(height: 30),
                const Text(
                  "📈 User Activity",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
                const SizedBox(height: 200, child: UserActivityBarChart()),

                const SizedBox(height: 30),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                  onPressed: fetchStats,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
