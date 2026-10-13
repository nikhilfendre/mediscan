import 'dart:io';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

/// Which on-device model a scan uses.
///
/// - [dermoscopy]: the original 7-class lesion model, trained on
///   dermoscopic (magnified) images from HAM10000.
/// - [clinical]: the 32-class common-skin-problems model, trained on
///   normal camera photos (Fitzpatrick17k + SD-198 + DermNet).
/// - [xray]: the 2-class chest X-ray model (Normal / Pneumonia),
///   trained on the Kermany chest X-ray dataset. Its labels file
///   already holds display names, and its flow uses a grayscale
///   photo check instead of the skin gates.
/// - [bone]: the 2-class bone X-ray model (No fracture / Fracture),
///   trained on the FracAtlas dataset (hand, leg, hip, shoulder
///   radiographs). Same X-ray flow and grayscale check as [xray].
/// - [knee]: the 3-class knee X-ray model (Healthy / Mild
///   osteoarthritis / Severe osteoarthritis), trained on the Kaggle
///   knee osteoarthritis set (Kellgren-Lawrence grades 0-4 grouped).
/// - [dental]: the 3-class dental X-ray model (Healthy teeth /
///   Cavity / Impacted tooth), trained on per-tooth crops from the
///   DENTEX panoramic set. The user crops one tooth out of the
///   panorama and the standard 224x224 flow classifies that crop.
enum ScanMode { dermoscopy, clinical, xray, bone, knee, dental }

extension ScanModeConfig on ScanMode {
  String get modelAsset => switch (this) {
        ScanMode.clinical => 'assets/model/skin_clinical_model.tflite',
        ScanMode.xray => 'assets/model/xray_model.tflite',
        ScanMode.bone => 'assets/model/bone_model.tflite',
        ScanMode.knee => 'assets/model/knee_model.tflite',
        ScanMode.dental => 'assets/model/dental_model.tflite',
        ScanMode.dermoscopy => 'assets/model/skin_model.tflite',
      };

  String get labelsAsset => switch (this) {
        ScanMode.clinical => 'assets/labels_clinical.txt',
        ScanMode.xray => 'assets/labels_xray.txt',
        ScanMode.bone => 'assets/labels_bone.txt',
        ScanMode.knee => 'assets/labels_knee.txt',
        ScanMode.dental => 'assets/labels_dental.txt',
        ScanMode.dermoscopy => 'assets/labels.txt',
      };

  /// Stage-1 skin gate. Dermoscopic photos are mostly skin, so the
  /// threshold is strict; clinical photos may include hair, nails or
  /// background, so the gate is looser there. The X-ray flows do not
  /// use the skin gate at all (0 = always passes).
  double get skinThreshold => switch (this) {
        ScanMode.clinical => 0.15,
        ScanMode.xray => 0.0,
        ScanMode.bone => 0.0,
        ScanMode.knee => 0.0,
        ScanMode.dental => 0.0,
        ScanMode.dermoscopy => 0.35,
      };

  /// Stored with each scan in Firestore.
  String get storageKey => switch (this) {
        ScanMode.clinical => 'clinical',
        ScanMode.xray => 'xray',
        ScanMode.bone => 'bone',
        ScanMode.knee => 'knee',
        ScanMode.dental => 'dental',
        ScanMode.dermoscopy => 'dermoscopy',
      };

  /// Human-readable line used in reports.
  String get reportLabel => switch (this) {
        ScanMode.clinical =>
          'Common skin problems model - 32 conditions (camera photos)',
        ScanMode.xray =>
          'Chest X-ray model - 2 classes (Normal / Pneumonia)',
        ScanMode.bone =>
          'Bone X-ray model - 2 classes (No fracture / Fracture)',
        ScanMode.knee =>
          'Knee X-ray model - 3 classes (Healthy / Mild / Severe osteoarthritis)',
        ScanMode.dental =>
          'Dental X-ray model - 3 classes per tooth (Healthy teeth / Cavity / Impacted tooth)',
        ScanMode.dermoscopy =>
          'Skin lesion model - 7 conditions (dermoscopic images)',
      };

  static ScanMode fromStorage(String? key) => switch (key) {
        'clinical' => ScanMode.clinical,
        'xray' => ScanMode.xray,
        'bone' => ScanMode.bone,
        'knee' => ScanMode.knee,
        'dental' => ScanMode.dental,
        _ => ScanMode.dermoscopy,
      };
}

/// Display names for the clinical model's raw class keys. The
/// dermoscopic model's labels.txt already holds display names.
const Map<String, String> clinicalDisplayNames = {
  'acne': 'Acne',
  'actinic_keratosis_clinical': 'Actinic keratosis',
  'alopecia': 'Alopecia',
  'athletes_foot': "Athlete's foot",
  'basal_cell_carcinoma': 'Basal cell carcinoma',
  'benign_keratosis': 'Benign keratosis',
  'candidiasis': 'Candidiasis',
  'cellulitis': 'Cellulitis',
  'contact_dermatitis': 'Contact dermatitis',
  'dermatofibroma': 'Dermatofibroma',
  'eczema': 'Eczema',
  'folliculitis': 'Folliculitis',
  'herpes_simplex': 'Herpes simplex',
  'keloid': 'Keloid',
  'lichen_planus': 'Lichen planus',
  'melanoma_clinical': 'Melanoma',
  'melasma_pigmentation': 'Melasma / pigmentation',
  'nail_fungus': 'Nail fungus',
  'nevus_clinical': 'Nevus',
  'pityriasis_rosea': 'Pityriasis rosea',
  'pityriasis_versicolor': 'Pityriasis versicolor',
  'psoriasis': 'Psoriasis',
  'rosacea': 'Rosacea',
  'scabies': 'Scabies',
  'seborrheic_dermatitis': 'Seborrheic dermatitis',
  'skin_tags': 'Skin tags',
  'squamous_cell_carcinoma': 'Squamous cell carcinoma',
  'tinea': 'Tinea',
  'urticaria': 'Urticaria',
  'vascular_lesion': 'Vascular lesion',
  'vitiligo': 'Vitiligo',
  'warts': 'Warts',
};

