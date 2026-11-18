import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import '../theme.dart';

class ScannedFacility {
  const ScannedFacility({
    required this.id,
    required this.code,
    required this.name,
  });

  final String id;
  final String code;
  final String name;
}

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

  Future<void> _handleDetection(BarcodeCapture capture) async {
    if (_hasHandledScan || capture.barcodes.isEmpty) return;
    _hasHandledScan = true;
    final rawQrValue = capture.barcodes.first.rawValue?.trim();
    if (rawQrValue == null || rawQrValue.isEmpty) {
      _showInvalidCodeMessage();
      return;
    }

    String facilityId = rawQrValue;
    String? scannedFacilityCode;
    String? scannedFacilityName;
    try {
      final decoded = jsonDecode(rawQrValue);
      if (decoded is Map) {
        facilityId = decoded['facilityId']?.toString().trim() ?? '';
        scannedFacilityCode = decoded['facilityCode']?.toString().trim();
        scannedFacilityName = decoded['facilityName']?.toString().trim();
      }
    } on FormatException {
      // Existing QR codes containing only a facility ID remain supported.
    }
    if (facilityId.isEmpty) {
      _showInvalidCodeMessage();
      return;
    }

    try {
      final collection = FirebaseFirestore.instance.collection('facilities');
      DocumentSnapshot<Map<String, dynamic>>? matchedDoc;

      final directDoc = await collection.doc(facilityId).get();
      if (directDoc.exists) {
        matchedDoc = directDoc;
      } else {
        for (final field in ['facilityId', 'applicantUid', 'ownerUid', 'adminUid']) {
          final querySnap =
              await collection.where(field, isEqualTo: facilityId).limit(1).get();
          if (querySnap.docs.isNotEmpty) {
            matchedDoc = querySnap.docs.first;
            break;
          }
        }
      }

      if (matchedDoc == null || !matchedDoc.exists) {
        _showInvalidCodeMessage('This QR code does not match a registered facility.');
        return;
      }

      final data = matchedDoc.data();
      final matchedFacilityId =
          data?['facilityId']?.toString().trim() ?? matchedDoc.id;
      final facilityCode =
          (data?['facilityCode'] ?? data?['acronym'])?.toString().trim();
      final facilityName = data?['facilityName']?.toString().trim();
      if (facilityCode == null || facilityCode.isEmpty ||
          facilityName == null || facilityName.isEmpty) {
        _showInvalidCodeMessage(
          'Facility record is missing required credentials.',
        );
        return;
      }

      if ((scannedFacilityCode?.isNotEmpty == true &&
              scannedFacilityCode != facilityCode) ||
          (scannedFacilityName?.isNotEmpty == true &&
              scannedFacilityName != facilityName)) {
        _showInvalidCodeMessage('QR code credentials do not match this facility.');
        return;
      }
      if (!mounted) return;
      Navigator.of(context).pop(
        ScannedFacility(
          id: matchedFacilityId,
          code: facilityCode,
          name: facilityName,
        ),
      );
    } catch (_) {
      _showInvalidCodeMessage();
    }
  }

  void _showInvalidCodeMessage([
    String message = 'This QR code does not match a registered facility.',
  ]) {
    if (!mounted) return;
    setState(() => _hasHandledScan = false);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
      ));
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
          onPressed: () => Navigator.of(context).pop(),
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
                  onBack: () => Navigator.of(context).pop(),
                )
              : MobileScanner(
                  controller: _scannerController,
                  onDetect: _handleDetection,
                  errorBuilder: (context, error) => _CameraMessage(
                    message: 'Camera unavailable. Please check your camera and try again.',
                    onBack: () => Navigator.of(context).pop(),
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
