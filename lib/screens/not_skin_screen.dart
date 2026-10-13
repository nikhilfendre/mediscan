import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Shown when the stage-1 skin check rejects a photo: the classifier is
/// never run on non-skin images, so the app can never present a random
/// object as a disease prediction.
class NotSkinScreen extends StatelessWidget {
  final File image;
  final double skinRatio;

  /// True when the scan came from the common-problems (clinical) mode.
  final bool clinical;

  /// True when the photo passed the colour check but NEITHER model
  /// could recognize a skin condition in it with any certainty (e.g.
  /// a wall, furniture or a random scene). The wording differs: the
  /// problem is not the skin colour, it is that no model could read
  /// the photo as a skin problem.
  final bool unclear;

  const NotSkinScreen(
      {super.key,
      required this.image,
      required this.skinRatio,
      this.clinical = false,
      this.unclear = false});

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
              unclear
                  ? 'Could not read this photo'
                  : clinical
                      ? 'This is not a skin photo'
                      : 'This is not a skin lesion photo',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.ink),
            ),
            const SizedBox(height: 10),
            Text(
              unclear
                  ? 'This does not look like a clear photo of a skin '
                      'problem. Neither AI model could recognize a skin '
                      'condition in it, so no prediction was made.'
                  : (clinical
                          ? 'MediScan can only analyze photos of skin, scalp '
                              'or nails. '
                          : 'MediScan can only analyze close-up photos of '
                              'skin lesions. ') +
                      'In this photo only '
                          '${(skinRatio * 100).toStringAsFixed(0)}% '
                          'of the image looks like skin, so no prediction '
                          'was made.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 14.5, height: 1.5, color: AppTheme.muted),
            ),
            const SizedBox(height: 22),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('For a valid scan:',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.ink)),
                    const SizedBox(height: 8),
                    Text(
                        clinical
                            ? '•  Fill the frame with the affected skin, '
                                'scalp or nail area'
                            : '•  Fill the frame with the skin lesion',
                        style: const TextStyle(
                            fontSize: 13.5, color: AppTheme.muted)),
                    const SizedBox(height: 4),
                    const Text('•  Use good, even lighting — no shadows',
                        style:
                            TextStyle(fontSize: 13.5, color: AppTheme.muted)),
                    const SizedBox(height: 4),
                    const Text('•  Hold the camera steady and close',
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
