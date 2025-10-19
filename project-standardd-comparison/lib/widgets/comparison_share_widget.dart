import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/deep_link_service.dart';
import '../providers/comparison_provider.dart';
import 'sharing_dialog.dart';

class ComparisonShareWidget extends StatelessWidget {
  final Comparison comparison;
  final bool showFullDialog;

  const ComparisonShareWidget({
    super.key,
    required this.comparison,
    this.showFullDialog = false,
  });

  @override
  Widget build(BuildContext context) {
    if (showFullDialog) {
      return _FullComparisonShareWidget(comparison: comparison);
    }

    return _QuickComparisonShareWidget(comparison: comparison);
  }
}

class _QuickComparisonShareWidget extends StatelessWidget {
  final Comparison comparison;

  const _QuickComparisonShareWidget({required this.comparison});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Quick copy summary
        IconButton(
          tooltip: 'Copy comparison summary',
          icon: const Icon(Icons.content_copy),
          onPressed: () => _quickCopySummary(context),
        ),
        // Share comparison
        IconButton(
          tooltip: 'Share comparison',
          icon: const Icon(Icons.share),
          onPressed: () => _showFullShareDialog(context),
        ),
        // Export options
        PopupMenuButton<String>(
          tooltip: 'Export options',
          icon: const Icon(Icons.download),
          onSelected: (value) => _handleExport(context, value),
          itemBuilder:
              (context) => [
                const PopupMenuItem(
                  value: 'pdf',
                  child: Row(
                    children: [
                      Icon(Icons.picture_as_pdf),
                      SizedBox(width: 8),
                      Text('Export as PDF'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'html',
                  child: Row(
                    children: [
                      Icon(Icons.web),
                      SizedBox(width: 8),
                      Text('Export as HTML'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'text',
                  child: Row(
                    children: [
                      Icon(Icons.text_snippet),
                      SizedBox(width: 8),
                      Text('Export as Text'),
                    ],
                  ),
                ),
              ],
        ),
      ],
    );
  }

  Future<void> _quickCopySummary(BuildContext context) async {
    try {
      final summary = _generateComparisonSummary(comparison);
      await Clipboard.setData(ClipboardData(text: summary));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comparison summary copied'),
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
    final bookIds = comparison.snippets.map((s) => s.bookId).toSet().toList();
    final deepLink = deepLinkService.generateComparisonLink(
      topic: comparison.topic,
      bookIds: bookIds,
      comparisonId: comparison.id,
    );

    final summary = _generateComparisonSummary(comparison);

    await showSharingDialog(
      context,
      deepLink: deepLink,
      content: summary,
      title: 'Share Comparison: ${comparison.topic}',
    );
  }

  Future<void> _handleExport(BuildContext context, String format) async {
    // This would integrate with the ExportService
    // For now, we'll show a placeholder
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Export as $format - Feature coming soon')),
    );
  }

  String _generateComparisonSummary(Comparison comparison) {
    final buffer = StringBuffer();

    buffer.writeln('Comparison: ${comparison.topic}');
    buffer.writeln(
      'Created: ${comparison.created.toLocal().toString().split('.')[0]}',
    );
    buffer.writeln();

    // Add insights summary
    if (comparison.insights.similarities.isNotEmpty) {
      buffer.writeln('Key Similarities:');
      for (final similarity in comparison.insights.similarities.take(3)) {
        buffer.writeln('• ${similarity.content}');
      }
      buffer.writeln();
    }

    if (comparison.insights.differences.isNotEmpty) {
      buffer.writeln('Key Differences:');
      for (final difference in comparison.insights.differences.take(3)) {
        buffer.writeln('• ${difference.content}');
      }
      buffer.writeln();
    }

    if (comparison.insights.uniquePoints.isNotEmpty) {
      buffer.writeln('Unique Points:');
      for (final unique in comparison.insights.uniquePoints.take(3)) {
        buffer.writeln('• ${unique.content}');
      }
      buffer.writeln();
    }

    // Add book coverage
    final bookIds = comparison.snippets.map((s) => s.bookId).toSet();
    buffer.writeln('Standards Compared: ${bookIds.join(', ')}');

    return buffer.toString();
  }
}

class _FullComparisonShareWidget extends StatefulWidget {
  final Comparison comparison;

  const _FullComparisonShareWidget({required this.comparison});

  @override
  State<_FullComparisonShareWidget> createState() =>
      _FullComparisonShareWidgetState();
}

class _FullComparisonShareWidgetState
    extends State<_FullComparisonShareWidget> {
  final DeepLinkService _deepLinkService = DeepLinkService();
  late String _deepLink;
  late String _summary;

  @override
  void initState() {
    super.initState();
    final bookIds =
        widget.comparison.snippets.map((s) => s.bookId).toSet().toList();
    _deepLink = _deepLinkService.generateComparisonLink(
      topic: widget.comparison.topic,
      bookIds: bookIds,
      comparisonId: widget.comparison.id,
    );
    _summary = _generateDetailedSummary(widget.comparison);
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
                const Icon(Icons.compare_arrows),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Share Comparison: ${widget.comparison.topic}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Comparison stats
            _buildStatsRow(context),
            const SizedBox(height: 16),

            // Summary preview
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
                    'Summary Preview:',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _summary,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 6,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Share actions
            Text(
              'Share Options:',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _copySummary,
                  icon: const Icon(Icons.content_copy),
                  label: const Text('Copy Summary'),
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

            // Export options
            Text(
              'Export Options:',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _exportAs('pdf'),
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('PDF'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _exportAs('html'),
                  icon: const Icon(Icons.web),
                  label: const Text('HTML'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _exportAs('text'),
                  icon: const Icon(Icons.text_snippet),
                  label: const Text('Text'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Deep link
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

  Widget _buildStatsRow(BuildContext context) {
    final insights = widget.comparison.insights;
    return Row(
      children: [
        _StatChip(
          icon: Icons.check_circle,
          label: 'Similarities',
          count: insights.similarities.length,
          color: Colors.green,
        ),
        const SizedBox(width: 8),
        _StatChip(
          icon: Icons.compare_arrows,
          label: 'Differences',
          count: insights.differences.length,
          color: Colors.orange,
        ),
        const SizedBox(width: 8),
        _StatChip(
          icon: Icons.star,
          label: 'Unique',
          count: insights.uniquePoints.length,
          color: Colors.blue,
        ),
      ],
    );
  }

  Future<void> _copySummary() async {
    try {
      await Clipboard.setData(ClipboardData(text: _summary));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comparison summary copied'),
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
      await _deepLinkService.shareComparison(
        comparisonId: widget.comparison.id,
        topic: widget.comparison.topic,
        bookIds:
            widget.comparison.snippets.map((s) => s.bookId).toSet().toList(),
        format: ShareFormat.email,
      );
    } catch (e) {
      _showError('Error sharing via email: $e');
    }
  }

  Future<void> _shareGeneral() async {
    try {
      await _deepLinkService.shareComparison(
        comparisonId: widget.comparison.id,
        topic: widget.comparison.topic,
        bookIds:
            widget.comparison.snippets.map((s) => s.bookId).toSet().toList(),
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
              QRCodeDialog(deepLink: _deepLink, title: 'Comparison QR Code'),
    );
  }

  Future<void> _exportAs(String format) async {
    // This would integrate with the ExportService
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Export as $format - Feature coming soon')),
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

  String _generateDetailedSummary(Comparison comparison) {
    final buffer = StringBuffer();

    buffer.writeln('# Comparison: ${comparison.topic}');
    buffer.writeln(
      'Created: ${comparison.created.toLocal().toString().split('.')[0]}',
    );
    buffer.writeln();

    // Standards compared
    final bookIds = comparison.snippets.map((s) => s.bookId).toSet();
    buffer.writeln('## Standards Compared');
    for (final bookId in bookIds) {
      buffer.writeln('- $bookId');
    }
    buffer.writeln();

    // Insights
    if (comparison.insights.similarities.isNotEmpty) {
      buffer.writeln('## Key Similarities');
      for (final similarity in comparison.insights.similarities) {
        buffer.writeln('- ${similarity.content}');
        if (similarity.rationale.isNotEmpty) {
          buffer.writeln('  ${similarity.rationale}');
        }
      }
      buffer.writeln();
    }

    if (comparison.insights.differences.isNotEmpty) {
      buffer.writeln('## Key Differences');
      for (final difference in comparison.insights.differences) {
        buffer.writeln('- ${difference.content}');
        if (difference.rationale.isNotEmpty) {
          buffer.writeln('  ${difference.rationale}');
        }
      }
      buffer.writeln();
    }

    if (comparison.insights.uniquePoints.isNotEmpty) {
      buffer.writeln('## Unique Points');
      for (final unique in comparison.insights.uniquePoints) {
        buffer.writeln('- ${unique.content}');
        if (unique.rationale.isNotEmpty) {
          buffer.writeln('  ${unique.rationale}');
        }
      }
      buffer.writeln();
    }

    // Overlap scores
    if (comparison.insights.overlapScores.isNotEmpty) {
      buffer.writeln('## Overlap Analysis');
      for (final entry in comparison.insights.overlapScores.entries) {
        final percentage = (entry.value * 100).toStringAsFixed(1);
        buffer.writeln('- ${entry.key}: ${percentage}% overlap');
      }
    }

    return buffer.toString();
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text('$count $label'),
      backgroundColor: color.withOpacity(0.1),
    );
  }
}
