import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

/// Scan history stored per-user in Firestore; images in Firebase Storage.
class FirestoreService {
  final _db = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  CollectionReference get _scans =>
      _db.collection('users').doc(_uid).collection('scans');

  Future<String?> uploadScanImage(File file, String scanId) async {
    try {
      final ref = _storage.ref('scans/$_uid/$scanId.jpg');
      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (_) {
      return null;
    }
  }

  /// Copies the scan photo into the app's private documents folder.
  /// Firebase Storage needs the paid Blaze plan, so on the free
  /// Spark plan the upload above returns null and History would
  /// have no photo at all; the local copy makes the photo show in
  /// History and in reports on this phone. Returns the local path,
  /// or null if the copy failed.
  Future<String?> saveScanImageLocally(File file, String scanId) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final dest = File('${dir.path}/scan_images/$scanId.jpg');
      await dest.parent.create(recursive: true);
      await file.copy(dest.path);
      return dest.path;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveScan({
    required String label,
    required double confidence,
    required List<MapEntry<String, double>> top3,
    String? imageUrl,
    String? localImagePath,
    String modelType = 'dermoscopy',
    Map<String, dynamic>? extra,
  }) async {
    await _scans.add({
      'label': label,
      'confidence': confidence,
      'top3': top3.map((e) => {'label': e.key, 'prob': e.value}).toList(),
      'imageUrl': imageUrl,
      'localImagePath': localImagePath,
      'modelType': modelType,
      'createdAt': FieldValue.serverTimestamp(),
      ...?extra,
    });
  }

  Stream<QuerySnapshot> watchScans() {
    return _scans.orderBy('createdAt', descending: true).snapshots();
  }

  Future<void> deleteScan(String docId) async {
    try {
      final snap = await _scans.doc(docId).get();
      final data = snap.data() as Map<String, dynamic>?;
      final local = data?['localImagePath'] as String?;
      if (local != null) {
        final f = File(local);
        if (await f.exists()) await f.delete();
      }
    } catch (_) {
      // Best effort only - deleting the record matters most.
    }
    await _scans.doc(docId).delete();
  }
}
