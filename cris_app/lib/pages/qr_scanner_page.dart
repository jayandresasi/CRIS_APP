import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import '../theme.dart';

class QrScannerPage extends StatefulWidget {
  const QrScannerPage({super.key});

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage> {
  final _scannerController = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
  );
  bool _isRequestingPermission = true;
  bool _hasCameraPermission = false;
  bool _hasHandledScan = false;

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
  }

  Future<void> _requestCameraPermission() async {
    final granted = kIsWeb || (await Permission.camera.request()).isGranted;
    if (!mounted) return;
    setState(() {
      _isRequestingPermission = false;
      _hasCameraPermission = granted;
    });
  }

  void _handleDetection(BarcodeCapture capture) {
    if (_hasHandledScan || capture.barcodes.isEmpty) return;
    _hasHandledScan = true;
    Navigator.of(context).pop(true);
  }

  @override
  void dispose() {
    unawaited(_scannerController.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        title: const Text(
          'Scan QR Code',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isRequestingPermission
          ? const Center(child: CircularProgressIndicator())
          : !_hasCameraPermission
              ? _CameraMessage(
                  message: 'Camera permission is needed to scan a QR code.',
                  onBack: () => Navigator.of(context).pop(false),
                )
              : MobileScanner(
                  controller: _scannerController,
                  onDetect: _handleDetection,
                  errorBuilder: (context, error) => _CameraMessage(
                    message: 'Camera unavailable. Please check your camera and try again.',
                    onBack: () => Navigator.of(context).pop(false),
                  ),
                ),
    );
  }
}

class _CameraMessage extends StatelessWidget {
  const _CameraMessage({required this.message, required this.onBack});

  final String message;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.camera_alt_outlined,
                color: AppColors.primary, size: 48),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onBack, child: const Text('Go back')),
          ],
        ),
      ),
    );
  }
}
