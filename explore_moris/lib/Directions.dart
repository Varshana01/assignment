import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlng;



class DirectionsPage extends StatelessWidget {
  const DirectionsPage({super.key});

  // Example coordinates for Le Morne Brabant
  static latlng.LatLng destination = latlng.LatLng(-20.4230, 57.3059);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF87CEEB),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text(
              "DIRECTIONS",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                fontFamily: 'Times New Roman',
                color: Colors.black,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.map, color: Colors.black),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Map Section
          SizedBox(
            height: 250,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: destination,
                initialZoom: 13,
              ),
              children: [
                TileLayer(
                  urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                  userAgentPackageName: 'com.example.exploremoris',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: destination,
                      width: 60,
                      height: 60,
                      child: const Icon(
                        Icons.location_pin,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Trip Insights + Buttons
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Le Morne Brabant",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Trip Insights",
                      style: TextStyle(color: Colors.black54),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildInfoCard("Total Distance", "20 km", "+5 km"),
                      _buildInfoCard("Time Left", "2 hours", "-30 min"),
                      _buildInfoCard("Stops", "3", ""),
                    ],
                  ),
                  const SizedBox(height: 24),

                  _buildActionButton("Save Route", Icons.save_alt,
                      Colors.amber, Colors.black, () {}),
                  const SizedBox(height: 12),
                  _buildActionButton("Virtual explore", Icons.travel_explore,
                      Colors.amber, Colors.black, () {}),
                  const SizedBox(height: 12),
                  _buildActionButton("Start Navigation", Icons.navigation,
                      const Color(0xFF20B2AA), Colors.white, () {}),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Trip Info Card
  Widget _buildInfoCard(String title, String main, String subtitle) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[100],
        ),
        child: Column(
          children: [
            Text(title, style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 8),
            Text(
              main,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
            if (subtitle.isNotEmpty)
              Text(subtitle, style: const TextStyle(color: Colors.black45)),
          ],
        ),
      ),
    );
  }

  // Custom Button
  Widget _buildActionButton(String label, IconData icon, Color bg, Color text,
      VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: text),
        label: Text(
          label,
          style: TextStyle(
            color: text,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: text == Colors.black ? Colors.black : bg),
          ),
        ),
      ),
    );
  }
}
