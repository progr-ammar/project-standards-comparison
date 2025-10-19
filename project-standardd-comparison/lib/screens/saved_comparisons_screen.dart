import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/comparison_provider.dart';
import '../widgets/visual_feedback_helper.dart';

class SavedComparisonsScreen extends StatelessWidget {
  const SavedComparisonsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Comparisons'),
        actions: [
          Consumer<ComparisonProvider>(
            builder: (context, provider, child) {
              if (provider.savedComparisons.isEmpty) {
                return const SizedBox.shrink();
              }

              return PopupMenuButton(
                itemBuilder:
                    (context) => [
                      const PopupMenuItem(
                        value: 'clear_all',
                        child: Row(
                          children: [
                            Icon(Icons.clear_all, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Clear All'),
                          ],
                        ),
                      ),
                    ],
                onSelected: (value) {
                  if (value == 'clear_all') {
                    _showClearAllDialog(context);
                  }
                },
              );
            },
          ),
        ],
      ),
      body: Consumer<ComparisonProvider>(
        builder: (context, provider, child) {
          final comparisons =
              provider.savedComparisons.values.toList()
                ..sort((a, b) => b.created.compareTo(a.created));

          if (comparisons.isEmpty) {
            return VisualFeedbackHelper.emptyState(
              title: 'No Saved Comparisons',
              subtitle:
                  'Create comparisons from the Compare tab to see them here',
              icon: Icons.compare_arrows,
              action: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.compare_arrows),
                label: const Text('Start Comparing'),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: comparisons.length,
            itemBuilder: (context, index) {
              final comparison = comparisons[index];

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(
                    comparison.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('Topic: ${comparison.topic}'),
                      const SizedBox(height: 4),
                      Text(
                        'Created: ${_formatDate(comparison.created)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          _buildInfoChip(
                            context,
                            '${comparison.snippets.length} snippets',
                            Icons.text_snippet,
                          ),
                          _buildInfoChip(
                            context,
                            '${comparison.insights.similarities.length} similarities',
                            Icons.check_circle,
                          ),
                          _buildInfoChip(
                            context,
                            '${comparison.insights.differences.length} differences',
                            Icons.compare,
                          ),
                        ],
                      ),
                      if (comparison.tags.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children:
                              comparison.tags.map((tag) {
                                return Chip(
                                  label: Text(tag),
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                );
                              }).toList(),
                        ),
                      ],
                    ],
                  ),
                  trailing: PopupMenuButton(
                    itemBuilder:
                        (context) => [
                          const PopupMenuItem(
                            value: 'view',
                            child: Row(
                              children: [
                                Icon(Icons.visibility),
                                SizedBox(width: 8),
                                Text('View'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'export',
                            child: Row(
                              children: [
                                Icon(Icons.download),
                                SizedBox(width: 8),
                                Text('Export'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Delete'),
                              ],
                            ),
                          ),
                        ],
                    onSelected: (value) {
                      switch (value) {
                        case 'view':
                          _viewComparison(context, comparison);
                          break;
                        case 'export':
                          _exportComparison(context, comparison);
                          break;
                        case 'delete':
                          _deleteComparison(context, comparison);
                          break;
                      }
                    },
                  ),
                  onTap: () => _viewComparison(context, comparison),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildInfoChip(BuildContext context, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  void _viewComparison(BuildContext context, Comparison comparison) {
    // TODO: Navigate to comparison view or set as current comparison
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Viewing comparison: ${comparison.name}')),
    );
    Navigator.of(context).pop();
  }

  void _exportComparison(BuildContext context, Comparison comparison) {
    // TODO: Implement export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export functionality coming soon')),
    );
  }

  void _deleteComparison(BuildContext context, Comparison comparison) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Comparison'),
            content: Text(
              'Are you sure you want to delete "${comparison.name}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  context.read<ComparisonProvider>().deleteComparison(
                    comparison.id,
                  );
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Comparison deleted')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  void _showClearAllDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Clear All Comparisons'),
            content: const Text(
              'Are you sure you want to delete all saved comparisons? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final provider = context.read<ComparisonProvider>();
                  final comparisons = provider.savedComparisons.keys.toList();
                  for (final id in comparisons) {
                    provider.deleteComparison(id);
                  }
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('All comparisons cleared')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Clear All'),
              ),
            ],
          ),
    );
  }
}
