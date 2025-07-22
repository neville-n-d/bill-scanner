import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bill_provider.dart';
import '../services/camera_service.dart';
import '../screens/bill_processing_screen.dart';
import 'package:flutter_document_picker/flutter_document_picker.dart';
import 'package:pdf_render/pdf_render.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import '../screens/bill_detail_screen.dart';
import 'package:image/image.dart' as img;
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import '../services/ai_service.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  bool _isInitialized = false;
  bool _isProcessing = false;
  bool _isCheckingPermission = false;
  String? _error;

  // Store multiple images
  final List<File> _selectedImages = [];

  @override
  void initState() {
    super.initState();
    _checkAndRequestPermission();
  }

  Future<void> _checkAndRequestPermission() async {
    setState(() {
      _isCheckingPermission = true;
      _error = null;
    });

    print('DEBUG: Checking camera permission...');
    try {
      // Check if camera permission is already granted
      final hasPermission = await CameraService.hasCameraPermission();
      print('DEBUG: Camera permission granted? $hasPermission');
      if (hasPermission) {
        // Permission already granted, initialize camera
        await _initializeCamera();
      } else {
        // Permission not granted, show permission request UI
        setState(() {
          _isCheckingPermission = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to check camera permission: $e';
        _isCheckingPermission = false;
      });
    }
  }

  Future<void> _requestPermission() async {
    setState(() {
      _isCheckingPermission = true;
      _error = null;
    });

    try {
      final granted = await CameraService.requestCameraPermission();

      if (granted) {
        await _initializeCamera();
      } else {
        // Check if permission is permanently denied
        final isPermanentlyDenied =
            await CameraService.isPermissionPermanentlyDenied();

        setState(() {
          if (isPermanentlyDenied) {
            _error =
                'Camera permission is permanently denied. Please enable camera access in your device settings to scan bills.';
          } else {
            _error =
                'Camera permission is required to scan bills. Please grant camera permission to continue.';
          }
          _isCheckingPermission = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to request camera permission: $e';
        _isCheckingPermission = false;
      });
    }
  }

  Future<void> _initializeCamera() async {
    try {
      print('DEBUG: Initializing camera...');
      await CameraService.initialize();
      setState(() {
        _isInitialized = true;
        _isCheckingPermission = false;
        _error = null;
      });
      print('DEBUG: Camera initialized successfully.');
    } catch (e) {
      setState(() {
        _error = 'Failed to initialize camera: $e';
        _isCheckingPermission = false;
      });
      print('DEBUG: Camera initialization failed: $e');
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
        setState(() {
          _selectedImages.add(photo);
        });
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
      final List<File> images =
          await CameraService.pickMultipleImagesFromGallery();
      if (images.isNotEmpty && mounted) {
        setState(() {
          _selectedImages.addAll(images);
          _isInitialized = true; // Show main UI after picking images
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to pick images: $e';
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _pickPdfAndConvertToImages() async {
    try {
      final pdfPath = await FlutterDocumentPicker.openDocument(
        params: FlutterDocumentPickerParams(
          allowedFileExtensions: ['pdf'],
          allowedUtiTypes: ['com.adobe.pdf'],
          invalidFileNameSymbols: ['/'],
        ),
      );
      if (pdfPath != null && await File(pdfPath).exists()) {
        final file = File(pdfPath);
        int size = await file.length();
        if (size == 0) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'File is not fully downloaded. Please open it in the Files app first.',
                ),
              ),
            );
          }
          return;
        }

        // Show loading screen
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );

        // Upload PDF and get images from backend
        List<String> base64Images = await AIService.uploadPdfAndGetImages(file);
        List<Uint8List> imageBytes = AIService.base64ImagesToUint8List(
          base64Images,
        );

        // Save images as temporary files
        final tempDir = await getTemporaryDirectory();
        List<File> imageFiles = [];
        for (int i = 0; i < imageBytes.length; i++) {
          final tempFile = File('${tempDir.path}/pdf_backend_page_$i.jpg');
          await tempFile.writeAsBytes(imageBytes[i]);
          imageFiles.add(tempFile);
        }

        // Dismiss loading
        if (mounted) Navigator.of(context, rootNavigator: true).pop();

        // Navigate to BillProcessingScreen with the image files
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  BillProcessingScreen(imageFiles: imageFiles),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Selected PDF file does not exist.')),
          );
        }
      }
    } catch (e, stack) {
      print('PDF processing error: $e\n$stack');
      if (mounted) {
        Navigator.of(
          context,
          rootNavigator: true,
        ).pop(); // Dismiss loading if error
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to process PDF: $e')));
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _analyzeImages() {
    if (_selectedImages.isNotEmpty) {
      print(
        'DEBUG: Navigating to BillProcessingScreen with ${_selectedImages.length} images',
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              BillProcessingScreen(imageFiles: _selectedImages),
        ),
      );
    } else {
      print('DEBUG: _analyzeImages called but _selectedImages is empty');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Scan Electricity Bill',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isFlashOn ? Icons.flash_on : Icons.flash_off,
              color: _isFlashOn ? Colors.orange : Colors.grey[700],
            ),
            onPressed: () async {
              await CameraService.toggleFlash();
              setState(() {
                _isFlashOn = !_isFlashOn;
              });
            },
            tooltip: 'Toggle Flash',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  // Add a state variable for flash status
  bool _isFlashOn = false;

  Widget _buildBody() {
    print(
      'DEBUG: _buildBody called. _error=$_error, _isCheckingPermission=$_isCheckingPermission, _isInitialized=$_isInitialized',
    );
    if (_error != null) {
      return _buildErrorView();
    }

    if (_isCheckingPermission) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Checking camera permission...'),
          ],
        ),
      );
    }

    if (!_isInitialized) {
      return _buildPermissionRequestView();
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
      return const Center(child: Text('Camera preview not available'));
    }

    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: double.infinity,
          child: preview,
        ),
        // White square overlay to guide bill positioning
        // Center(
        //   child: Container(
        //     width: MediaQuery.of(context).size.width * 0.97,
        //     height:
        //         MediaQuery.of(context).size.height *
        //         0.85, // Aspect ratio for bills
        //     decoration: BoxDecoration(
        //       border: Border.all(color: Colors.white, width: 3),
        //       borderRadius: BorderRadius.circular(12),
        //     ),
        //   ),
        // ),
        // Corner indicators
        Positioned(
          top: MediaQuery.of(context).size.height * 0.01,
          left: MediaQuery.of(context).size.width * 0.02,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.white, width: 4),
                left: BorderSide(color: Colors.white, width: 4),
              ),
            ),
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).size.height * 0.01,
          right: MediaQuery.of(context).size.width * 0.02,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.white, width: 4),
                right: BorderSide(color: Colors.white, width: 4),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: MediaQuery.of(context).size.height * 0.04,
          left: MediaQuery.of(context).size.width * 0.01,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.white, width: 4),
                left: BorderSide(color: Colors.white, width: 4),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: MediaQuery.of(context).size.height * 0.04,
          right: MediaQuery.of(context).size.width * 0.01,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.white, width: 4),
                right: BorderSide(color: Colors.white, width: 4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCameraControls() {
    print(
      'DEBUG: Building camera controls. _selectedImages.length =  [38;5;2m${_selectedImages.length} [0m, _isProcessing = $_isProcessing',
    );
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
        // Remove the dark gradient overlay for a normal look
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildImagePreviewList(),
            const SizedBox(height: 6),
            _buildActionButtons(),
            const SizedBox(height: 6),
            _buildControlButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreviewList() {
    if (_selectedImages.isEmpty) return const SizedBox.shrink();
    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _selectedImages.length,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(
                    _selectedImages[index],
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => _removeImage(index),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Page ${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.tips_and_updates, color: Colors.blue[600], size: 20),
          const SizedBox(width: 8),
          const Text(
            'Position your electricity bill within the frame',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Gallery button
          _buildControlButton(
            onPressed: _isProcessing ? null : _pickFromGallery,
            icon: Icons.photo_library,
            label: 'Gallery',
            color: Colors.blue,
          ),

          // Capture button
          _buildCaptureButton(),

          // PDF upload button (replaces flash)
          _buildControlButton(
            onPressed: _isProcessing ? null : _pickPdfAndConvertToImages,
            icon: Icons.picture_as_pdf,
            label: 'PDF',
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          onPressed: onPressed,
          backgroundColor: Colors.white,
          foregroundColor: color,
          elevation: 6,
          child: Icon(icon, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildCaptureButton() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton.large(
          onPressed: _isProcessing ? null : _takePhoto,
          backgroundColor: Colors.white,
          foregroundColor: Colors.blue[600],
          elevation: 8,
          child: Icon(Icons.camera_alt, size: 36),
        ),
        const SizedBox(height: 8),
        const Text(
          'Capture',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Analyze button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _selectedImages.isNotEmpty && !_isProcessing
                ? _analyzeImages
                : null,
            icon: const Icon(Icons.analytics, color: Colors.white, size: 24),
            label: const Text(
              'Analyze Bill Images',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              elevation: 8,
              shadowColor: Colors.blue.withOpacity(0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // PDF upload button
        // SizedBox(
        //   width: double.infinity,
        //   height: 56,
        //   child: ElevatedButton.icon(
        //     onPressed: _isProcessing ? null : _pickPdfAndConvertToImages,
        //     icon: const Icon(
        //       Icons.picture_as_pdf,
        //       color: Colors.white,
        //       size: 24,
        //     ),
        //     label: const Text(
        //       'Upload PDF',
        //       style: TextStyle(
        //         color: Colors.white,
        //         fontSize: 16,
        //         fontWeight: FontWeight.w600,
        //       ),
        //     ),
        //     style: ElevatedButton.styleFrom(
        //       backgroundColor: Colors.grey[700],
        //       foregroundColor: Colors.white,
        //       elevation: 4,
        //       shadowColor: Colors.black.withOpacity(0.3),
        //       shape: RoundedRectangleBorder(
        //         borderRadius: BorderRadius.circular(28),
        //       ),
        //       padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        //     ),
        //   ),
        // ),
      ],
    );
  }

  Widget _buildProcessingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  shape: BoxShape.circle,
                ),
                child: CircularProgressIndicator(
                  color: Colors.blue[600],
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Processing...',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please wait while we analyze your bill',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionRequestView() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue[50]!, Colors.white, Colors.blue[50]!],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.camera_alt,
                  size: 64,
                  color: Colors.blue[700],
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Camera Permission Required',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'This app needs camera access to scan your electricity bills. Please grant camera permission to continue.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              _buildPermissionButton(),
              const SizedBox(height: 16),
              _buildAlternativeButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _requestPermission,
        icon: const Icon(Icons.camera_alt, color: Colors.white, size: 24),
        label: const Text(
          'Grant Camera Permission',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[600],
          foregroundColor: Colors.white,
          elevation: 8,
          shadowColor: Colors.blue.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildAlternativeButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _pickFromGallery,
            icon: Icon(Icons.photo_library, color: Colors.grey[700], size: 20),
            label: Text(
              'Pick from Gallery Instead',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.grey[700],
              elevation: 2,
              shadowColor: Colors.black.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(color: Colors.grey[300]!),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _pickPdfAndConvertToImages,
            icon: Icon(Icons.picture_as_pdf, color: Colors.grey[700], size: 20),
            label: Text(
              'Upload PDF',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.grey[700],
              elevation: 2,
              shadowColor: Colors.black.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(color: Colors.grey[300]!),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorView() {
    final isPermissionError = _error?.contains('permission') == true;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.red[50]!, Colors.white, Colors.red[50]!],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isPermissionError
                      ? Colors.orange[100]
                      : Colors.red[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPermissionError ? Icons.camera_alt : Icons.error_outline,
                  size: 64,
                  color: isPermissionError
                      ? Colors.orange[700]
                      : Colors.red[700],
                ),
              ),
              const SizedBox(height: 32),
              Text(
                isPermissionError
                    ? 'Camera Permission Required'
                    : 'Camera Error',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  _error ?? 'An unknown error occurred',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.black54,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              if (isPermissionError) ...[
                _buildPermissionButton(),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.grey[300]!),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextButton.icon(
                    onPressed: () async {
                      await CameraService.openAppSettingsForPermission();
                    },
                    icon: Icon(Icons.settings, color: Colors.grey[700]),
                    label: Text(
                      'Open Settings',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ),
              ] else ...[
                Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.blue[600],
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _checkAndRequestPermission,
                    child: const Text(
                      'Retry',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey[300]!),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextButton.icon(
                  onPressed: _pickFromGallery,
                  icon: Icon(Icons.photo_library, color: Colors.grey[700]),
                  label: Text(
                    'Pick from Gallery Instead',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ),
            ],
          ),
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
