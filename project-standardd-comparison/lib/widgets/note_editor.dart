import 'package:flutter/material.dart';

class NoteEditor extends StatefulWidget {
  const NoteEditor({
    super.key,
    required this.initialText,
    required this.onSave,
    this.title = 'Edit Note',
    this.hintText = 'Enter your notes...',
  });

  final String initialText;
  final Function(String) onSave;
  final String title;
  final String hintText;

  @override
  State<NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends State<NoteEditor> {
  late final TextEditingController _controller;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasChanges = _controller.text != widget.initialText;
    if (hasChanges != _hasChanges) {
      setState(() {
        _hasChanges = hasChanges;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 500,
        height: 400,
        child: Column(
          children: [
            // Toolbar
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.format_bold),
                      onPressed: () => _insertFormatting('**', '**'),
                      tooltip: 'Bold',
                    ),
                    IconButton(
                      icon: const Icon(Icons.format_italic),
                      onPressed: () => _insertFormatting('*', '*'),
                      tooltip: 'Italic',
                    ),
                    IconButton(
                      icon: const Icon(Icons.format_list_bulleted),
                      onPressed: () => _insertFormatting('- ', ''),
                      tooltip: 'Bullet point',
                    ),
                    IconButton(
                      icon: const Icon(Icons.format_list_numbered),
                      onPressed: () => _insertFormatting('1. ', ''),
                      tooltip: 'Numbered list',
                    ),
                    const Spacer(),
                    Text(
                      '${_controller.text.length} characters',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Text editor
            Expanded(
              child: TextField(
                controller: _controller,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.all(16),
                ),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),

            // Preview section (if text contains markdown-like formatting)
            if (_controller.text.contains('**') ||
                _controller.text.contains('*') ||
                _controller.text.contains('- '))
              Column(
                children: [
                  const SizedBox(height: 8),
                  ExpansionTile(
                    title: const Text('Preview'),
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceVariant.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _formatPreviewText(_controller.text),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed:
              _hasChanges || widget.initialText.isEmpty
                  ? () {
                    widget.onSave(_controller.text);
                    Navigator.of(context).pop();
                  }
                  : null,
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _insertFormatting(String before, String after) {
    final selection = _controller.selection;
    final text = _controller.text;

    if (selection.isValid) {
      final selectedText = text.substring(selection.start, selection.end);
      final newText = text.replaceRange(
        selection.start,
        selection.end,
        '$before$selectedText$after',
      );

      _controller.text = newText;
      _controller.selection = TextSelection.collapsed(
        offset:
            selection.start +
            before.length +
            selectedText.length +
            after.length,
      );
    } else {
      final cursorPos = _controller.selection.baseOffset;
      final newText =
          text.substring(0, cursorPos) +
          before +
          after +
          text.substring(cursorPos);

      _controller.text = newText;
      _controller.selection = TextSelection.collapsed(
        offset: cursorPos + before.length,
      );
    }
  }

  String _formatPreviewText(String text) {
    // Simple markdown-like preview formatting
    String formatted = text;

    // Bold text
    formatted = formatted.replaceAllMapped(
      RegExp(r'\*\*(.*?)\*\*'),
      (match) => '[BOLD]${match.group(1)}[/BOLD]',
    );

    // Italic text
    formatted = formatted.replaceAllMapped(
      RegExp(r'\*(.*?)\*'),
      (match) => '[ITALIC]${match.group(1)}[/ITALIC]',
    );

    return formatted;
  }
}

class QuickNoteWidget extends StatelessWidget {
  const QuickNoteWidget({
    super.key,
    required this.note,
    required this.onEdit,
    this.maxLines = 3,
  });

  final String note;
  final VoidCallback onEdit;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    if (note.isEmpty) {
      return InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
              style: BorderStyle.solid,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.note_add,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Add a note...',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return InkWell(
      onTap: onEdit,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.secondaryContainer.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.note,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text('Note', style: Theme.of(context).textTheme.labelSmall),
                const Spacer(),
                Icon(
                  Icons.edit,
                  size: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              note,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
