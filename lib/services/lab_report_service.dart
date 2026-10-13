import 'dart:io';
import 'dart:ui';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// One measured value read from a lab report, compared with a
/// reference range. (In the app results and PDF these are shown as
/// the RAW measured value and the range it was compared with.)
class LabTestResult {
  final String name;
  final double value;
  final String unit;

  /// Reference range actually used - the range printed on the
  /// report when it could be read, otherwise the built-in standard
  /// adult range ([rangeFromReport] says which).
  final double low;
  final double high;
  final bool rangeFromReport;

  const LabTestResult({
    required this.name,
    required this.value,
    required this.unit,
    required this.low,
    required this.high,
    required this.rangeFromReport,
  });

  bool get isLow => value < low;
  bool get isHigh => value > high;
  bool get isNormal => !isLow && !isHigh;
  String get status => isLow ? 'Low' : (isHigh ? 'High' : 'Normal');

  String get valueText => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);

  String get rangeText {
    String f(double v) =>
        v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
    return '${f(low)} - ${f(high)} $unit';
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'value': value,
        'unit': unit,
        'low': low,
        'high': high,
        'rangeFromReport': rangeFromReport,
      };

  factory LabTestResult.fromMap(Map<dynamic, dynamic> m) => LabTestResult(
        name: m['name']?.toString() ?? 'Test',
        value: (m['value'] as num?)?.toDouble() ?? 0,
        unit: m['unit']?.toString() ?? '',
        low: (m['low'] as num?)?.toDouble() ?? 0,
        high: (m['high'] as num?)?.toDouble() ?? 0,
        rangeFromReport: m['rangeFromReport'] == true,
      );
}

/// A test the parser knows how to find on a printed report, with
/// its standard adult reference range (used only when the report's
/// own printed range cannot be read).
class _LabTestDef {
  final String name;
  final List<String> aliases;
  final String unit;
  final double low;
  final double high;

  /// Plausibility window - a "value" outside this is not this test
  /// (protects against dates, phone numbers and ref numbers that
  /// OCR may place on the same line).
  final double saneMin;
  final double saneMax;

  /// Normalises the many ways Indian labs print counts (e.g. WBC
  /// as 8.5 thousand, platelets as 1.85 lakh) into raw counts.
  final double Function(double v, String line)? scale;

  const _LabTestDef(this.name, this.aliases, this.unit, this.low, this.high,
      this.saneMin, this.saneMax,
      {this.scale});
}

double _scaleWbc(double v, String line) => v < 100 ? v * 1000 : v;

double _scalePlatelets(double v, String line) {
  if (v < 10) return v * 100000; // "1.85" lakh style
  if (v < 1000) return v * 1000; // "185" thousand style
  return v;
}

