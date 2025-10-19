import 'package:flutter/material.dart';

import '../services/topic_manager.dart';

enum TopicChipSize { small, medium, large }

enum TopicChipStyle { filled, outlined, tonal }

class TopicChip extends StatelessWidget {
  const TopicChip({
    super.key,
    required this.topic,
    required this.onTap,
    this.isSelected = false,
    this.size = TopicChipSize.medium,
    this.style = TopicChipStyle.tonal,
    this.showUsageCount = false,
    this.usageCount = 0,
  });

  final TopicConfiguration topic;
  final VoidCallback onTap;
  final bool isSelected;
  final TopicChipSize size;
  final TopicChipStyle style;
  final bool showUsageCount;
  final int usageCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Size configuration
    EdgeInsets padding;
    double fontSize;
    double iconSize;

    switch (size) {
      case TopicChipSize.small:
        padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4);
        fontSize = 12;
        iconSize = 14;
        break;
      case TopicChipSize.medium:
        padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
        fontSize = 14;
        iconSize = 16;
        break;
      case TopicChipSize.large:
        padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
        fontSize = 16;
        iconSize = 18;
        break;
    }

    // Style configuration
    Color backgroundColor;
    Color foregroundColor;
    Color borderColor;

    if (isSelected) {
      backgroundColor = theme.colorScheme.primary;
      foregroundColor = theme.colorScheme.onPrimary;
      borderColor = theme.colorScheme.primary;
    } else {
      switch (style) {
        case TopicChipStyle.filled:
          backgroundColor = theme.colorScheme.surfaceContainerHighest;
          foregroundColor = theme.colorScheme.onSurface;
          borderColor = Colors.transparent;
          break;
        case TopicChipStyle.outlined:
          backgroundColor = Colors.transparent;
          foregroundColor = theme.colorScheme.onSurface;
          borderColor = theme.colorScheme.outline;
          break;
        case TopicChipStyle.tonal:
          backgroundColor = theme.colorScheme.secondaryContainer.withValues(
            alpha: 0.5,
          );
          foregroundColor = theme.colorScheme.onSecondaryContainer;
          borderColor = Colors.transparent;
          break;
      }
    }

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border:
                borderColor != Colors.transparent
                    ? Border.all(color: borderColor, width: 1)
                    : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Custom topic indicator
              if (topic.isCustom) ...[
                Icon(Icons.star, size: iconSize, color: Colors.amber),
                const SizedBox(width: 4),
              ],

              // Topic name
              Flexible(
                child: Text(
                  topic.name,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: foregroundColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Usage count
              if (showUsageCount && usageCount > 0) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: foregroundColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    usageCount.toString(),
                    style: TextStyle(
                      fontSize: fontSize - 2,
                      fontWeight: FontWeight.w600,
                      color: foregroundColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class TopicChipGrid extends StatelessWidget {
  const TopicChipGrid({
    super.key,
    required this.topics,
    required this.onTopicTap,
    this.selectedTopic,
    this.usageStats = const {},
    this.showUsageCount = false,
    this.chipSize = TopicChipSize.medium,
    this.chipStyle = TopicChipStyle.tonal,
    this.spacing = 8,
    this.runSpacing = 8,
    this.maxLines,
  });

  final List<TopicConfiguration> topics;
  final ValueChanged<String> onTopicTap;
  final String? selectedTopic;
  final Map<String, int> usageStats;
  final bool showUsageCount;
  final TopicChipSize chipSize;
  final TopicChipStyle chipStyle;
  final double spacing;
  final double runSpacing;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    if (topics.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
      children:
          topics.map((topic) {
            final isSelected = selectedTopic == topic.name;
            final usageCount = usageStats[topic.name] ?? 0;

            return TopicChip(
              topic: topic,
              onTap: () => onTopicTap(topic.name),
              isSelected: isSelected,
              size: chipSize,
              style: chipStyle,
              showUsageCount: showUsageCount,
              usageCount: usageCount,
            );
          }).toList(),
    );
  }
}

class TopicChipSelector extends StatefulWidget {
  const TopicChipSelector({
    super.key,
    required this.topics,
    required this.onSelectionChanged,
    this.initialSelection,
    this.allowMultiple = false,
    this.chipSize = TopicChipSize.medium,
    this.chipStyle = TopicChipStyle.tonal,
  });

  final List<TopicConfiguration> topics;
  final ValueChanged<List<String>> onSelectionChanged;
  final List<String>? initialSelection;
  final bool allowMultiple;
  final TopicChipSize chipSize;
  final TopicChipStyle chipStyle;

  @override
  State<TopicChipSelector> createState() => _TopicChipSelectorState();
}

class _TopicChipSelectorState extends State<TopicChipSelector> {
  late Set<String> _selectedTopics;

  @override
  void initState() {
    super.initState();
    _selectedTopics = Set.from(widget.initialSelection ?? []);
  }

  void _toggleTopic(String topicName) {
    setState(() {
      if (_selectedTopics.contains(topicName)) {
        _selectedTopics.remove(topicName);
      } else {
        if (!widget.allowMultiple) {
          _selectedTopics.clear();
        }
        _selectedTopics.add(topicName);
      }
    });

    widget.onSelectionChanged(_selectedTopics.toList());
  }

  @override
  Widget build(BuildContext context) {
    return TopicChipGrid(
      topics: widget.topics,
      onTopicTap: _toggleTopic,
      selectedTopic: widget.allowMultiple ? null : _selectedTopics.firstOrNull,
      chipSize: widget.chipSize,
      chipStyle: widget.chipStyle,
    );
  }
}

class TopicSearchChips extends StatelessWidget {
  const TopicSearchChips({
    super.key,
    required this.searchQuery,
    required this.topics,
    required this.onTopicSelected,
    this.maxResults = 6,
  });

  final String searchQuery;
  final List<TopicConfiguration> topics;
  final ValueChanged<String> onTopicSelected;
  final int maxResults;

  @override
  Widget build(BuildContext context) {
    if (searchQuery.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    final filteredTopics =
        topics
            .where((topic) => topic.matchesQuery(searchQuery))
            .take(maxResults)
            .toList();

    if (filteredTopics.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Related Topics',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        TopicChipGrid(
          topics: filteredTopics,
          onTopicTap: onTopicSelected,
          chipSize: TopicChipSize.small,
          chipStyle: TopicChipStyle.outlined,
        ),
      ],
    );
  }
}
