import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/firestore_service.dart';
import '../services/lab_report_service.dart';
import '../services/skin_model_service.dart';
import '../theme/app_theme.dart';
import 'lab_result_screen.dart';
import 'report_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = FirestoreService();
    return Scaffold(
      appBar: AppBar(title: const Text('Scan History')),
      body: StreamBuilder<QuerySnapshot>(
        stream: store.watchScans(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: AppTheme.muted),
                  SizedBox(height: 12),
                  Text('No scans yet',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.ink)),
                  SizedBox(height: 4),
                  Text('Your past scans will appear here',
                      style: TextStyle(color: AppTheme.muted)),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final d = docs[i].data() as Map<String, dynamic>;
              final ts = d['createdAt'] as Timestamp?;
              final date = ts == null
                  ? ''
                  : DateFormat('dd MMM yyyy, hh:mm a').format(ts.toDate());
              final conf = (d['confidence'] as num?)?.toDouble() ?? 0;
              return Ink(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.radius),
                  border: const Border(
                    left: BorderSide(color: AppTheme.accent, width: 4),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppTheme.radius),
                  onTap: () {
                    // Rebuild the top-3 results stored with this scan and
                    // open its full report (details + PDF).
                    final rawTop3 = (d['top3'] as List?) ?? const [];
                    var results = rawTop3
                        .map((m) => MapEntry(
                              (m as Map)['label']?.toString() ?? 'Unknown',
                              ((m)['prob'] as num?)?.toDouble() ?? 0,
                            ))
                        .toList();
                    if (results.isEmpty) {
                      results = [
                        MapEntry(d['label']?.toString() ?? 'Unknown', conf)
                      ];
                    }
                    if (d['modelType'] == 'lab') {
                      final rows = ((d['labRows'] as List?) ?? const [])
                          .map((m) =>
                              LabTestResult.fromMap(m as Map<dynamic, dynamic>))
                          .toList();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LabResultScreen(
                            results: rows,
                            imageUrl: d['imageUrl'] as String?,
                            localImagePath: d['localImagePath'] as String?,
                            scannedAt: ts?.toDate(),
                            fromHistory: true,
                          ),
                        ),
                      );
                      return;
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReportScreen(
                          imageUrl: d['imageUrl'] as String?,
                          localImagePath: d['localImagePath'] as String?,
                          results: results,
                          scannedAt: ts?.toDate(),
                          mode: ScanModeConfig.fromStorage(
                              d['modelType'] as String?),
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
                    child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: _thumb(d),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(d['label'] ?? 'Unknown',
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.ink)),
                            const SizedBox(height: 2),
                            if (d['modelType'] != 'lab') ...[
                              Text(
                                  '${(conf * 100).toStringAsFixed(1)}% confidence',
                                  style: const TextStyle(
                                      fontSize: 13, color: AppTheme.muted)),
                              const SizedBox(height: 2),
                            ],
                            Text(date,
                                style: const TextStyle(
                                    fontSize: 12, color: AppTheme.muted)),
                            if (d['modelType'] == 'clinical') ...[
                              const SizedBox(height: 2),
                              const Text('Common skin problems - 32',
                                  style: TextStyle(
                                      fontSize: 11.5,
                                      color: AppTheme.accent,
                                      fontWeight: FontWeight.w600)),
                            ],
                            if (d['modelType'] == 'xray') ...[
                              const SizedBox(height: 2),
                              const Text('Chest X-ray - Normal / Pneumonia',
                                  style: TextStyle(
                                      fontSize: 11.5,
                                      color: AppTheme.accent,
                                      fontWeight: FontWeight.w600)),
                            ],
                            if (d['modelType'] == 'bone') ...[
                              const SizedBox(height: 2),
                              const Text('Bone X-ray - Fracture check',
                                  style: TextStyle(
                                      fontSize: 11.5,
                                      color: AppTheme.accent,
                                      fontWeight: FontWeight.w600)),
                            ],
                            if (d['modelType'] == 'knee') ...[
                              const SizedBox(height: 2),
                              const Text('Knee X-ray - Osteoarthritis',
                                  style: TextStyle(
                                      fontSize: 11.5,
                                      color: AppTheme.accent,
                                      fontWeight: FontWeight.w600)),
                            ],
                            if (d['modelType'] == 'dental') ...[
                              const SizedBox(height: 2),
                              const Text('Dental X-ray - Tooth check',
                                  style: TextStyle(
                                      fontSize: 11.5,
                                      color: AppTheme.accent,
                                      fontWeight: FontWeight.w600)),
                            ],
                            if (d['modelType'] == 'lab') ...[
                              const SizedBox(height: 2),
                              const Text('Lab Report - Blood test values check',
                                  style: TextStyle(
                                      fontSize: 11.5,
                                      color: AppTheme.accent,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: AppTheme.danger),
                        onPressed: () => store.deleteScan(docs[i].id),
                      ),
                      const Icon(Icons.chevron_right,
                          size: 20, color: AppTheme.muted),
                    ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// Scan thumbnail: prefer the on-device photo copy (Firebase
  /// Storage needs the paid plan, so the URL is usually absent),
  /// then the remote URL, then the placeholder.
  Widget _thumb(Map<String, dynamic> d) {
    final local = d['localImagePath'] as String?;
    if (local != null) {
      final f = File(local);
      if (f.existsSync()) {
        return Image.file(f,
            width: 62,
            height: 62,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _thumbPlaceholder());
      }
    }
    if (d['imageUrl'] != null) {
      return Image.network(d['imageUrl'],
          width: 62,
          height: 62,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _thumbPlaceholder());
    }
    return _thumbPlaceholder();
  }

  Widget _thumbPlaceholder() {
    return Container(
      width: 62,
      height: 62,
      color: const Color(0xFFE8EBF0),
      child: const Icon(Icons.image_outlined, color: AppTheme.muted),
    );
  }
}