final List<_LabTestDef> _kLabTests = [
  _LabTestDef('Hemoglobin', ['hemoglobin', 'haemoglobin', 'hb '], 'g/dL',
      12.0, 17.0, 3, 22),
  _LabTestDef('RBC Count', ['rbc count', 'r.b.c', 'red blood cell'], 'mill/cumm',
      4.0, 5.9, 1, 9),
  _LabTestDef(
      'WBC Count',
      ['wbc count', 'total leukocyte', 't.l.c', 'tlc', 'white blood cell'],
      '/cumm',
      4000,
      11000,
      500,
      500000,
      scale: _scaleWbc),
  _LabTestDef('Platelet Count', ['platelet'], '/cumm', 150000, 450000, 5000,
      2000000,
      scale: _scalePlatelets),
  _LabTestDef('Hematocrit (PCV)', ['hematocrit', 'haematocrit', 'pcv', 'packed cell'],
      '%', 36, 52, 10, 75),
  _LabTestDef('MCV', ['mcv', 'mean corpuscular volume'], 'fL', 80, 100, 40, 140),
  // MCHC is listed (and therefore matched) BEFORE MCH, and
  // parseLines never lets two tests consume the same OCR line -
  // otherwise an "MCHC" row would also be read as "MCH".
  _LabTestDef('MCHC', ['mchc'], 'g/dL', 32, 36, 15, 50),
  _LabTestDef('MCH', ['mch'], 'pg', 27, 33, 10, 60),
  _LabTestDef('RDW', ['rdw'], '%', 11.5, 14.5, 5, 30),
  _LabTestDef('ESR', ['esr', 'erythrocyte sedimentation'], 'mm/hr', 0, 20, 0, 140),
  _LabTestDef('Blood Sugar (Fasting)',
      ['fasting blood sugar', 'fbs', 'glucose fasting', 'sugar fasting'],
      'mg/dL', 70, 100, 30, 600),
  _LabTestDef('Blood Sugar (Random)',
      ['random blood sugar', 'rbs', 'glucose random', 'sugar random'], 'mg/dL',
      70, 140, 30, 700),
  _LabTestDef('HbA1c', ['hba1c', 'glycated'], '%', 4.0, 5.6, 2, 18),
  _LabTestDef('Total Cholesterol', ['total cholesterol', 'cholesterol total'],
      'mg/dL', 0, 200, 40, 600),
  _LabTestDef('Triglycerides', ['triglyceride'], 'mg/dL', 0, 150, 20, 1500),
  _LabTestDef('HDL Cholesterol', ['hdl'], 'mg/dL', 40, 999, 5, 150),
  _LabTestDef('LDL Cholesterol', ['ldl'], 'mg/dL', 0, 100, 5, 400),
  _LabTestDef('Creatinine', ['creatinine'], 'mg/dL', 0.6, 1.3, 0.1, 15),
  _LabTestDef('Urea', ['urea'], 'mg/dL', 15, 40, 2, 250),
  _LabTestDef('SGOT (AST)', ['sgot', 'ast '], 'U/L', 0, 40, 0, 2000),
  _LabTestDef('SGPT (ALT)', ['sgpt', 'alt '], 'U/L', 0, 41, 0, 2000),
  _LabTestDef('Bilirubin (Total)', ['bilirubin'], 'mg/dL', 0.1, 1.2, 0, 30),
  _LabTestDef('TSH', ['tsh', 'thyroid stimulating'], 'uIU/mL', 0.4, 4.5, 0, 100),
];

/// Reads a printed lab report photo with on-device OCR (ML Kit)
/// and extracts the known test values with their flags.
class LabReportService {
  static final RegExp _numRe = RegExp(r'\d[\d,]*\.?\d*');
  static final RegExp _rangeRe =
      RegExp(r'(\d[\d,]*\.?\d*)\s*[-–—]\s*(\d[\d,]*\.?\d*)');

  static double? _parseNum(String s) {
    final v = double.tryParse(s.replaceAll(',', ''));
    return v;
  }

