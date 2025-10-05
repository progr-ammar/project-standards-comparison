import 'package:flutter/material.dart';

import '../services/standards_index.dart';

class IndexProvider extends ChangeNotifier {
  IndexProvider();

  final StandardsIndexService _service = StandardsIndexService();
  bool _ready = false;
  bool get ready => _ready;

  Future<void> init() async {
    await _service.loadAll();
    _ready = true;
    notifyListeners();
  }

  List<TocEntry> getIndex(String bookId) => _service.getIndex(bookId);
  List<String> getAllTopics() => _service.getAllTopics();
  Map<String, int?> mapTopicToPages(String topic) =>
      _service.mapTopicToPages(topic);
  Map<String, String> extractTextAroundPages(
    Map<String, int?> pages, {
    int radius = 1,
  }) => _service.extractTextAroundPages(pages, radius: radius);
  Map<String, dynamic> computeInsights(Map<String, String> bookToText) =>
      _service.computeInsights(bookToText);
  int? findIndexPage(String bookId) => _service.findIndexPage(bookId);
  int? findTocPage(String bookId) => _service.findTocPage(bookId);
}
