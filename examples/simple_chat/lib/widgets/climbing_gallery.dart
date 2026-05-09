import 'package:flutter/material.dart';
import '../db/climbing_db.dart';
import 'climbing.dart';

class ClimbingGallery extends StatelessWidget {
  const ClimbingGallery({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Climbing Locations Gallery'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: climbingLocations.length,
        itemBuilder: (context, index) {
          final location = climbingLocations[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: ClimbingLocation(info: location),
          );
        },
      ),
    );
  }
}
