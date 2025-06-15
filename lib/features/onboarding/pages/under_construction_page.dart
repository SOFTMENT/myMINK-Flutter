import 'package:flutter/material.dart';

class UnderConstructionPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo or Icon
              const Icon(
                Icons.build_rounded,
                size: 100,
                color: Colors.blueAccent,
              ),
              const SizedBox(height: 20),

              // "Coming Soon" Text
              const Text(
                'App Coming Soon!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),

              // Description Text
              Text(
                'We are currently working on something amazing. Stay tuned!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
