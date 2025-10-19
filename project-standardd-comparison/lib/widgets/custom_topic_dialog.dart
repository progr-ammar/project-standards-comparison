import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/topic_provider.dart';

class CustomTopicDialog extends StatefulWidget {
  const CustomTopicDialog({super.key});

  @override
  State<CustomTopicDialog> createState() => _CustomTopicDialogState();
}

class _CustomTopicDialogState extends State<CustomTopicDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _keywordsController = TextEditingController();
  final _synonymsController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _keywordsController.dispose();
    _synonymsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Custom Topic'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Topic Name',
                  hintText: 'e.g., Agile Risk Management',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a topic name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Brief description of the topic',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _keywordsController,
                decoration: const InputDecoration(
                  labelText: 'Keywords',
                  hintText: 'Comma-separated keywords',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter at least one keyword';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _synonymsController,
                decoration: const InputDecoration(
                  labelText: 'Synonyms (optional)',
                  hintText: 'Comma-separated synonyms',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _createTopic, child: const Text('Create')),
      ],
    );
  }

  Future<void> _createTopic() async {
    if (!_formKey.currentState!.validate()) return;

    final topicProvider = context.read<TopicProvider>();

    final keywords =
        _keywordsController.text
            .split(',')
            .map((k) => k.trim())
            .where((k) => k.isNotEmpty)
            .toList();

    final synonyms =
        _synonymsController.text
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();

    try {
      final success = await topicProvider.createCustomTopic(
        name: _nameController.text.trim(),
        keywords: keywords,
        synonyms: synonyms,
        description: _descriptionController.text.trim(),
      );

      if (mounted) {
        if (success) {
          Navigator.of(context).pop(true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                topicProvider.lastError ?? 'Failed to create topic',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating topic: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class CustomTopicManagementScreen extends StatelessWidget {
  const CustomTopicManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Custom Topics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await showDialog<bool>(
                context: context,
                builder: (context) => const CustomTopicDialog(),
              );

              if (result == true && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Custom topic created successfully'),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: Consumer<TopicProvider>(
        builder: (context, topicProvider, child) {
          final customTopics = topicProvider.customTopics;

          if (customTopics.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.topic, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No custom topics yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Create custom topics to organize your comparisons',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: customTopics.length,
            itemBuilder: (context, index) {
              final topic = customTopics[index];

              return ListTile(
                leading: const Icon(Icons.star, color: Colors.amber),
                title: Text(topic.name),
                subtitle: Text(
                  topic.description.isNotEmpty
                      ? topic.description
                      : 'Keywords: ${topic.keywords.join(', ')}',
                ),
                trailing: PopupMenuButton(
                  itemBuilder:
                      (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit),
                              SizedBox(width: 8),
                              Text('Edit'),
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
                      case 'edit':
                        // TODO: Implement edit functionality
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Edit functionality coming soon'),
                          ),
                        );
                        break;
                      case 'delete':
                        _deleteTopic(context, topic.name);
                        break;
                    }
                  },
                ),
                onTap: () {
                  topicProvider.selectTopic(topic.name);
                  Navigator.of(context).pop();
                },
              );
            },
          );
        },
      ),
    );
  }

  void _deleteTopic(BuildContext context, String topicName) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Topic'),
            content: Text('Are you sure you want to delete "$topicName"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final topicProvider = context.read<TopicProvider>();
                  await topicProvider.deleteCustomTopic(topicName);

                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Topic deleted successfully'),
                      ),
                    );
                  }
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
}
