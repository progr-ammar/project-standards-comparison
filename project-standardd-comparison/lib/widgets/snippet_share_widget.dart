import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/deep_link_service.dart';
import 'sharing_dialog.dart';

class SnippetShareWidget extends StatelessWidget {
  final String content;
  final String bookId;
  final int page;
  final String? highlight;
  final bool showFullDialog;

  const SnippetShareWidget({
    super.key,
    required this.content,
    required this.bookId,
    required this.page,
    this.highlight,
    this.showFullDialog = false,
  });

  @override
  Widget build(BuildContext context) {
    if (showFullDialog) {
      return _FullShareWidget(
        content: content,
        bookId: bookId,
        page: page,
        highlight: highlight,
      );
    }

    return _QuickShareWidget(
      content: content,
      bookId: bookId,
      page: page,
      highlight: highlight,
    );
  }
}

class _QuickShareWidget extends StatelessWidget {
  final String content;
  final String bookId;
  final int page;
  final String? highlight;

  const _QuickShareWidget({
    required this.content,
    required this.bookId,
    required this.page,
    this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Quick copy button
        IconButton(
          tooltip: 'Copy with citation',
          icon: const Icon(Icons.content_copy),
          onPressed: () => _quickCopy(context),
        ),
        // Share options button
        IconButton(
          tooltip: 'More sharing options',
          icon: const Icon(Icons.share),
          onPressed: () => _showFullShareDialog(context),
        ),
      ],
    );
  }

  Future<void> _quickCopy(BuildContext context) async {
    try {
      final deepLinkService = DeepLinkService();
      final citation = _generateCitation(bookId, page);
      final shareText = '$content\n\n$citation';

      await Clipboard.setData(ClipboardData(text: shareText));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Snippet copied with citation'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error copying: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _showFullShareDialog(BuildContext context) async {
    final deepLinkService = DeepLinkService();
    final deepLink = deepLinkService.generateSnippetLink(
      bookId: bookId,
      page: page,
      text: content,
      highlight: highlight,
    );

    await showSharingDialog(
      context,
      deepLink: deepLink,
      content: content,
      title: 'Share Snippet',
      citation: _generateCitation(bookId, page),
    );
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
}

class _FullShareWidget extends StatefulWidget {
  final String content;
  final String bookId;
  final int page;
  final String? highlight;

  const _FullShareWidget({
    required this.content,
    required this.bookId,
    required this.page,
    this.highlight,
  });

  @override
  State<_FullShareWidget> createState() => _FullShareWidgetState();
}

class _FullShareWidgetState extends State<_FullShareWidget> {
  final DeepLinkService _deepLinkService = DeepLinkService();
  late String _deepLink;
  late String _citation;

  @override
  void initState() {
    super.initState();
    _deepLink = _deepLinkService.generateSnippetLink(
      bookId: widget.bookId,
      page: widget.page,
      text: widget.content,
      highlight: widget.highlight,
    );
    _citation = _generateCitation(widget.bookId, widget.page);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.share),
                const SizedBox(width: 8),
                Text(
                  'Share Options',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Content preview
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.content,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _citation,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Quick actions
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _quickCopyWithCitation,
                  icon: const Icon(Icons.content_copy),
                  label: const Text('Copy with Citation'),
                ),
                ElevatedButton.icon(
                  onPressed: _shareViaEmail,
                  icon: const Icon(Icons.email),
                  label: const Text('Email'),
                ),
                ElevatedButton.icon(
                  onPressed: _shareGeneral,
                  icon: const Icon(Icons.share),
                  label: const Text('Share'),
                ),
                ElevatedButton.icon(
                  onPressed: _showQRCode,
                  icon: const Icon(Icons.qr_code),
                  label: const Text('QR Code'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Deep link display
            Text('Deep Link:', style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _deepLink,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Copy link',
                    icon: const Icon(Icons.content_copy),
                    onPressed: _copyDeepLink,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _quickCopyWithCitation() async {
    try {
      final shareText = '${widget.content}\n\n$_citation';
      await Clipboard.setData(ClipboardData(text: shareText));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Snippet copied with citation'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      _showError('Error copying: $e');
    }
  }

  Future<void> _shareViaEmail() async {
    try {
      await _deepLinkService.shareWithCitation(
        content: widget.content,
        bookId: widget.bookId,
        page: widget.page,
        deepLink: _deepLink,
        format: ShareFormat.email,
      );
    } catch (e) {
      _showError('Error sharing via email: $e');
    }
  }

  Future<void> _shareGeneral() async {
    try {
      await _deepLinkService.shareWithCitation(
        content: widget.content,
        bookId: widget.bookId,
        page: widget.page,
        deepLink: _deepLink,
        format: ShareFormat.text,
      );
    } catch (e) {
      _showError('Error sharing: $e');
    }
  }

  Future<void> _copyDeepLink() async {
    try {
      await Clipboard.setData(ClipboardData(text: _deepLink));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Deep link copied'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      _showError('Error copying link: $e');
    }
  }

  void _showQRCode() {
    showDialog(
      context: context,
      builder:
          (context) =>
              QRCodeDialog(deepLink: _deepLink, title: 'Snippet QR Code'),
    );
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
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
}

// Utility functions for easy integration
class SnippetShareUtils {
  static final DeepLinkService _deepLinkService = DeepLinkService();

  static Future<void> quickCopyWithCitation({
    required BuildContext context,
    required String content,
    required String bookId,
    required int page,
  }) async {
    try {
      final citation = _generateCitation(bookId, page);
      final shareText = '$content\n\n$citation';

      await Clipboard.setData(ClipboardData(text: shareText));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Snippet copied with citation'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error copying: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  static Future<void> shareSnippet({
    required BuildContext context,
    required String content,
    required String bookId,
    required int page,
    String? highlight,
    ShareFormat format = ShareFormat.text,
  }) async {
    try {
      await _deepLinkService.shareWithCitation(
        content: content,
        bookId: bookId,
        page: page,
        format: format,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  static String _generateCitation(String bookId, int page) {
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
}
