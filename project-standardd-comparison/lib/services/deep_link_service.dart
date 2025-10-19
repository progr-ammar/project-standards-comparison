import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

import '../screens/reader_screen.dart';
import '../screens/compare_screen.dart';
import '../screens/bookmarks_screen.dart';
import '../screens/parallel_search_screen.dart';

// Wrapper classes for deep link navigation
class CompareScreenWithTopic extends StatefulWidget {
  final String initialTopic;
  final List<String> initialBookIds;
  final String? comparisonId;

  const CompareScreenWithTopic({
    super.key,
    required this.initialTopic,
    this.initialBookIds = const [],
    this.comparisonId,
  });

  @override
  State<CompareScreenWithTopic> createState() => _CompareScreenWithTopicState();
}

class _CompareScreenWithTopicState extends State<CompareScreenWithTopic> {
  @override
  void initState() {
    super.initState();
    // Initialize the comparison with the provided topic
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeComparison();
    });
  }

  void _initializeComparison() {
    // This would trigger the comparison generation with the initial topic
    // Implementation depends on how CompareScreen handles initial state
    debugPrint('Initializing comparison with topic: ${widget.initialTopic}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Compare: ${widget.initialTopic}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: const CompareScreen(),
    );
  }
}

class DeepLinkService {
  DeepLinkService();

  static const String _baseUrl = 'pmstandards://';
  static const String _webBaseUrl = 'https://pmstandards.app/';

  // Deep link generation methods
  String generateViewerLink({
    required String bookId,
    int? page,
    String? highlight,
    Map<String, dynamic>? metadata,
  }) {
    final params = <String, dynamic>{'action': 'view', 'book': bookId};

    if (page != null) params['page'] = page;
    if (highlight != null) params['highlight'] = highlight;
    if (metadata != null) params.addAll(metadata);

    return _buildDeepLink(params);
  }

  String generateComparisonLink({
    required String topic,
    List<String>? bookIds,
    String? comparisonId,
    Map<String, dynamic>? metadata,
  }) {
    final params = <String, dynamic>{'action': 'compare', 'topic': topic};

    if (bookIds != null && bookIds.isNotEmpty) {
      params['books'] = bookIds.join(',');
    }
    if (comparisonId != null) params['id'] = comparisonId;
    if (metadata != null) params.addAll(metadata);

    return _buildDeepLink(params);
  }

  String generateBookmarkLink({
    required String bookmarkId,
    String? bookId,
    int? page,
    Map<String, dynamic>? metadata,
  }) {
    final params = <String, dynamic>{'action': 'bookmark', 'id': bookmarkId};

    if (bookId != null) params['book'] = bookId;
    if (page != null) params['page'] = page;
    if (metadata != null) params.addAll(metadata);

    return _buildDeepLink(params);
  }

  String generateSnippetLink({
    required String bookId,
    required int page,
    required String text,
    String? highlight,
    Map<String, dynamic>? metadata,
  }) {
    final params = <String, dynamic>{
      'action': 'snippet',
      'book': bookId,
      'page': page,
      'text': _encodeText(text),
    };

    if (highlight != null) params['highlight'] = highlight;
    if (metadata != null) params.addAll(metadata);

    return _buildDeepLink(params);
  }

  String generateSearchLink({
    required String query,
    List<String>? bookIds,
    String? topic,
    Map<String, dynamic>? metadata,
  }) {
    final params = <String, dynamic>{'action': 'search', 'q': query};

    if (bookIds != null && bookIds.isNotEmpty) {
      params['books'] = bookIds.join(',');
    }
    if (topic != null) params['topic'] = topic;
    if (metadata != null) params.addAll(metadata);

    return _buildDeepLink(params);
  }

  String generateProcessLink({
    required String processId,
    Map<String, dynamic>? metadata,
  }) {
    final params = <String, dynamic>{'action': 'process', 'id': processId};

    if (metadata != null) params.addAll(metadata);

    return _buildDeepLink(params);
  }

