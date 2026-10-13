import 'package:flutter/material.dart';
import '../services/skin_model_service.dart';
import '../theme/app_theme.dart';
import 'xray_scan_screen.dart';

/// X-Ray section hub: choose which X-ray model to scan with.
class XrayHubScreen extends StatelessWidget {
  const XrayHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('X-Ray Scan')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Which X-ray do you want to check?',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.ink),
            ),
            const SizedBox(height: 6),
            const Text(
              'Each model is trained only for its own body area - a '
              'chest model cannot read a bone X-ray, and the other way '
              'around.',
              style: TextStyle(fontSize: 13.5, color: AppTheme.muted),
            ),
            const SizedBox(height: 20),
            _XrayCard(
              icon: Icons.medical_services_outlined,
              title: 'Chest X-Ray',
              subtitle: 'Normal / Pneumonia screening',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        const XrayScanScreen(mode: ScanMode.xray)),
              ),
            ),
            const SizedBox(height: 14),
            _XrayCard(
              icon: Icons.accessibility_new_outlined,
              title: 'Bone X-Ray',
              subtitle: 'Fracture check - hand, leg, hip, shoulder',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        const XrayScanScreen(mode: ScanMode.bone)),
              ),
            ),
            const SizedBox(height: 14),
            _XrayCard(
              icon: Icons.directions_run_outlined,
              title: 'Knee X-Ray',
              subtitle: 'Osteoarthritis check - Healthy / Mild / Severe',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        const XrayScanScreen(mode: ScanMode.knee)),
              ),
            ),
            const SizedBox(height: 14),
            _XrayCard(
              icon: Icons.grid_view_outlined,
              title: 'Dental X-Ray',
              subtitle:
                  'Tooth check, one tooth at a time - Healthy / Cavity / Impacted',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        const XrayScanScreen(mode: ScanMode.dental)),
              ),
            ),
            const SizedBox(height: 20),
            const DisclaimerStrip(
              text:
                  'X-ray results are AI-generated for screening support only and are not a medical diagnosis.',
            ),
          ],
        ),
      ),
    );
  }
}

class _XrayCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _XrayCard(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radius),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                height: 52,
                width: 52,
                decoration: BoxDecoration(
                  color: AppTheme.accent.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppTheme.accent, size: 27),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.ink)),
                    const SizedBox(height: 3),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 13, color: AppTheme.muted)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppTheme.muted),
            ],
          ),
        ),
      ),
    );
  }
}
