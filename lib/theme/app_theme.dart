import 'package:flutter/material.dart';

/// MediScan design system — deep navy + teal on a light clinical background.
/// One palette, one corner radius family, one spacing scale across all screens,
/// so the app reads as a single professionally designed product.
class AppTheme {
  // Brand palette
  static const primary = Color(0xFF0D2B4E); // deep navy
  static const primaryDark = Color(0xFF081D38);
  static const accent = Color(0xFF009688); // teal
  static const background = Color(0xFFF4F6FA);
  static const surface = Colors.white;
  static const ink = Color(0xFF1A2433); // main text
  static const muted = Color(0xFF6B7686); // secondary text
  static const border = Color(0xFFE2E7EF);
  static const danger = Color(0xFFC62828);
  static const dangerBg = Color(0xFFFDECEC);
  static const warning = Color(0xFFF9A825);
  static const amberBg = Color(0xFFFFF4D6);
  static const amberBorder = Color(0xFFF2D38A);
  static const amberText = Color(0xFF7A5200);

  static const radius = 16.0;

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          primary: primary,
          surface: surface,
        ),
        scaffoldBackgroundColor: background,
        appBarTheme: const AppBarTheme(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        cardTheme: CardThemeData(
          color: surface,
          elevation: 1,
          shadowColor: Colors.black.withOpacity(0.10),
          surfaceTintColor: Colors.transparent,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 52),
            textStyle:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: ink,
            minimumSize: const Size(double.infinity, 52),
            textStyle:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            side: const BorderSide(color: border),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surface,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primary, width: 1.6),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: surface,
          indicatorColor: primary.withOpacity(0.10),
          elevation: 3,
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected ? primary : muted,
            );
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return IconThemeData(color: selected ? primary : muted);
          }),
        ),
        dividerTheme: const DividerThemeData(color: border, thickness: 1),
      );
}

/// Brand lockup: shield-cross mark + "MediScan" wordmark.
/// Used on the splash, login header and home header so branding is identical.
class MediScanLogo extends StatelessWidget {
  final double iconSize;
  final double fontSize;
  final Color color;

  const MediScanLogo({
    super.key,
    this.iconSize = 30,
    this.fontSize = 24,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.health_and_safety, size: iconSize, color: color),
        const SizedBox(width: 10),
        Text(
          'MediScan',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

/// Amber medical-disclaimer strip used on Home and in the Report.
class DisclaimerStrip extends StatelessWidget {
  final String text;

  const DisclaimerStrip({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.amberBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.amberBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 20, color: AppTheme.amberText),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12.5,
                height: 1.45,
                color: AppTheme.amberText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