/// Result of a full scan analysis: predictions plus the stage-1 skin
/// check that guards the classifier.
class SkinAnalysis {
  /// (display label, probability) pairs, sorted by probability descending.
  final List<MapEntry<String, double>> results;

  /// Fraction of the photo classified as skin-coloured pixels (0..1).
  final double skinRatio;

  /// Skin ratio at or above which the photo passes the stage-1 gate
  /// (depends on the scan mode).
  final double skinThreshold;

  const SkinAnalysis(this.results, this.skinRatio, this.skinThreshold);

  double get topConfidence => results.first.value;

  double get margin =>
      results.length > 1 ? results.first.value - results[1].value : 1.0;

  /// Stage-1 gate: real skin photos pass; random objects, documents
  /// and scenes fall far below the ratio.
  bool get isSkin => skinRatio >= skinThreshold;

  /// Weak or ambiguous predictions are flagged instead of being
  /// presented as confident answers.
  bool get isUncertain => topConfidence < 0.65 || margin < 0.12;
}



/// On-device skin classifier (EfficientNet-B0 converted to TFLite).
/// Runs fully offline — no image ever leaves the phone for inference.
///
/// Two-stage pipeline:
///  1. Skin check (colour analysis) rejects non-skin photos, which a
///     closed-set classifier would otherwise force into a disease class.
///  2. Classification with test-time augmentation (original +
///     horizontal + vertical flip, averaged) for a more stable result.
class SkinModelService {
  static final SkinModelService _instance = SkinModelService._internal();
  factory SkinModelService() => _instance;
  SkinModelService._internal();

  final Map<ScanMode, Interpreter> _interpreters = {};
  final Map<ScanMode, List<String>> _labels = {};

  bool isLoaded(ScanMode mode) => _interpreters.containsKey(mode);

  Future<void> load(ScanMode mode) async {
    if (_interpreters.containsKey(mode)) return;
    _interpreters[mode] = await Interpreter.fromAsset(mode.modelAsset);
    final raw = await rootBundle.loadString(mode.labelsAsset);
    _labels[mode] =
        raw.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
  }

  String _display(ScanMode mode, String rawLabel) =>
      mode == ScanMode.clinical
          ? (clinicalDisplayNames[rawLabel] ?? rawLabel)
          : rawLabel;

  Future<SkinAnalysis> analyze(File imageFile, ScanMode mode) async {
    await load(mode);
    final interpreter = _interpreters[mode]!;
    final labels = _labels[mode]!;
    final bytes = await imageFile.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) throw Exception('Could not decode image');
    final resized = img.copyResize(decoded, width: 224, height: 224);

    final ratio = _skinRatio(resized);

    // Test-time augmentation: run the model on the photo and its two
    // flips, then average the probability distributions.
    final totals = List<double>.filled(labels.length, 0.0);
    for (final flip in const [
      [false, false],
      [true, false],
      [false, true],
    ]) {
      final input = _inputFor(resized, flipX: flip[0], flipY: flip[1]);
      final output = List.generate(1, (_) => List.filled(labels.length, 0.0));
      interpreter.run(input, output);
      for (var i = 0; i < labels.length; i++) {
        totals[i] += output[0][i] / 3.0;
      }
    }

    final entries = List.generate(
      labels.length,
      (i) => MapEntry(_display(mode, labels[i]), totals[i]),
    );
    entries.sort((a, b) => b.value.compareTo(a.value));
    return SkinAnalysis(entries, ratio, mode.skinThreshold);
  }

  /// Builds the [1, 224, 224, 3] float32 input tensor (RGB in [0, 1]).
  /// ImageNet normalization + softmax are baked into the TFLite graph.
  List _inputFor(img.Image im, {bool flipX = false, bool flipY = false}) {
    return List.generate(
      1,
      (_) => List.generate(224, (y) {
        final sy = flipY ? 223 - y : y;
        return List.generate(224, (x) {
          final sx = flipX ? 223 - x : x;
          final p = im.getPixel(sx, sy);
          return [p.r / 255.0, p.g / 255.0, p.b / 255.0];
        });
      }),
    );
  }

  /// Skin-colour detection in YCbCr space. The classic Chai–Ngan
  /// ranges (Cb 77–127, Cr 133–173) were designed for ordinary camera
  /// photos; dermoscopic images are red-shifted by the magnifier
  /// light, which pushes Cb above 127 and made the classic rule
  /// reject real lesions (a vascular-lesion sample scored 1% skin).
  /// The bounds below were re-calibrated on the sample set: every
  /// skin sample scores 0.94+, while paper, cloth, walls and other
  /// non-skin scenes stay at 0.14 or below.
  double _skinRatio(img.Image im) {
    var skin = 0;
    final total = im.width * im.height;
    for (var y = 0; y < im.height; y++) {
      for (var x = 0; x < im.width; x++) {
        final p = im.getPixel(x, y);
        final r = p.r.toDouble();
        final g = p.g.toDouble();
        final b = p.b.toDouble();
        final cb = 128 - 0.168736 * r - 0.331264 * g + 0.5 * b;
        final cr = 128 + 0.5 * r - 0.418688 * g - 0.081312 * b;
        if (cb >= 77 && cb <= 150 && cr >= 133 && cr <= 190) skin++;
      }
    }
    return skin / total;
  }
}
