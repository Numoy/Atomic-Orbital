import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';

class AssetManager {
  static final AssetManager _instance = AssetManager._();
  static AssetManager get instance => _instance;

  AssetManager._();

  ui.Image? atomImage;
  ui.Image? photonImage;
  ui.Image? backgroundImage;

  bool get isLoaded =>
      atomImage != null && photonImage != null && backgroundImage != null;

  Future<void> loadAssets() async {
    if (isLoaded) return;

    atomImage = await _loadImage('assets/images/std_atom.png');
    photonImage = await _loadImage('assets/images/std_photon.png');
    backgroundImage = await _loadImage('assets/images/stars.png');
  }

  Future<ui.Image> _loadImage(String assetPath) async {
    final data = await rootBundle.load(assetPath);
    final list = Uint8List.view(data.buffer);
    final codec = await ui.instantiateImageCodec(list);
    final frame = await codec.getNextFrame();
    return frame.image;
  }
}
