import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Shown when the X-ray flow's photo check rejects a photo: X-rays
/// are grayscale images, so a strongly coloured photo (skin, a room,
/// a document) cannot be a chest X-ray and is never sent to the
/// X-ray model.
class NotXrayScreen extends StatelessWidget {
  final File image;

  /// What the user was asked to scan, e.g. 'a chest X-ray'.
  final String subject;

  const NotXrayScreen(
      {super.key, required this.image, this.subject = 'a chest X-ray'});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Image Check')),
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
            const Icon(Icons.image_not_supported_outlined,
                size: 64, color: AppTheme.danger),
            const SizedBox(height: 14),
            Text(
              'This is not $subject',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.ink),
            ),
            const SizedBox(height: 10),
            const Text(
              'MediScan can only analyze X-ray images, which are '
              'black-and-white (grayscale). This photo has strong '
              'colours, so it does not look like an X-ray and no '
              'prediction was made.',
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
                    Text('For a valid scan:',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.ink)),
                    SizedBox(height: 8),
                    Text('•  Use the digital X-ray image from your report, or photograph the X-ray film against a white light',
                        style:
                            TextStyle(fontSize: 13.5, color: AppTheme.muted)),
                    SizedBox(height: 4),
                    Text('•  Fill the frame with the full X-ray',
                        style:
                            TextStyle(fontSize: 13.5, color: AppTheme.muted)),
                    SizedBox(height: 4),
                    Text('•  Avoid glare, shadows and tilted angles',
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
