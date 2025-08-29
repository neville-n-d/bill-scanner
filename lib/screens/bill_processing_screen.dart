import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bill_provider.dart';
import '../screens/bill_detail_screen.dart';
import '../services/bill_validator.dart';

class BillProcessingScreen extends StatefulWidget {
  final List<File> imageFiles;

  const BillProcessingScreen({
    super.key,
    required this.imageFiles,
  });

  @override
  State<BillProcessingScreen> createState() => _BillProcessingScreenState();
}

class _BillProcessingScreenState extends State<BillProcessingScreen> {
  bool _isProcessing = false;
  String _currentStep = 'Initializing...';
  String? _error;
  final BillValidator _billValidator = BillValidator();

  @override
  void initState() {
    super.initState();
    print('DEBUG: BillProcessingScreen initState called with imageFiles.length = ${widget.imageFiles.length}');
    _processBill();
  }

  Future<void> _processBill() async {
    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      // Validate the first image before sending to OpenAI
      setState(() {
        _currentStep = 'Validating bill image...';
      });
      final imageBytes = await widget.imageFiles[0].readAsBytes();
      String validationResult = await _billValidator.validate(imageBytes);
      if (validationResult == 'non_bill') {
        if (mounted) {
          setState(() {
            _isProcessing = false;
            _currentStep = 'Validation failed';
          });
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Invalid Image'),
              content: const Text('The uploaded image is not recognized as an electricity bill. Please try again.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
        return;
      }

      final billProvider = context.read<BillProvider>();

      setState(() {
        _currentStep = 'Saving images...';
      });

      setState(() {
        _currentStep = 'Analyzing bill with AI...';
      });

      await billProvider.processBillFromImages(widget.imageFiles);

      if (mounted) {
        setState(() {
          _currentStep = 'Processing complete!';
        });

        // Navigate to bill detail screen after a short delay
        await Future.delayed(const Duration(seconds: 1));
        
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => BillDetailScreen(
                bill: billProvider.currentBill!,
              ),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to process bill: $e';
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Processing Bill'),
        automaticallyImplyLeading: false,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return _buildErrorView();
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildImagePreview(),
            const SizedBox(height: 32),
            _buildProcessingStatus(),
            const SizedBox(height: 32),
            _buildProgressIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.imageFiles.length,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                widget.imageFiles[index],
                fit: BoxFit.cover,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProcessingStatus() {
    return Column(
      children: [
        const Icon(
          Icons.analytics,
          size: 48,
          color: Colors.blue,
        ),
        const SizedBox(height: 16),
        Text(
          'Processing Your Bill',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _currentStep,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    return Column(
      children: [
        const SizedBox(
          width: 200,
          child: LinearProgressIndicator(),
        ),
        const SizedBox(height: 16),
        Text(
          'This may take a few moments...',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[500],
          ),
        ),
      ],
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
              'Processing Failed',
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
              onPressed: _processBill,
              child: const Text('Retry'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
} 