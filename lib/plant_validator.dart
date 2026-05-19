import 'dart:math' as math;
import 'package:image/image.dart' as img;

// ignore_for_file: avoid_print

enum ValidationFailure { notAPlant, tooBlurry, tooDark, tooExposed }

class PlantValidationResult {
  final bool isPlant;
  final double plantScore;      // fraction of pixels with organic (plant) colour
  final double blurScore;       // 0–1, higher = sharper
  final double brightnessScore; // mean pixel brightness normalised to 0–1
  final ValidationFailure? failure;
  final String guidanceMessage; // always human-friendly

  const PlantValidationResult({
    required this.isPlant,
    required this.plantScore,
    required this.blurScore,
    required this.brightnessScore,
    this.failure,
    required this.guidanceMessage,
  });
}

/// Three-stage pre-filter that runs BEFORE any TFLite model to ensure the
/// image actually contains plant/leaf material.
///
/// Stage 1 — Brightness: reject images that are too dark or overexposed.
/// Stage 2 — Sharpness: reject severely blurry images (advisory only when
///            organic score is already strong).
/// Stage 3 — Organic colour: count pixels whose hue/saturation fall in the
///            palette of living or diseased plant tissue and reject images
///            below a minimum coverage threshold.
///
/// All thresholds are intentionally generous to avoid rejecting real-world
/// field photos (JPEG compression, mixed lighting, partial leaf framing, etc.)
class PlantValidator {
  // ── Tunable thresholds ─────────────────────────────────────────────────────

  // Minimum fraction of "organic" pixels to pass as a plant image.
  // Kept low so that partially-framed leaves or heavily diseased tissue pass.
  static const double _plantThreshold = 0.07;

  // Laplacian sharpness score below which the image is considered blurry.
  // Computed on a 128×128 thumbnail — average-downscaling from a phone camera
  // already smooths the image significantly, so this must be very low.
  static const double _blurThreshold = 0.005;

  // If organic score exceeds this, skip the blur check entirely — the colour
  // evidence is strong enough that mild motion blur does not matter.
  static const double _blurBypassScore = 0.15;

  // Pixel brightness limits (0–255).  Wide range to tolerate bright outdoor
  // sun and shaded field conditions.
  static const double _minBrightness = 15.0;
  static const double _maxBrightness = 250.0;

  // Thumbnail dimensions for fast analysis.
  static const int _thumbSize = 128;

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Validate [source].  Never throws — any internal error returns a safe
  /// non-plant result with a helpful guidance message.
  static PlantValidationResult validate(img.Image source) {
    try {
      return _validate(source);
    } catch (e) {
      print('[Validator] Internal error: $e');
      return const PlantValidationResult(
        isPlant: false,
        plantScore: 0,
        blurScore: 0,
        brightnessScore: 0,
        failure: ValidationFailure.notAPlant,
        guidanceMessage:
            'The image could not be analysed. Please try a different photo.',
      );
    }
  }

  // ── Internal pipeline ──────────────────────────────────────────────────────

  static PlantValidationResult _validate(img.Image source) {
    final thumb = img.copyResize(
      source,
      width: _thumbSize,
      height: _thumbSize,
      interpolation: img.Interpolation.average,
    );

    // ── Stage 1: Brightness ────────────────────────────────────────────────────
    final brightness = _meanBrightness(thumb);
    print('[Validator] brightness=${brightness.toStringAsFixed(1)}');

    if (brightness < _minBrightness) {
      return PlantValidationResult(
        isPlant: false,
        plantScore: 0,
        blurScore: 0.5,
        brightnessScore: brightness / 255.0,
        failure: ValidationFailure.tooDark,
        guidanceMessage:
            'The image is too dark to analyse. Move to a brighter area '
            'or use a light source and try again.',
      );
    }
    if (brightness > _maxBrightness) {
      return PlantValidationResult(
        isPlant: false,
        plantScore: 0,
        blurScore: 0.5,
        brightnessScore: brightness / 255.0,
        failure: ValidationFailure.tooExposed,
        guidanceMessage:
            'The image is overexposed. Step away from direct sunlight '
            'or reduce lighting and try again.',
      );
    }

    // ── Stage 2: Organic colour (run before blur so we can bypass blur) ────────
    final plantScore = _organicColorScore(thumb);
    print('[Validator] organicScore=${plantScore.toStringAsFixed(3)}');

    // ── Stage 3: Sharpness (advisory — skipped when colour evidence is strong) ─
    final blurScore = _laplacianScore(thumb);
    print('[Validator] blurScore=${blurScore.toStringAsFixed(4)} '
        '(threshold=$_blurThreshold, bypass if organicScore>=$_blurBypassScore)');

    final blurTooLow = blurScore < _blurThreshold;
    final colourBypassesBlur = plantScore >= _blurBypassScore;

    if (blurTooLow && !colourBypassesBlur) {
      return PlantValidationResult(
        isPlant: false,
        plantScore: plantScore,
        blurScore: blurScore,
        brightnessScore: brightness / 255.0,
        failure: ValidationFailure.tooBlurry,
        guidanceMessage:
            'The image appears blurry. Hold the camera steady and tap the '
            'leaf to focus, then try again.',
      );
    }

    // ── Stage 4: Plant presence decision ──────────────────────────────────────
    final isPlant = plantScore >= _plantThreshold;
    print('[Validator] isPlant=$isPlant '
        '(score=${plantScore.toStringAsFixed(3)} threshold=$_plantThreshold)');

    return PlantValidationResult(
      isPlant: isPlant,
      plantScore: plantScore,
      blurScore: blurScore,
      brightnessScore: brightness / 255.0,
      failure: isPlant ? null : ValidationFailure.notAPlant,
      guidanceMessage: isPlant ? '' : _guidanceFor(plantScore),
    );
  }

