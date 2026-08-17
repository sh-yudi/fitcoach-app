import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

/// Lets the user pick a profile photo from the camera or gallery, crop it to
/// a locked 1:1 square (the same shape as the one-tap login avatar) and return
/// it as a base64 string. Returns null if cancelled.
Future<String?> pickProfilePhoto(BuildContext context) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('Take a photo'),
            onTap: () => Navigator.of(context).pop(ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Choose from gallery'),
            onTap: () => Navigator.of(context).pop(ImageSource.gallery),
          ),
        ],
      ),
    ),
  );
  if (source == null) return null;

  final picker = ImagePicker();
  final file = await picker.pickImage(
    source: source,
    maxWidth: 1200,
    maxHeight: 1200,
  );
  if (file == null) return null;

  final cropper = ImageCropper();
  final cropped = await cropper.cropImage(
    sourcePath: file.path,
    maxWidth: 400,
    maxHeight: 400,
    aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
    compressFormat: ImageCompressFormat.jpg,
    compressQuality: 70,
    uiSettings: [
      AndroidUiSettings(
        toolbarTitle: 'Crop photo',
        toolbarColor: const Color(0xFF24321A),
        toolbarWidgetColor: Colors.white,
        activeControlsWidgetColor: const Color(0xFF4A6B1E),
        lockAspectRatio: true,
        initAspectRatio: CropAspectRatioPreset.square,
        aspectRatioPresets: const [
          CropAspectRatioPreset.square,
        ],
      ),
      IOSUiSettings(
        title: 'Crop photo',
        aspectRatioLockEnabled: true,
        resetAspectRatioEnabled: false,
        aspectRatioPickerButtonHidden: true,
        doneButtonTitle: 'Done',
      ),
    ],
  );
  if (cropped == null) return null;
  final bytes = await cropped.readAsBytes();
  return base64Encode(bytes);
}
