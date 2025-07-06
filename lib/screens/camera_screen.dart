import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bill_provider.dart';
import '../services/camera_service.dart';
import '../screens/bill_processing_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  bool _isInitialized = false;
  bool _isProcessing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      await CameraService.initialize();
      setState(() {
        _isInitialized = true;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to initialize camera: $e';
      });
    }
  }

  Future<void> _takePhoto() async {
    if (!_isInitialized) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final File? photo = await CameraService.takePhoto();
      if (photo != null) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => BillProcessingScreen(imageFile: photo),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to take photo: $e';
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _pickFromGallery() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final File? image = await CameraService.pickImageFromGallery();
      if (image != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => BillProcessingScreen(imageFile: image),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to pick image: $e';
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Electricity Bill'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return _buildErrorView();
    }

    if (!_isInitialized) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Initializing camera...'),
          ],
        ),
      );
    }

    return Stack(
      children: [
        _buildCameraPreview(),
        _buildCameraControls(),
        if (_isProcessing) _buildProcessingOverlay(),
      ],
    );
  }

  Widget _buildCameraPreview() {
    final preview = CameraService.getCameraPreview();
    if (preview == null) {
      return const Center(
        child: Text('Camera preview not available'),
      );
    }

    return Container(
      width: double.infinity,
      height: double.infinity,
      child: preview,
    );
  }

  Widget _buildCameraControls() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.7),
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildInstructions(),
            const SizedBox(height: 24),
            _buildControlButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'Position your electricity bill within the frame',
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildControlButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Gallery button
        FloatingActionButton(
          onPressed: _isProcessing ? null : _pickFromGallery,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          child: const Icon(Icons.photo_library),
        ),
        
        // Capture button
        FloatingActionButton.large(
          onPressed: _isProcessing ? null : _takePhoto,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          child: const Icon(Icons.camera_alt, size: 32),
        ),
        
        // Flash toggle button
        FloatingActionButton(
          onPressed: _isProcessing ? null : () async {
            await CameraService.toggleFlash();
          },
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          child: const Icon(Icons.flash_on),
        ),
      ],
    );
  }

  Widget _buildProcessingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Processing...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Camera Error',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'An unknown error occurred',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _initializeCamera,
              child: const Text('Retry'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _pickFromGallery,
              child: const Text('Pick from Gallery Instead'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    CameraService.dispose();
    super.dispose();
  }
} 