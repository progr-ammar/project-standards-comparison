import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

enum ErrorType {
  fileNotFound,
  fileCorrupted,
  scannedPdf,
  invalidFormat,
  permissionDenied,
  networkError,
  searchTimeout,
  processingError,
  memoryError,
  performanceError,
  unknownError,
}

enum ErrorSeverity { low, medium, high, critical }

class AppError {
  final ErrorType type;
  final ErrorSeverity severity;
  final String message;
  final String? details;
  final String? suggestion;
  final List<String> recoveryActions;
  final DateTime timestamp;
  final String? context;

  AppError({
    required this.type,
    required this.severity,
    required this.message,
    this.details,
    this.suggestion,
    this.recoveryActions = const [],
    DateTime? timestamp,
    this.context,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'severity': severity.name,
      'message': message,
      'details': details,
      'suggestion': suggestion,
      'recoveryActions': recoveryActions,
      'timestamp': timestamp.toIso8601String(),
      'context': context,
    };
  }

  @override
  String toString() {
    return 'AppError(${type.name}): $message';
  }
}

class ErrorHandlingService {
  static final ErrorHandlingService _instance =
      ErrorHandlingService._internal();
  factory ErrorHandlingService() => _instance;
  ErrorHandlingService._internal();

  final List<AppError> _errorHistory = [];
  final Map<ErrorType, int> _errorCounts = {};

  // File and document error handling
  Future<AppError?> validatePdfFile(String filePath) async {
    try {
      // Check if file exists
      final file = File(filePath);
      if (!await file.exists()) {
        return AppError(
          type: ErrorType.fileNotFound,
          severity: ErrorSeverity.high,
          message: 'PDF file not found',
          details: 'The file at path "$filePath" does not exist',
          suggestion: 'Please check the file path and ensure the file exists',
          recoveryActions: [
            'Browse for the correct file location',
            'Re-download the file if it was deleted',
            'Check if the file is on a removable drive',
          ],
          context: 'File validation',
        );
      }

      // Check file permissions
      try {
        await file.readAsBytes();
      } catch (e) {
        return AppError(
          type: ErrorType.permissionDenied,
          severity: ErrorSeverity.high,
          message: 'Cannot access PDF file',
          details: 'Permission denied when trying to read "$filePath": $e',
          suggestion:
              'Check file permissions and ensure the app has read access',
          recoveryActions: [
            'Check file permissions in system settings',
            'Move file to a location with proper permissions',
            'Run the application with appropriate privileges',
          ],
          context: 'File access',
        );
      }

      // Validate PDF format
      final validationError = await _validatePdfFormat(filePath);
      if (validationError != null) {
        return validationError;
      }

      return null; // No errors
    } catch (e) {
      return AppError(
        type: ErrorType.unknownError,
        severity: ErrorSeverity.medium,
        message: 'Unexpected error during file validation',
        details: 'Error: $e',
        suggestion: 'Try again or contact support if the problem persists',
        recoveryActions: [
          'Retry the operation',
          'Restart the application',
          'Check system resources',
        ],
        context: 'File validation',
      );
    }
  }