  // ── Metric helpers ─────────────────────────────────────────────────────────

  static double _meanBrightness(img.Image im) {
    double total = 0;
    final n = im.width * im.height;
    for (final p in im) {
      total += (p.r.toDouble() + p.g.toDouble() + p.b.toDouble()) / 3.0;
    }
    return n > 0 ? total / n : 128.0;
  }

  /// Approximated 5-tap Laplacian mean as a sharpness proxy.
  ///
  /// NOTE: This score is intentionally low on downscaled thumbnails because
  /// average-interpolation removes high-frequency content.  Use _blurThreshold
  /// of 0.005 or lower — do NOT compare against values calibrated on full-res
  /// images.
  static double _laplacianScore(img.Image im) {
    double sum = 0;
    int n = 0;
    final w = im.width;
    final h = im.height;
    for (int y = 1; y < h - 1; y++) {
      for (int x = 1; x < w - 1; x++) {
        final c = _luma(im.getPixel(x, y));
        final lap = (4.0 * c
                - _luma(im.getPixel(x - 1, y))
                - _luma(im.getPixel(x + 1, y))
                - _luma(im.getPixel(x, y - 1))
                - _luma(im.getPixel(x, y + 1)))
            .abs();
        sum += lap;
        n++;
      }
    }
    return n > 0 ? (sum / n / 255.0).clamp(0.0, 1.0) : 0.0;
  }

  static double _luma(img.Pixel p) =>
      0.299 * p.r.toDouble() + 0.587 * p.g.toDouble() + 0.114 * p.b.toDouble();

  // ── Organic-colour detection ───────────────────────────────────────────────
  //
  // Recognised hue bands (degrees):
  //   50°–170°   green — broad band covering healthy leaves, moss, stems
  //   35°–50°    yellow-green — early chlorosis, stressed tissue
  //   18°–35°    yellow-brown — necrotic lesions, late-stage disease
  //    0°–18°    red-brown — blight, fire damage, severe necrosis
  //  340°–360°   dark red / wine red — same as above, negative-hue wrap-around
  //
  // Near-black (brightness < 12) and near-white (> 248) pixels are excluded
  // to avoid counting deep shadows and bright glare patches as background.
  //
  // Saturation minimum of 0.05 filters out neutral greys (keyboards, walls,
  // concrete, metal) while accepting mildly desaturated plant photos.

  static double _organicColorScore(img.Image im) {
    int organic = 0;
    int skipped = 0;
    final total = im.width * im.height;

    for (final p in im) {
      final r = p.r.toDouble();
      final g = p.g.toDouble();
      final b = p.b.toDouble();
      final brightness = (r + g + b) / 3.0;

      // Exclude near-black and near-white pixels.
      if (brightness < 12 || brightness > 248) {
        skipped++;
        continue;
      }

      final maxC = math.max(math.max(r, g), b);
      final minC = math.min(math.min(r, g), b);
      final delta = maxC - minC;
      final saturation = maxC > 1.0 ? delta / maxC : 0.0;

      // Neutral grey / achromatic pixels — keyboards, walls, fabric.
      if (saturation < 0.05) continue;

      // Compute hue in [0, 360).
      double hue;
      if (delta < 1.0) {
        hue = 0;
      } else if (maxC == r) {
        hue = 60.0 * (((g - b) / delta) % 6.0);
      } else if (maxC == g) {
        hue = 60.0 * ((b - r) / delta + 2.0);
      } else {
        hue = 60.0 * ((r - g) / delta + 4.0);
      }
      if (hue < 0) hue += 360.0;

      // Green — healthy photosynthetic tissue (wide band, low sat threshold).
      if (hue >= 50.0 && hue <= 170.0 && saturation > 0.08) {
        organic++;
        continue;
      }
      // Yellow-green — early chlorosis, stressed tissue.
      if (hue >= 35.0 && hue < 50.0 && saturation > 0.12) {
        organic++;
        continue;
      }
      // Yellow-brown — necrotic lesions, intermediate disease stage.
      if (hue >= 18.0 && hue < 35.0 && saturation > 0.18 && brightness < 215) {
        organic++;
        continue;
      }
      // Red-brown — blight, severe necrosis. Higher saturation gate to avoid
      // counting dark manufactured reds (tool handles, plastic, ceramics).
      if ((hue < 18.0 || hue > 340.0) && saturation > 0.25 && brightness < 190) {
        organic++;
      }
    }

    final effective = total - skipped;
    final score = effective > 0 ? (organic / effective).clamp(0.0, 1.0) : 0.0;
    return score;
  }

  static String _guidanceFor(double score) {
    if (score < 0.03) {
      return 'No plant material was detected in this image. '
          'Please photograph a plant leaf or the affected area of a crop.';
    }
    if (score < 0.05) {
      return 'Very little plant material is visible. '
          'Move the camera closer so the leaf fills most of the frame.';
    }
    return 'The plant is not clearly visible in the image. '
        'Centre the affected leaf in the frame and photograph it up close '
        'for an accurate diagnosis.';
  }
}
