// lib/providers/scale_notifier.dart
import 'package:flutter/material.dart';

/// A [ChangeNotifier] that manages a scaling factor for UI elements.
/// It provides methods to zoom in, zoom out, and reset the zoom level.
class ScaleNotifier extends ChangeNotifier {
  double _scale = 1.0;
  static const double _minScale = 0.5;
  static const double _maxScale = 2.0; // Adjust max scale as needed
  static const double _scaleIncrement = 0.1;

  /// The current scale factor.
  double get scale => _scale;

  /// Updates the scale factor to a [newScale] value, clamped between
  /// [_minScale] and [_maxScale].
  void updateScale(double newScale) {
    _scale = newScale.clamp(_minScale, _maxScale);
    notifyListeners();
  }

  /// Increases the scale factor by [_scaleIncrement], up to [_maxScale].
  void zoomIn() {
    if (_scale < _maxScale) {
      _scale = (_scale + _scaleIncrement).clamp(_minScale, _maxScale);
      notifyListeners();
    }
  }

  /// Decreases the scale factor by [_scaleIncrement], down to [_minScale].
  void zoomOut() {
    if (_scale > _minScale) {
      _scale = (_scale - _scaleIncrement).clamp(_minScale, _maxScale);
      notifyListeners();
    }
  }

  /// Resets the scale factor to 1.0.
  void resetZoom() {
    _scale = 1.0;
    notifyListeners();
  }
}

// Intents for keyboard shortcuts or other actions that might trigger zoom changes.
class ZoomInIntent extends Intent {}

class ZoomOutIntent extends Intent {}

class ResetZoomIntent extends Intent {}
