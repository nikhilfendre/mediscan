import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'lab_scan_screen.dart';
import 'scan_screen.dart';
import 'xray_hub_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  static const _pages = [
    _HomeTab(),
    HistoryScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.history_outlined),
              selectedIcon: Icon(Icons.history),
              label: 'History'),
          NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile'),
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final name =
        user?.displayName ?? user?.email?.split('@').first ?? 'there';
    return Column(
      children: [
        // Navy brand header
        Container(
          width: double.infinity,
          color: AppTheme.primary,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 8, 18),
              child: Row(
                children: [
                  const MediScanLogo(),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.notifications_none,
                        color: Colors.white),
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No new notifications')),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '$_greeting, $name',
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.ink,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'What would you like to check today?',
                  style: TextStyle(fontSize: 15, color: AppTheme.muted),
                ),
                const SizedBox(height: 22),
                // Primary action — skin scan
                Card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppTheme.radius),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ScanScreen()),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          Container(
                            height: 58,
                            width: 58,
                            decoration: const BoxDecoration(
                              color: AppTheme.accent,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.photo_camera_outlined,
                                color: Colors.white, size: 28),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Skin Scan',
                                    style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.ink)),
                                SizedBox(height: 3),
                                Text(
                                  'One photo - both AI models check it (32 common problems + 7 lesions) and the most reliable result is shown.',
                                  style: TextStyle(
                                      fontSize: 13,
                                      height: 1.4,
                                      color: AppTheme.muted),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right,
                              color: AppTheme.muted),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                // Phase-2 modules, side by side
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _MiniCard(
                        icon: Icons.medical_services_outlined,
                        title: 'X-Ray Scan',
                        soon: false,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const XrayHubScreen()),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _MiniCard(
                        icon: Icons.description_outlined,
                        title: 'Lab Report Scan',
                        soon: false,
                        subtitle: 'Blood report values check',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const LabScanScreen()),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                const DisclaimerStrip(
                  text:
                      'Medical disclaimer: MediScan provides AI-assisted information only and is not a substitute for professional medical diagnosis. Always consult a licensed healthcare provider.',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _soon(BuildContext context, String what) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$what is coming soon in Phase 2')),
    );
  }
}

class _MiniCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  /// When true the card is an inactive placeholder ("Coming soon").
  final bool soon;

  /// Small teal line shown on active cards instead of the pill.
  final String subtitle;

  const _MiniCard(
      {required this.icon,
      required this.title,
      required this.onTap,
      this.soon = true,
      this.subtitle = 'Chest, Bone, Knee + Dental'});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radius),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.07),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon,
                    color: soon ? AppTheme.muted : AppTheme.accent,
                    size: 23),
              ),
              const SizedBox(height: 12),
              Text(title,
                  style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.ink)),
              const SizedBox(height: 8),
              if (soon)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8EBF0),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Coming soon',
                      style: TextStyle(fontSize: 11.5, color: AppTheme.muted)),
                )
              else
                Row(
                  children: [
                    Flexible(
                      child: Text(subtitle,
                          style: const TextStyle(
                              fontSize: 11.5,
                              color: AppTheme.accent,
                              fontWeight: FontWeight.w600)),
                    ),
                    const Icon(Icons.chevron_right,
                        size: 14, color: AppTheme.accent),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
