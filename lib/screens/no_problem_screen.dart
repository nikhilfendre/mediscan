import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Shown when the photo clearly IS skin (high skin coverage) but
/// neither model can find a clear skin problem in it — e.g. a photo
/// of a healthy hand. The models were trained only on diseases, so
/// without this screen they would be forced to invent one. The
/// wording is careful: "no clear problem found in this photo" is not
/// a clean bill of health.
class NoProblemScreen extends StatelessWidget {
  final File image;

  const NoProblemScreen({super.key, required this.image});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Result')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radius),
              child: Image.file(image, height: 210, fit: BoxFit.cover),
            ),
            const SizedBox(height: 28),
            const Icon(Icons.check_circle_outline,
                size: 64, color: Color(0xFF2E7D32)),
            const SizedBox(height: 14),
            const Text(
              'No clear skin problem found',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.ink),
            ),
            const SizedBox(height: 10),
            const Text(
              'This photo looks like skin, but neither AI model could '
              'find a clear skin problem in it, so no disease name has '
              'been guessed. This is not a clean bill of health — if '
              'you have a specific spot, rash or symptom, take a '
              'closer photo of that exact area. If it does not go '
              'away, please see a dermatologist.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14.5, height: 1.5, color: AppTheme.muted),
            ),
            const SizedBox(height: 22),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('For a better scan:',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.ink)),
                    SizedBox(height: 8),
                    Text('•  Fill the frame with the exact spot or area',
                        style:
                            TextStyle(fontSize: 13.5, color: AppTheme.muted)),
                    SizedBox(height: 4),
                    Text('•  Use good, even lighting — no shadows',
                        style:
                            TextStyle(fontSize: 13.5, color: AppTheme.muted)),
                    SizedBox(height: 4),
                    Text('•  Hold the camera steady and close',
                        style:
                            TextStyle(fontSize: 13.5, color: AppTheme.muted)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.camera_alt_outlined),
              label: const Text('Scan Again'),
            ),
          ],
        ),
      ),
    );
  }
}
