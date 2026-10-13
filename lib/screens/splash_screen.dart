import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppTheme.primary,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Column(
            children: [
              Spacer(),
              Icon(Icons.health_and_safety, size: 96, color: Colors.white),
              SizedBox(height: 20),
              Text(
                'MediScan',
                style: TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'AI-assisted skin screening',
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
              Spacer(),
              SizedBox(
                height: 26,
                width: 26,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5),
              ),
              SizedBox(height: 14),
              Text(
                'Version 1.0.0',
                style: TextStyle(fontSize: 12, color: Colors.white54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
