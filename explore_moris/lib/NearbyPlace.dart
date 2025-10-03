import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' show cos, sqrt, asin;

import 'PlaceDetails.dart'; // Page that will show details of each place

class NearbyPlacesPage extends StatefulWidget {
  const NearbyPlacesPage({super.key});

  @override
  _NearbyPlacesPageState createState() => _NearbyPlacesPageState();
}

class _NearbyPlacesPageState extends State<NearbyPlacesPage> {
  Position? _userPosition; // This will hold the user's current location

  // Hardcoded list of places (for testing, will later come from Firebase)
  final List<Map<String, dynamic>> _places = [
    {
      "id": "place1",
      "name": "Caudan Waterfront",
      "latitude": -20.1605,
      "longitude": 57.5012,
      "imageUrl": "https://example.com/caudan.jpg",
      "description":
          "A lively waterfront with shopping, dining, and entertainment.",
    },
    {
      "id": "place2",
      "name": "Aapravasi Ghat",
      "latitude": -20.1609,
      "longitude": 57.4975,
      "imageUrl": "https://example.com/aapravasi.jpg",
      "description": "Historic UNESCO World Heritage Site in Port Louis.",
    },
  ];

  @override
  void initState() {
    super.initState();
    _getUserLocation(); // When the page loads, get the user’s location
  }

  // 🔹 Get the user’s current location using Geolocator
  Future<void> _getUserLocation() async {
    try {
      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() => _userPosition = pos);
    } catch (e) {
      print("Error getting location: $e");
    }
  }

  // 🔹 Calculate distance between two points (Haversine formula in KM)
  double _calculateDistance(lat1, lon1, lat2, lon2) {
    const p = 0.017453292519943295; // pi / 180
    final a =
        0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // 12742 km = Earth diameter
  }

  @override
  Widget build(BuildContext context) {
    // Copy the list of places so we can sort it by distance
    List<Map<String, dynamic>> sortedPlaces = [..._places];

    if (_userPosition != null) {
      // Sort places from nearest → farthest
      sortedPlaces.sort((a, b) {
        double distA = _calculateDistance(
          _userPosition!.latitude,
          _userPosition!.longitude,
          a['latitude'],
          a['longitude'],
        );
        double distB = _calculateDistance(
          _userPosition!.latitude,
          _userPosition!.longitude,
          b['latitude'],
          b['longitude'],
        );
        return distA.compareTo(distB);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Nearby Places"),
        backgroundColor: Colors.teal,
      ),

      // If location not ready yet → show loading spinner
      body:
          _userPosition == null
              ? const Center(child: CircularProgressIndicator())
              // If location is ready → show sorted list of places
              : ListView.builder(
                itemCount: sortedPlaces.length,
                itemBuilder: (context, index) {
                  final place = sortedPlaces[index];

                  // Calculate distance of each place from user
                  final distance = _calculateDistance(
                    _userPosition!.latitude,
                    _userPosition!.longitude,
                    place['latitude'],
                    place['longitude'],
                  ).toStringAsFixed(1); // 1 decimal place

                  // Card for each place
                  return Card(
                    margin: const EdgeInsets.all(10),
                    child: ListTile(
                      leading: Image.network(
                        place['imageUrl'], // Show image of place
                        width: 60,
                        fit: BoxFit.cover,
                      ),
                      title: Text(place['name']),
                      subtitle: Text("$distance km away"),
                      trailing: ElevatedButton(
                        onPressed: () {
                          // Navigate to PlaceDetailsPage when button is clicked
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PlaceDetailsPage(place: place),
                            ),
                          );
                        },
                        child: const Text("Details"),
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
