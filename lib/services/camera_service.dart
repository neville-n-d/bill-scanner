import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class CameraService {
  static CameraController? _controller;
  static List<CameraDescription>? _cameras;
  static final ImagePicker _picker = ImagePicker();

  // Initialize camera
  static Future<void> initialize() async {
    // Check camera permission first
    final status = await Permission.camera.status;
    if (status != PermissionStatus.granted) {
      throw Exception('Camera permission not granted. Please grant camera permission to use this feature.');
    }

    // Get available cameras
    _cameras = await availableCameras();
    if (_cameras == null || _cameras!.isEmpty) {
      throw Exception('No cameras available on this device');
    }

    // Initialize camera controller with back camera
    _controller = CameraController(
      _cameras![0],
      ResolutionPreset.high,
      enableAudio: false,
    );

    await _controller!.initialize();
  }

  // Get camera controller
  static CameraController? get controller => _controller;

  // Get available cameras
  static List<CameraDescription>? get cameras => _cameras;

  // Take a photo using camera
  static Future<File?> takePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      await initialize();
    }

    try {
      final XFile image = await _controller!.takePicture();
      return File(image.path);
    } catch (e) {
      throw Exception('Failed to take photo: $e');
    }
  }

  // Pick image from gallery
  static Future<File?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to pick image from gallery: $e');
    }
  }

  // Pick image from camera
  static Future<File?> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to pick image from camera: $e');
    }
  }

  // Pick multiple images from gallery
  static Future<List<File>> pickMultipleImagesFromGallery() async {
    try {
      final List<XFile>? images = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (images != null && images.isNotEmpty) {
        return images.map((x) => File(x.path)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to pick images from gallery: $e');
    }
  }

  // Save image to app directory
  static Future<String> saveImageToAppDirectory(File imageFile) async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String fileName = 'bill_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String filePath = path.join(appDir.path, 'bills', fileName);

      // Create bills directory if it doesn't exist
      final Directory billsDir = Directory(path.dirname(filePath));
      if (!await billsDir.exists()) {
        await billsDir.create(recursive: true);
      }

      // Copy image to app directory
      await imageFile.copy(filePath);
      return filePath;
    } catch (e) {
      throw Exception('Failed to save image: $e');
    }
  }

  // Check if camera is available
  static Future<bool> isCameraAvailable() async {
    try {
      final cameras = await availableCameras();
      return cameras.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Check if camera permission is permanently denied
  static Future<bool> isPermissionPermanentlyDenied() async {
    final status = await Permission.camera.status;
    return status == PermissionStatus.permanentlyDenied;
  }

  // Open app settings for permission
  static Future<void> openAppSettingsForPermission() async {
    await openAppSettings();
  }

  // Check camera permission
  static Future<bool> hasCameraPermission() async {
    final status = await Permission.camera.status;
    return status == PermissionStatus.granted;
  }

  // Request camera permission
  static Future<bool> requestCameraPermission() async {
    // First check current status
    final currentStatus = await Permission.camera.status;
    
    // If already granted, return true
    if (currentStatus == PermissionStatus.granted) {
      return true;
    }
    
    // If permanently denied, return false
    if (currentStatus == PermissionStatus.permanentlyDenied) {
      return false;
    }
    
    // Request permission - this will show the iOS permission dialog
    final status = await Permission.camera.request();
    return status == PermissionStatus.granted;
  }

  // Dispose camera controller
  static Future<void> dispose() async {
    if (_controller != null) {
      await _controller!.dispose();
      _controller = null;
    }
  }

  // Switch camera
  static Future<void> switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) {
      throw Exception('No other camera available');
    }

    final currentCameraIndex = _cameras!.indexOf(_controller!.description);
    final nextCameraIndex = (currentCameraIndex + 1) % _cameras!.length;

    await _controller!.dispose();
    _controller = CameraController(
      _cameras![nextCameraIndex],
      ResolutionPreset.high,
      enableAudio: false,
    );

    await _controller!.initialize();
  }

  // Toggle flash
  static Future<void> toggleFlash() async {
    if (_controller == null) return;

    try {
      if (_controller!.value.flashMode == FlashMode.off) {
        await _controller!.setFlashMode(FlashMode.torch);
      } else {
        await _controller!.setFlashMode(FlashMode.off);
      }
    } catch (e) {
      // Flash might not be available on all devices
      print('Flash toggle failed: $e');
    }
  }

  // Get camera preview widget
  static Widget? getCameraPreview() {
    if (_controller == null || !_controller!.value.isInitialized) {
      return null;
    }
    return CameraPreview(_controller!);
  }
} 