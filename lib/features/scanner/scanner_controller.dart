import 'dart:io';
import 'package:flutter/material.dart';
import '../../services/camera_service.dart';
import '../../services/ocr_service.dart';
import '../../services/math_service.dart';
import '../../models/math_question.dart';

enum ScannerState {
  initializing,
  ready,
  scanning,
  processing,
  detected,
  error,
}

class ScannerController extends ChangeNotifier {
  final CameraService _cameraService = CameraService();
  final OcrService _ocrService = OcrService();
  final MathService _mathService = MathService();

  ScannerState _state = ScannerState.initializing;
  String _errorMessage = '';
  String _detectedText = '';
  MathQuestion? _currentQuestion;
  File? _capturedImage;

  // Getters
  ScannerState get state => _state;
  String get errorMessage => _errorMessage;
  String get detectedText => _detectedText;
  MathQuestion? get currentQuestion => _currentQuestion;
  File? get capturedImage => _capturedImage;
  CameraService get cameraService => _cameraService;
  bool get isCameraReady => _cameraService.isInitialized;

  /// Initialize the camera.
  Future<void> initializeCamera() async {
    _state = ScannerState.initializing;
    notifyListeners();

    try {
      await _cameraService.initialize();
      _state = ScannerState.ready;
    } catch (e) {
      _state = ScannerState.error;
      _errorMessage = 'Gagal mengakses kamera: $e';
    }
    notifyListeners();
  }

  /// Capture image from camera and process it.
  Future<void> scanFromCamera() async {
    if (!_cameraService.isInitialized) return;

    _state = ScannerState.scanning;
    notifyListeners();

    try {
      final image = await _cameraService.captureImage();
      if (image != null) {
        _capturedImage = image;
        await _processImage(image);
      } else {
        _state = ScannerState.ready;
        _errorMessage = 'Gagal mengambil foto';
      }
    } catch (e) {
      _state = ScannerState.error;
      _errorMessage = 'Error saat scan: $e';
    }
    notifyListeners();
  }

  /// Pick image from gallery and process it.
  Future<void> scanFromGallery() async {
    _state = ScannerState.scanning;
    notifyListeners();

    try {
      final image = await _cameraService.pickFromGallery();
      if (image != null) {
        _capturedImage = image;
        await _processImage(image);
      } else {
        _state = ScannerState.ready;
      }
    } catch (e) {
      _state = ScannerState.error;
      _errorMessage = 'Error saat membaca gambar: $e';
    }
    notifyListeners();
  }

  /// Crop a captured image to select specific math area.
  Future<void> cropAndProcess() async {
    if (_capturedImage == null) return;

    _state = ScannerState.processing;
    notifyListeners();

    try {
      final croppedImage = await _cameraService.cropImage(_capturedImage!);
      if (croppedImage != null) {
        _capturedImage = croppedImage;
        await _processImage(croppedImage);
      } else {
        _state = ScannerState.detected;
      }
    } catch (e) {
      _state = ScannerState.error;
      _errorMessage = 'Error saat crop: $e';
    }
    notifyListeners();
  }

  /// Process the captured/picked image through OCR.
  Future<void> _processImage(File image) async {
    _state = ScannerState.processing;
    notifyListeners();

    try {
      final recognizedText = await _ocrService.recognizeMathExpression(image);

      if (recognizedText.isEmpty) {
        _state = ScannerState.error;
        _errorMessage = 'Tidak dapat membaca soal. Coba arahkan kamera lebih dekat.';
        notifyListeners();
        return;
      }

      _detectedText = recognizedText;
      _currentQuestion = _mathService.parseQuestion(recognizedText);
      _state = ScannerState.detected;
    } catch (e) {
      _state = ScannerState.error;
      _errorMessage = 'Gagal memproses gambar: $e';
    }
    notifyListeners();
  }

  /// Update the detected text (for manual edit by user).
  void updateDetectedText(String newText) {
    _detectedText = newText;
    _currentQuestion = _mathService.parseQuestion(newText);
    notifyListeners();
  }

  /// Reset the scanner to ready state.
  void reset() {
    _state = ScannerState.ready;
    _detectedText = '';
    _currentQuestion = null;
    _capturedImage = null;
    _errorMessage = '';
    notifyListeners();
  }

  @override
  void dispose() {
    _cameraService.dispose();
    _ocrService.dispose();
    _mathService.dispose();
    super.dispose();
  }
}