  /// Runs OCR on [image] and returns the values found (possibly
  /// empty when the photo could not be read as a lab report).
  Future<List<LabTestResult>> analyze(File image) async {
    final recognizer =
        TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final input = InputImage.fromFile(image);
      final recognized = await recognizer.processImage(input);
      final lines = <String>[];
      final boxed = <MapEntry<String, Rect>>[];
      for (final block in recognized.blocks) {
        for (final line in block.lines) {
          lines.add(line.text);
          boxed.add(MapEntry(line.text, line.boundingBox));
        }
      }
      // ML Kit often returns a table column-by-column or as small
      // fragments ("Hemoglobin", "10.8", "13.0 - 17.0" as separate
      // lines), so the visual rows are first rebuilt from the
      // fragments' positions; the raw lines stay as a fallback.
      final candidates = <String>[
        ..._reconstructRows(boxed),
        ...lines,
      ];
      return parseLines(candidates);
    } finally {
      recognizer.close();
    }
  }

  /// Groups OCR line fragments that sit at the same height into
  /// visual rows (sorted left to right), like the printed table.
  static List<String> _reconstructRows(List<MapEntry<String, Rect>> boxed) {
    final items = boxed.where((e) => e.value.height > 0).toList()
      ..sort((a, b) => a.value.center.dy.compareTo(b.value.center.dy));
    final rows = <String>[];
    var group = <MapEntry<String, Rect>>[];
    double? groupY;
    void flush() {
      if (group.isEmpty) return;
      group.sort((a, b) => a.value.left.compareTo(b.value.left));
      rows.add(group.map((e) => e.key).join(' '));
      group = <MapEntry<String, Rect>>[];
      groupY = null;
    }

    for (final e in items) {
      final y = e.value.center.dy;
      final tol = e.value.height * 0.7 + 6;
      final gy = groupY;
      if (gy == null || (y - gy).abs() <= tol) {
        group.add(e);
        groupY = gy == null ? y : (gy + y) / 2;
      } else {
        flush();
        group.add(e);
        groupY = y;
      }
    }
    flush();
    return rows;
  }

  /// Finds [alias] in the lowercased [line], requiring that the
  /// alias is not just the start of a longer word (so 'mch' does
  /// not match inside 'mchc'). Returns the index or -1.
  static int _aliasIndex(String line, String alias) {
    var from = 0;
    while (true) {
      final idx = line.indexOf(alias, from);
      if (idx < 0) return -1;
      final end = idx + alias.length;
      if (end >= line.length ||
          !RegExp(r'[a-z]').hasMatch(line[end])) {
        return idx;
      }
      from = idx + 1;
    }
  }

  /// The parsing step, separated so its behaviour is easy to
  /// reason about: for each known test, find its line (or a window
  /// of joined text), take the standalone value after the name,
  /// and take the printed range when one is present.
  static List<LabTestResult> parseLines(List<String> lines) {
    final out = <LabTestResult>[];
    final lower = lines.map((l) => l.toLowerCase()).toList();
    final usedLines = <int>{};
    for (final def in _kLabTests) {
      LabTestResult? found;
      for (var i = 0; i < lines.length && found == null; i++) {
        if (usedLines.contains(i)) continue;
        var nameEnd = -1;
        for (final a in def.aliases) {
          final idx = _aliasIndex(lower[i], a);
          if (idx >= 0) {
            nameEnd = idx + a.length;
            break;
          }
        }
        if (nameEnd < 0) continue;
        found = _extract(def, lines[i].substring(nameEnd),
            i + 1 < lines.length ? lines[i + 1] : null);
        if (found != null) usedLines.add(i);
      }
      // Fallback: name and value may sit in different fragments
      // (e.g. columns read separately) - search the joined text
      // around the test name.
      if (found == null) {
        final joined = lower.join('\n');
        for (final a in def.aliases) {
          final idx = _aliasIndex(joined, a);
          if (idx < 0) continue;
          final end = idx + 90 > joined.length ? joined.length : idx + 90;
          final window = joined.substring(idx + a.length, end);
          found = _extract(def, window, null);
          if (found != null) break;
        }
      }
      if (found != null) out.add(found);
    }
    return out;
  }

  /// Extracts one test's value from the text that follows its
  /// name on a line ([rest]); [nextLine] is consulted when the
  /// value sits below the name in some report layouts.
  static LabTestResult? _extract(
      _LabTestDef def, String rest, String? nextLine) {
    // The printed range (if any) is identified so its two numbers
    // are not mistaken for the value.
    final rangeMatch = _rangeRe.firstMatch(rest);
    var rangeNums = <double>{};
    double? rLow, rHigh;
    if (rangeMatch != null) {
      rLow = _parseNum(rangeMatch.group(1)!);
      rHigh = _parseNum(rangeMatch.group(2)!);
      if (rLow != null) rangeNums.add(rLow);
      if (rHigh != null) rangeNums.add(rHigh);
    }
    double? value;
    for (final m in _numRe.allMatches(rest)) {
      final v = _parseNum(m.group(0)!);
      if (v == null || rangeNums.contains(v)) continue;
      value = v;
      break;
    }
    if (value == null && nextLine != null) {
      for (final m in _numRe.allMatches(nextLine)) {
        final v = _parseNum(m.group(0)!);
        if (v == null) continue;
        value = v;
        break;
      }
      if (value != null && rangeMatch == null) {
        final rm2 = _rangeRe.firstMatch(nextLine);
        if (rm2 != null) {
          rLow = _parseNum(rm2.group(1)!);
          rHigh = _parseNum(rm2.group(2)!);
          if (rLow != null && value == rLow) value = null;
        }
      }
    }
    if (value == null) return null;
    final v = def.scale != null ? def.scale!(value, rest) : value;
    if (v < def.saneMin || v > def.saneMax) return null;
    final usePrinted = rLow != null &&
        rHigh != null &&
        rLow < rHigh &&
        rLow >= 0 &&
        rHigh <= def.saneMax * 1.5;
    return LabTestResult(
      name: def.name,
      value: v,
      unit: def.unit,
      low: usePrinted ? rLow! : def.low,
      high: usePrinted ? rHigh! : def.high,
      rangeFromReport: usePrinted,
    );
  }
}
