import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:helloworld/wallpaper_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');

  test(
    'cancelled photo selection leaves wallpaper preferences untouched',
    () async {
      SharedPreferences.setMockInitialValues({});
      final picker = _FakeImagePicker(null);
      final helper = WallpaperHelper(imagePicker: picker);

      expect(await helper.pickAndSaveWallpaper(), isNull);
      expect(picker.source, ImageSource.gallery);
      expect(picker.imageQuality, 85);

      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getString(WallpaperHelper.wallpaperPathKey), isNull);
    },
  );

  test(
    'wallpaper copy overwrites the previous file and reset removes it',
    () async {
      SharedPreferences.setMockInitialValues({});
      final directory = await Directory.systemTemp.createTemp(
        'wallpaper-test-',
      );
      addTearDown(() async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(pathProviderChannel, null);
        await directory.delete(recursive: true);
      });
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(pathProviderChannel, (call) async {
            return directory.path;
          });

      final source = File('${directory.path}/picked-photo.jpg');
      await source.writeAsString('first image');
      final picker = _FakeImagePicker(XFile(source.path));
      final helper = WallpaperHelper(imagePicker: picker);

      final savedPath = await helper.pickAndSaveWallpaper();
      expect(savedPath, '${directory.path}/custom_list_wallpaper.jpg');
      expect(await File(savedPath!).readAsString(), 'first image');

      await source.writeAsString('replacement image');
      expect(await helper.pickAndSaveWallpaper(), savedPath);
      expect(await File(savedPath).readAsString(), 'replacement image');

      final preferences = await SharedPreferences.getInstance();
      expect(
        preferences.getString(WallpaperHelper.wallpaperPathKey),
        savedPath,
      );
      expect(await helper.loadOverlayOpacity(), 0.25);

      await helper.saveOverlayOpacity(0.9);
      expect(await helper.loadOverlayOpacity(), 0.7);

      await helper.resetWallpaper();
      expect(await File(savedPath).exists(), isFalse);
      expect(preferences.getString(WallpaperHelper.wallpaperPathKey), isNull);
    },
  );
}

class _FakeImagePicker extends ImagePicker {
  _FakeImagePicker(this.image);

  final XFile? image;
  ImageSource? source;
  int? imageQuality;

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    this.source = source;
    this.imageQuality = imageQuality;
    return image;
  }
}