  // Web-compatible link generation
  String generateWebLink(Map<String, dynamic> params) {
    final queryParams = params.entries
        .map(
          (e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value.toString())}',
        )
        .join('&');

    return '$_webBaseUrl?$queryParams';
  }

  // QR Code generation
  Future<Uint8List> generateQRCode(
    String deepLink, {
    double size = 200.0,
    Color foregroundColor = Colors.black,
    Color backgroundColor = Colors.white,
    int errorCorrectionLevel = QrErrorCorrectLevel.M,
  }) async {
    final qrValidationResult = QrValidator.validate(
      data: deepLink,
      version: QrVersions.auto,
      errorCorrectionLevel: errorCorrectionLevel,
    );

    if (qrValidationResult.status != QrValidationStatus.valid) {
      throw Exception('Invalid QR code data: ${qrValidationResult.error}');
    }

    final painter = QrPainter(
      data: deepLink,
      version: QrVersions.auto,
      errorCorrectionLevel: errorCorrectionLevel,
      eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.square, color: foregroundColor),
      dataModuleStyle: QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.square,
        color: foregroundColor,
      ),
      gapless: false,
    );

    final picData = await painter.toImageData(size);
    return picData!.buffer.asUint8List();
  }

  // QR Code widget generation
  Widget generateQRWidget(
    String deepLink, {
    double size = 200.0,
    Color foregroundColor = Colors.black,
    Color backgroundColor = Colors.white,
    int errorCorrectionLevel = QrErrorCorrectLevel.M,
    Widget? embeddedImage,
    double? embeddedImageSizeWidth,
    double? embeddedImageSizeHeight,
  }) {
    return QrImageView(
      data: deepLink,
      version: QrVersions.auto,
      size: size,
      backgroundColor: backgroundColor,
      errorCorrectionLevel: errorCorrectionLevel,
      eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.square, color: foregroundColor),
      dataModuleStyle: QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.square,
        color: foregroundColor,
      ),
      embeddedImage:
          embeddedImage != null
              ? const AssetImage('assets/app_icon.png')
              : null,
      embeddedImageStyle:
          embeddedImage != null
              ? QrEmbeddedImageStyle(
                size: Size(
                  embeddedImageSizeWidth ?? 40,
                  embeddedImageSizeHeight ?? 40,
                ),
              )
              : null,
    );
  }

  // Deep link parsing
  DeepLinkData? parseDeepLink(String link) {
    try {
      Uri uri;

      if (link.startsWith(_baseUrl)) {
        uri = Uri.parse(link);
      } else if (link.startsWith(_webBaseUrl)) {
        uri = Uri.parse(link);
      } else {
        return null;
      }

      final action = uri.queryParameters['action'];
      if (action == null) return null;

      return DeepLinkData(
        action: action,
        parameters: Map<String, dynamic>.from(uri.queryParameters),
      );
    } catch (e) {
      debugPrint('Error parsing deep link: $e');
      return null;
    }
  }

  // Navigation handling
  Future<bool> handleDeepLink(String link, BuildContext context) async {
    final linkData = parseDeepLink(link);
    if (linkData == null) return false;

    try {
      switch (linkData.action) {
        case 'view':
          return await _handleViewerLink(linkData.parameters, context);
        case 'compare':
          return await _handleComparisonLink(linkData.parameters, context);
        case 'bookmark':
          return await _handleBookmarkLink(linkData.parameters, context);
        case 'snippet':
          return await _handleSnippetLink(linkData.parameters, context);
        case 'search':
          return await _handleSearchLink(linkData.parameters, context);
        case 'process':
          return await _handleProcessLink(linkData.parameters, context);
        default:
          debugPrint('Unknown deep link action: ${linkData.action}');
          return false;
      }
    } catch (e) {
      debugPrint('Error handling deep link: $e');
      return false;
    }
  }

  // Link validation
  bool isValidDeepLink(String link) {
    return link.startsWith(_baseUrl) || link.startsWith(_webBaseUrl);
  }

  DeepLinkValidationResult validateDeepLink(String link) {
    if (!isValidDeepLink(link)) {
      return DeepLinkValidationResult(
        isValid: false,
        error: 'Invalid deep link format',
      );
    }

    final linkData = parseDeepLink(link);
    if (linkData == null) {
      return DeepLinkValidationResult(
        isValid: false,
        error: 'Failed to parse deep link',
      );
    }

    // Validate required parameters based on action
    String? error;
    switch (linkData.action) {
      case 'view':
        if (!linkData.parameters.containsKey('book')) {
          error = 'Missing required parameter: book';
        }
        break;
      case 'compare':
        if (!linkData.parameters.containsKey('topic')) {
          error = 'Missing required parameter: topic';
        }
        break;
      case 'bookmark':
        if (!linkData.parameters.containsKey('id')) {
          error = 'Missing required parameter: id';
        }
        break;
      case 'snippet':
        if (!linkData.parameters.containsKey('book') ||
            !linkData.parameters.containsKey('page') ||
            !linkData.parameters.containsKey('text')) {
          error = 'Missing required parameters for snippet';
        }
        break;
      case 'search':
        if (!linkData.parameters.containsKey('q')) {
          error = 'Missing required parameter: q (query)';
        }
        break;
      case 'process':
        if (!linkData.parameters.containsKey('id')) {
          error = 'Missing required parameter: id';
        }
        break;
      default:
        error = 'Unknown action: ${linkData.action}';
    }

    return DeepLinkValidationResult(
      isValid: error == null,
      error: error,
      linkData: linkData,
    );
  }

  // Enhanced sharing functionality
  Future<void> shareDeepLink(
    String link, {
    String? subject,
    String? text,
    ShareFormat format = ShareFormat.text,
  }) async {
    final shareText =
        text ?? 'Check out this content from PM Standards App: $link';
    final shareSubject = subject ?? 'Shared from PM Standards App';

    try {
      switch (format) {
        case ShareFormat.text:
          await Share.share(shareText, subject: shareSubject);
          break;
        case ShareFormat.email:
          await _shareViaEmail(shareSubject, shareText);
          break;
        case ShareFormat.social:
          await Share.share(shareText, subject: shareSubject);
          break;
        case ShareFormat.clipboard:
          await _copyToClipboard(shareText);
          break;
      }
    } catch (e) {
      debugPrint('Error sharing deep link: $e');
      // Fallback to clipboard
      await _copyToClipboard(shareText);
    }
  }

  Future<void> _shareViaEmail(String subject, String body) async {
    final uri = Uri(
      scheme: 'mailto',
      queryParameters: {'subject': subject, 'body': body},
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw Exception('Cannot launch email client');
    }
  }

  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }

  // Share with citation
  Future<void> shareWithCitation({
    required String content,
    required String bookId,
    required int page,
    String? deepLink,
    ShareFormat format = ShareFormat.text,
  }) async {
    final citation = _generateCitation(bookId, page);
    final shareText = '$content\n\n$citation';

    if (deepLink != null) {
      await shareDeepLink(
        deepLink,
        text: '$shareText\n\nView in app: $deepLink',
        format: format,
      );
    } else {
      final link = generateSnippetLink(
        bookId: bookId,
        page: page,
        text: content,
      );
      await shareDeepLink(
        link,
        text: '$shareText\n\nView in app: $link',
        format: format,
      );
    }
  }

  String _generateCitation(String bookId, int page) {
    final bookTitles = {
      'pmbok7':
          'A Guide to the Project Management Body of Knowledge (PMBOK® Guide) – Seventh Edition',
      'prince2': 'Managing Successful Projects with PRINCE2®',
      'iso21502':
          'ISO 21502:2020 Project, programme and portfolio management - Guidance on project management',
    };

    final title = bookTitles[bookId] ?? bookId;
    return 'Source: $title, Page $page';
  }

  // Utility methods
  String _buildDeepLink(Map<String, dynamic> params) {
    final queryParams = params.entries
        .map(
          (e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value.toString())}',
        )
        .join('&');

    return '$_baseUrl?$queryParams';
  }

  String _encodeText(String text) {
    // Encode text for URL safety, truncate if too long
    final truncated = text.length > 200 ? '${text.substring(0, 200)}...' : text;
    return base64Encode(utf8.encode(truncated));
  }

  String _decodeText(String encodedText) {
    try {
      return utf8.decode(base64Decode(encodedText));
    } catch (e) {
      debugPrint('Error decoding text: $e');
      return encodedText; // Return as-is if decoding fails
    }
  }

  // Navigation handlers
  Future<bool> _handleViewerLink(
    Map<String, dynamic> params,
    BuildContext context,
  ) async {
    final bookId = params['book'] as String?;
    final page = int.tryParse(params['page']?.toString() ?? '');
    final highlight = params['highlight'] as String?;

    if (bookId == null) return false;

    try {
      // Map book IDs to their asset paths and titles
      final bookInfo = _getBookInfo(bookId);
      if (bookInfo == null) return false;

      // Create the ReaderScreen
      final readerScreen = _createReaderScreen(
        bookInfo['title']!,
        bookInfo['assetPath']!,
        bookId,
        page,
        highlight,
      );

      if (context.mounted) {
        await Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => readerScreen));
      }

      trackDeepLinkUsage('viewer_navigation');
      return true;
    } catch (e) {
      debugPrint('Error navigating to viewer: $e');
      return false;
    }
  }

  Map<String, String>? _getBookInfo(String bookId) {
    final bookMappings = {
      'pmbok7': {
        'title': 'PMBOK Guide 7th Edition',
        'assetPath': 'assets/pmbok7.pdf',
      },
      'prince2': {
        'title': 'PRINCE2 Managing Successful Projects',
        'assetPath': 'assets/prince2.pdf',
      },
      'iso21502': {
        'title': 'ISO 21502:2020',
        'assetPath': 'assets/iso21502.pdf',
      },
    };
    return bookMappings[bookId];
  }

  Widget _createReaderScreen(
    String title,
    String assetPath,
    String bookId,
    int? page,
    String? highlight,
  ) {
    return ReaderScreen(
      title: title,
      assetPath: assetPath,
      bookId: bookId,
      initialPage: page,
      highlightText: highlight,
    );
  }

  Future<bool> _handleComparisonLink(
    Map<String, dynamic> params,
    BuildContext context,
  ) async {
    final topic = params['topic'] as String?;
    final booksParam = params['books'] as String?;
    final comparisonId = params['id'] as String?;

    if (topic == null) return false;

    try {
      final bookIds = booksParam?.split(',') ?? [];

      if (context.mounted) {
        // Navigate to Compare screen with the topic pre-selected
        // Since CompareScreen is already in the main navigation, we need to
        // navigate to the main app and set the comparison state
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder:
                (_) => CompareScreenWithTopic(
                  initialTopic: topic,
                  initialBookIds: bookIds,
                  comparisonId: comparisonId,
                ),
          ),
        );
      }

      trackDeepLinkUsage('comparison_navigation');
      return true;
    } catch (e) {
      debugPrint('Error navigating to comparison: $e');
      return false;
    }
  }

  Future<bool> _handleBookmarkLink(
    Map<String, dynamic> params,
    BuildContext context,
  ) async {
    final bookmarkId = params['id'] as String?;
    final bookId = params['book'] as String?;
    final page = int.tryParse(params['page']?.toString() ?? '');

    if (bookmarkId == null) return false;

    try {
      if (context.mounted) {
        // Navigate to bookmarks screen
        // Note: BookmarksScreen doesn't currently support highlighting specific bookmarks
        // This could be enhanced in the future
        await Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const BookmarksScreen()));
      }

      trackDeepLinkUsage('bookmark_navigation');
      return true;
    } catch (e) {
      debugPrint('Error navigating to bookmark: $e');
      return false;
    }
  }

  Future<bool> _handleSnippetLink(
    Map<String, dynamic> params,
    BuildContext context,
  ) async {
    final bookId = params['book'] as String?;
    final page = int.tryParse(params['page']?.toString() ?? '');
    final encodedText = params['text'] as String?;
    final highlight = params['highlight'] as String?;

    if (bookId == null || page == null || encodedText == null) return false;

    try {
      final text = _decodeText(encodedText);
      final bookInfo = _getBookInfo(bookId);
      if (bookInfo == null) return false;

      if (context.mounted) {
        // Navigate to reader screen with the snippet highlighted
        final readerScreen = _createReaderScreen(
          bookInfo['title']!,
          bookInfo['assetPath']!,
          bookId,
          page,
          highlight ?? text,
        );

        await Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => readerScreen));
      }

      trackDeepLinkUsage('snippet_navigation');
      return true;
    } catch (e) {
      debugPrint('Error navigating to snippet: $e');
      return false;
    }
  }

  Future<bool> _handleSearchLink(
    Map<String, dynamic> params,
    BuildContext context,
  ) async {
    final query = params['q'] as String?;
    final booksParam = params['books'] as String?;
    final topic = params['topic'] as String?;

    if (query == null) return false;

    try {
      final bookIds = booksParam?.split(',') ?? [];

      if (context.mounted) {
        // Navigate to parallel search screen with the query
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ParallelSearchScreen(query: query)),
        );
      }

      trackDeepLinkUsage('search_navigation');
      return true;
    } catch (e) {
      debugPrint('Error navigating to search: $e');
      return false;
    }
  }

  Future<bool> _handleProcessLink(
    Map<String, dynamic> params,
    BuildContext context,
  ) async {
    final processId = params['id'] as String?;

    if (processId == null) return false;

    try {
      if (context.mounted) {
        // Navigate to Generate screen with the process pre-loaded
        // Since GenerateScreen is in main navigation, we'll show a dialog
        // or navigate to a specific process view
        await _showProcessDialog(context, processId);
      }

      trackDeepLinkUsage('process_navigation');
      return true;
    } catch (e) {
      debugPrint('Error navigating to process: $e');
      return false;
    }
  }

  Future<void> _showProcessDialog(
    BuildContext context,
    String processId,
  ) async {
    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Process Link'),
            content: Text('Opening process: $processId'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  // Batch operations
  List<String> generateMultipleLinks(List<Map<String, dynamic>> linkConfigs) {
    return linkConfigs.map((config) {
      final action = config['action'] as String;
      final params = Map<String, dynamic>.from(config);

      switch (action) {
        case 'view':
          return generateViewerLink(
            bookId: params['book'],
            page: params['page'],
            highlight: params['highlight'],
            metadata: params['metadata'],
          );
        case 'compare':
          return generateComparisonLink(
            topic: params['topic'],
            bookIds: params['books'],
            comparisonId: params['id'],
            metadata: params['metadata'],
          );
        case 'bookmark':
          return generateBookmarkLink(
            bookmarkId: params['id'],
            bookId: params['book'],
            page: params['page'],
            metadata: params['metadata'],
          );
        default:
          return _buildDeepLink(params);
      }
    }).toList();
  }

  // Comprehensive sharing options
  Future<void> shareComparison({
    required String comparisonId,
    required String topic,
    required List<String> bookIds,
    ShareFormat format = ShareFormat.text,
  }) async {
    final link = generateComparisonLink(
      topic: topic,
      bookIds: bookIds,
      comparisonId: comparisonId,
    );

    final shareText =
        'Check out this comparison on "$topic" from PM Standards App';
    await shareDeepLink(link, text: shareText, format: format);
  }

  Future<void> shareBookmark({
    required String bookmarkId,
    required String bookId,
    required int page,
    required String snippet,
    ShareFormat format = ShareFormat.text,
  }) async {
    final link = generateBookmarkLink(
      bookmarkId: bookmarkId,
      bookId: bookId,
      page: page,
    );

    await shareWithCitation(
      content: snippet,
      bookId: bookId,
      page: page,
      deepLink: link,
      format: format,
    );
  }

  Future<void> shareSearchResults({
    required String query,
    List<String>? bookIds,
    String? topic,
    ShareFormat format = ShareFormat.text,
  }) async {
    final link = generateSearchLink(
      query: query,
      bookIds: bookIds,
      topic: topic,
    );

    final shareText = 'Search results for "$query" in PM Standards App';
    await shareDeepLink(link, text: shareText, format: format);
  }

  // QR Code sharing
  Future<void> shareQRCode(String deepLink, {String? filename}) async {
    try {
      final qrBytes = await generateQRCode(deepLink);
      final tempFile = await _saveQRCodeToTemp(qrBytes, filename);

      await Share.shareXFiles([
        XFile(tempFile.path),
      ], text: 'QR Code for PM Standards App content');
    } catch (e) {
      debugPrint('Error sharing QR code: $e');
      // Fallback to sharing the link as text
      await shareDeepLink(deepLink);
    }
  }

  Future<File> _saveQRCodeToTemp(Uint8List qrBytes, String? filename) async {
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/${filename ?? 'qr_code'}.png');
    await file.writeAsBytes(qrBytes);
    return file;
  }

  // Batch sharing operations
  Future<void> shareMultipleLinks(
    List<String> links, {
    String? subject,
    ShareFormat format = ShareFormat.text,
  }) async {
    final shareText = links.join('\n\n');
    await Share.share(
      shareText,
      subject: subject ?? 'Multiple links from PM Standards App',
    );
  }

  // Social media specific sharing
  Future<void> shareToSocialMedia(
    String link, {
    required String platform,
    String? text,
  }) async {
    final shareText =
        text ?? 'Check out this content from PM Standards App: $link';

    switch (platform.toLowerCase()) {
      case 'twitter':
        final twitterUrl =
            'https://twitter.com/intent/tweet?text=${Uri.encodeComponent(shareText)}';
        await _launchUrl(twitterUrl);
        break;
      case 'linkedin':
        final linkedinUrl =
            'https://www.linkedin.com/sharing/share-offsite/?url=${Uri.encodeComponent(link)}';
        await _launchUrl(linkedinUrl);
        break;
      case 'facebook':
        final facebookUrl =
            'https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent(link)}';
        await _launchUrl(facebookUrl);
        break;
      default:
        await Share.share(shareText);
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw Exception('Cannot launch URL: $url');
    }
  }

  // Analytics and tracking
  void trackDeepLinkGeneration(String action, Map<String, dynamic> params) {
    // This would typically send analytics data
    debugPrint('Deep link generated: action=$action, params=$params');
  }

  void trackDeepLinkUsage(String link) {
    // This would typically send analytics data
    debugPrint('Deep link used: $link');
  }

  void trackSharingActivity(String action, ShareFormat format) {
    // This would typically send analytics data
    debugPrint('Sharing activity: action=$action, format=$format');
  }
}

// Enums
enum ShareFormat { text, email, social, clipboard }

// Data classes
class DeepLinkData {
  final String action;
  final Map<String, dynamic> parameters;

  DeepLinkData({required this.action, required this.parameters});

  @override
  String toString() {
    return 'DeepLinkData(action: $action, parameters: $parameters)';
  }
}

class DeepLinkValidationResult {
  final bool isValid;
  final String? error;
  final DeepLinkData? linkData;

  DeepLinkValidationResult({required this.isValid, this.error, this.linkData});

  @override
  String toString() {
    return 'DeepLinkValidationResult(isValid: $isValid, error: $error, linkData: $linkData)';
  }
}
