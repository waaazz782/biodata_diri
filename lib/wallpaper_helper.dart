import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WallpaperHelper {
  WallpaperHelper({ImagePicker? imagePicker})
    : _imagePicker = imagePicker ?? ImagePicker();

  static const wallpaperPathKey = 'student_list_wallpaper_path';
  static const overlayOpacityKey = 'wallpaper_overlay_opacity';
  static const defaultOverlayOpacity = 0.25;
  static const minOverlayOpacity = 0.0;
  static const maxOverlayOpacity = 0.7;

  final ImagePicker _imagePicker;

  Future<String?> pickAndSaveWallpaper() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (image == null) return null;

    final directory = await getApplicationDocumentsDirectory();
    final destination = File('${directory.path}/custom_list_wallpaper.jpg');
    await File(image.path).copy(destination.path);
    await FileImage(destination).evict();

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(wallpaperPathKey, destination.path);
    return destination.path;
  }

  Future<void> resetWallpaper() async {
    final directory = await getApplicationDocumentsDirectory();
    final wallpaperFile = File('${directory.path}/custom_list_wallpaper.jpg');
    if (await wallpaperFile.exists()) {
      await wallpaperFile.delete();
    }

    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(wallpaperPathKey);
  }

  Future<String?> loadWallpaperPath() async {
    final preferences = await SharedPreferences.getInstance();
    final path = preferences.getString(wallpaperPathKey);
    if (path == null || !await File(path).exists()) return null;
    return path;
  }

  Future<double> loadOverlayOpacity() async {
    final preferences = await SharedPreferences.getInstance();
    final opacity = preferences.getDouble(overlayOpacityKey);
    if (opacity == null) return defaultOverlayOpacity;
    return opacity.clamp(minOverlayOpacity, maxOverlayOpacity).toDouble();
  }

  Future<void> saveOverlayOpacity(double opacity) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setDouble(
      overlayOpacityKey,
      opacity.clamp(minOverlayOpacity, maxOverlayOpacity).toDouble(),
    );
  }
}