  Future<AppError?> _validatePdfFormat(String filePath) async {
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();

      // Check PDF header
      if (bytes.length < 4 ||
          String.fromCharCodes(bytes.sublist(0, 4)) != '%PDF') {
        return AppError(
          type: ErrorType.invalidFormat,
          severity: ErrorSeverity.high,
          message: 'Invalid PDF format',
          details: 'The file does not have a valid PDF header',
          suggestion: 'Ensure the file is a valid PDF document',
          recoveryActions: [
            'Try opening the file in a PDF viewer to verify it\'s valid',
            'Re-download the file if it may be corrupted',
            'Convert the file to PDF format if it\'s in a different format',
          ],
          context: 'PDF format validation',
        );
      }

      // Try to load the PDF document
      try {
        final document = PdfDocument(inputBytes: bytes);

        // Try to access document properties to check if it's valid
        try {
          // Attempt to get page count to verify document is accessible
          final pageCount = document.pages.count;
          if (pageCount == 0) {
            document.dispose();
            return AppError(
              type: ErrorType.invalidFormat,
              severity: ErrorSeverity.high,
              message: 'PDF has no pages',
              details: 'The PDF document appears to be empty',
              suggestion: 'Please provide a valid PDF with content',
              recoveryActions: [
                'Check if the PDF file is valid',
                'Try opening the PDF in another application',
                'Obtain a new copy of the document',
              ],
              context: 'PDF validation check',
            );
          }
        } catch (e) {
          document.dispose();
          return AppError(
            type: ErrorType.invalidFormat,
            severity: ErrorSeverity.high,
            message: 'PDF is password protected or corrupted',
            details: 'Unable to access PDF content: ${e.toString()}',
            suggestion: 'Please provide an unprotected and valid PDF',
            recoveryActions: [
              'Remove password protection from the PDF',
              'Obtain an unprotected version of the document',
              'Check if the PDF file is corrupted',
            ],
            context: 'PDF access check',
          );
        }

        // Check if PDF contains extractable text
        final textExtractionError = await _checkTextExtraction(document);
        document.dispose();

        return textExtractionError;
      } catch (e) {
        return AppError(
          type: ErrorType.fileCorrupted,
          severity: ErrorSeverity.high,
          message: 'PDF file appears to be corrupted',
          details: 'Unable to load PDF document: $e',
          suggestion: 'The PDF file may be damaged or corrupted',
          recoveryActions: [
            'Try re-downloading the file',
            'Use a PDF repair tool',
            'Obtain a fresh copy of the document',
            'Check if the file was completely downloaded',
          ],
          context: 'PDF loading',
        );
      }
    } catch (e) {
      return AppError(
        type: ErrorType.unknownError,
        severity: ErrorSeverity.medium,
        message: 'Error validating PDF format',
        details: 'Unexpected error: $e',
        suggestion: 'Try again or check system resources',
        recoveryActions: [
          'Retry the operation',
          'Check available memory',
          'Close other applications',
        ],
        context: 'PDF format validation',
      );
    }
  }

  Future<AppError?> _checkTextExtraction(PdfDocument document) async {
    try {
      if (document.pages.count == 0) {
        return AppError(
          type: ErrorType.invalidFormat,
          severity: ErrorSeverity.high,
          message: 'PDF contains no pages',
          details: 'The PDF document appears to be empty',
          suggestion: 'Ensure the PDF contains actual content',
          recoveryActions: [
            'Check if this is the correct file',
            'Obtain a complete version of the document',
            'Verify the file was not truncated during download',
          ],
          context: 'PDF content check',
        );
      }

      final extractor = PdfTextExtractor(document);

      // Test text extraction on first few pages
      int pagesWithText = 0;
      final maxPagesToCheck =
          document.pages.count < 5 ? document.pages.count : 5;

      for (int i = 0; i < maxPagesToCheck; i++) {
        try {
          final text = extractor.extractText(
            startPageIndex: i,
            endPageIndex: i,
          );
          if (text.trim().isNotEmpty) {
            pagesWithText++;
          }
        } catch (e) {
          // Individual page extraction failed, continue checking others
          debugPrint('Text extraction failed for page $i: $e');
        }
      }

      // If no pages have extractable text, it's likely a scanned PDF
      if (pagesWithText == 0) {
        return AppError(
          type: ErrorType.scannedPdf,
          severity: ErrorSeverity.medium,
          message: 'PDF appears to be scanned images',
          details:
              'No extractable text found in the first $maxPagesToCheck pages',
          suggestion:
              'This PDF contains scanned images and requires OCR processing',
          recoveryActions: [
            'Use an OCR tool to convert the PDF to searchable text',
            'Obtain a text-based version of the document',
            'The app will have limited search functionality with this file',
          ],
          context: 'Text extraction check',
        );
      }

      // If very few pages have text, warn about limited functionality
      if (pagesWithText < maxPagesToCheck * 0.5) {
        return AppError(
          type: ErrorType.scannedPdf,
          severity: ErrorSeverity.low,
          message: 'PDF has limited searchable text',
          details:
              'Only $pagesWithText out of $maxPagesToCheck pages contain extractable text',
          suggestion: 'Some features may be limited due to scanned content',
          recoveryActions: [
            'Continue with limited functionality',
            'Consider using an OCR-processed version',
            'Some pages may not be searchable',
          ],
          context: 'Text extraction check',
        );
      }

      return null; // No text extraction errors
    } catch (e) {
      return AppError(
        type: ErrorType.processingError,
        severity: ErrorSeverity.medium,
        message: 'Error checking PDF text content',
        details: 'Text extraction test failed: $e',
        suggestion: 'The PDF may have compatibility issues',
        recoveryActions: [
          'Try with a different PDF version',
          'Check if the PDF uses unsupported features',
          'Continue with limited functionality',
        ],
        context: 'Text extraction check',
      );
    }
  }

  // Asset file validation for bundled PDFs
  Future<AppError?> validateAssetPdf(String assetPath) async {
    try {
      // This would be used for bundled assets
      // For now, we'll assume asset files are valid
      return null;
    } catch (e) {
      return AppError(
        type: ErrorType.fileNotFound,
        severity: ErrorSeverity.critical,
        message: 'Required asset file missing',
        details: 'Asset file "$assetPath" could not be loaded: $e',
        suggestion: 'The application installation may be incomplete',
        recoveryActions: [
          'Reinstall the application',
          'Check application integrity',
          'Contact support for assistance',
        ],
        context: 'Asset validation',
      );
    }
  }

  // File size and memory validation
  AppError? validateFileSize(String filePath, int fileSizeBytes) {
    const maxFileSize = 100 * 1024 * 1024; // 100MB limit
    const warningSize = 50 * 1024 * 1024; // 50MB warning

    if (fileSizeBytes > maxFileSize) {
      return AppError(
        type: ErrorType.memoryError,
        severity: ErrorSeverity.high,
        message: 'PDF file is too large',
        details:
            'File size: ${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)}MB (limit: ${maxFileSize ~/ (1024 * 1024)}MB)',
        suggestion: 'Large files may cause performance issues or crashes',
        recoveryActions: [
          'Use a smaller version of the PDF',
          'Split the PDF into smaller sections',
          'Increase available system memory',
          'Close other applications to free memory',
        ],
        context: 'File size validation',
      );
    }

    if (fileSizeBytes > warningSize) {
      return AppError(
        type: ErrorType.memoryError,
        severity: ErrorSeverity.low,
        message: 'Large PDF file detected',
        details:
            'File size: ${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)}MB',
        suggestion: 'Large files may take longer to process',
        recoveryActions: [
          'Continue with current file (may be slower)',
          'Consider using a smaller version if available',
          'Ensure sufficient system memory is available',
        ],
        context: 'File size validation',
      );
    }

    return null;
  }

  // Error logging and tracking
  void logError(AppError error) {
    _errorHistory.add(error);
    _errorCounts[error.type] = (_errorCounts[error.type] ?? 0) + 1;

    // Keep only last 100 errors
    if (_errorHistory.length > 100) {
      _errorHistory.removeAt(0);
    }

    debugPrint('Error logged: ${error.toString()}');
  }

  List<AppError> getErrorHistory() {
    return List.unmodifiable(_errorHistory);
  }

  Map<ErrorType, int> getErrorCounts() {
    return Map.unmodifiable(_errorCounts);
  }

  void clearErrorHistory() {
    _errorHistory.clear();
    _errorCounts.clear();
  }

  // Error recovery suggestions
  List<String> getRecoveryActions(ErrorType errorType) {
    switch (errorType) {
      case ErrorType.fileNotFound:
        return [
          'Check the file path and location',
          'Ensure the file exists and hasn\'t been moved',
          'Browse for the correct file location',
          'Re-download the file if necessary',
        ];
      case ErrorType.fileCorrupted:
        return [
          'Re-download the file from the original source',
          'Use a PDF repair tool',
          'Check if the file was completely downloaded',
          'Try a different version of the file',
        ];
      case ErrorType.scannedPdf:
        return [
          'Use OCR software to create a searchable version',
          'Obtain a text-based version of the document',
          'Continue with limited search functionality',
          'Consider manual navigation using bookmarks',
        ];
      case ErrorType.invalidFormat:
        return [
          'Verify the file is a valid PDF',
          'Convert the file to PDF format if needed',
          'Remove password protection if present',
          'Try opening in a PDF viewer to verify',
        ];
      case ErrorType.permissionDenied:
        return [
          'Check file permissions in system settings',
          'Move file to a location with proper access',
          'Run application with appropriate privileges',
          'Ensure the file is not locked by another application',
        ];
      default:
        return [
          'Retry the operation',
          'Restart the application',
          'Check system resources',
          'Contact support if problem persists',
        ];
    }
  }
}
