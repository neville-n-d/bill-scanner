import 'package:flutter_test/flutter_test.dart';
import 'package:electricity_bill_app/services/camera_service.dart';

void main() {
  group('CameraService Permission Tests', () {
    test('hasCameraPermission should return boolean', () async {
      final hasPermission = await CameraService.hasCameraPermission();
      expect(hasPermission, isA<bool>());
    });

    test('requestCameraPermission should return boolean', () async {
      final granted = await CameraService.requestCameraPermission();
      expect(granted, isA<bool>());
    });

    test('isPermissionPermanentlyDenied should return boolean', () async {
      final isPermanentlyDenied = await CameraService.isPermissionPermanentlyDenied();
      expect(isPermanentlyDenied, isA<bool>());
    });

    test('isCameraAvailable should return boolean', () async {
      final isAvailable = await CameraService.isCameraAvailable();
      expect(isAvailable, isA<bool>());
    });
  });
} 