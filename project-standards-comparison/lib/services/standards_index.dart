import 'dart:async';
import 'dart:math';

import 'package:flutter/services.dart' show rootBundle;
import 'package:syncfusion_flutter_pdf/pdf.dart';

class TocEntry {
  TocEntry({required this.title, required this.page, required this.level});
  final String title;
  final int page; // 1-based
  final int level; // 0 = root
}

class StandardsIndexService {
  StandardsIndexService();

  final Map<String, PdfDocument> _bookIdToDoc = {};
  final Map<String, List<TocEntry>> _bookIdToToc = {};

  static const String pmbokId = 'pmbok7';
  static const String prince2Id = 'prince2';
  static const String isoId = 'iso21502';

  Future<void> loadAll() async {
    // No-op: we lazily load per book to avoid UI stalls.
  }

  Future<void> _loadBook(String bookId, String assetPath) async {
    final data = await rootBundle.load(assetPath);
    final bytes = data.buffer.asUint8List();
    final doc = PdfDocument(inputBytes: bytes);
    _bookIdToDoc[bookId] = doc;
    _bookIdToToc[bookId] = _extractToc(doc);
  }

  String? _assetPathFor(String bookId) {
    switch (bookId) {
      case pmbokId:
        return 'assets/pmbok7.pdf';
      case prince2Id:
        return 'assets/prince2.pdf';
      case isoId:
        return 'assets/iso21502.pdf';
      default:
        return null;
    }
  }

  Future<void> _ensureLoaded(String bookId) async {
    if (_bookIdToDoc.containsKey(bookId)) return;
    final path = _assetPathFor(bookId);
    if (path != null) {
      await _loadBook(bookId, path);
    }
  }

  List<TocEntry> getIndex(String bookId) {
    // Synchronous snapshot; caller can trigger ensure if needed
    return List.unmodifiable(_bookIdToToc[bookId] ?? const <TocEntry>[]);
  }

  List<String> getAllTopics() {
    final set = <String>{};
    for (final list in _bookIdToToc.values) {
      for (final e in list) {
        final t = _normalizeTitle(e.title);
        if (t.length >= 3) set.add(t);
      }
    }
    return set.toList()..sort();
  }

  Map<String, int?> mapTopicToPages(String topic) {
    final norm = _normalizeTitle(topic);
    return {
      pmbokId: _bestMatchPage(pmbokId, norm),
      prince2Id: _bestMatchPage(prince2Id, norm),
      isoId: _bestMatchPage(isoId, norm),
    };
  }

  Map<String, String> extractTextAroundPages(
    Map<String, int?> pages, {
    int radius = 1,
  }) {
    final result = <String, String>{};
    pages.forEach((bookId, page) {
      if (page == null) return;
      final doc = _bookIdToDoc[bookId];
      if (doc == null) return;
      final extractor = PdfTextExtractor(doc);
      final start = max(1, page - radius);
      final end = min(doc.pages.count, page + radius);
      final buffer = StringBuffer();
      for (int p = start; p <= end; p++) {
        try {
          buffer.writeln(
            extractor.extractText(startPageIndex: p - 1, endPageIndex: p - 1),
          );
        } catch (_) {
          // ignore extraction errors for individual pages
        }
      }
      result[bookId] = buffer.toString();
    });
    return result;
  }

  int? findIndexPage(String bookId) {
    // 1) Try TOC bookmark titled 'Index'
    final toc = _bookIdToToc[bookId] ?? const <TocEntry>[];
    for (final e in toc.reversed) {
      if (e.title.toLowerCase().contains('index')) {
        return e.page;
      }
    }
    // 2) Fallback: scan last 50 pages (or last 20% if smaller) for heading 'Index'
    final doc = _bookIdToDoc[bookId];
    if (doc == null) return null;
    final extractor = PdfTextExtractor(doc);
    final total = doc.pages.count;
    final scanCount = total <= 50 ? total : (total * 0.2).floor().clamp(1, 50);
    final start = (total - scanCount + 1).clamp(1, total);
    for (int p = start; p <= total; p++) {
      try {
        final text = extractor.extractText(
          startPageIndex: p - 1,
          endPageIndex: p - 1,
        );
        final head = text
            .trimLeft()
            .split(RegExp(r'\n|\r'))
            .firstWhere((s) => s.trim().isNotEmpty, orElse: () => '');
        if (head.toLowerCase().startsWith('index')) {
          return p;
        }
      } catch (_) {}
    }
    return null;
  }

  int? findTocPage(String bookId) {
    // Attempt fast load to avoid delays if needed later
    _ensureLoaded(bookId);
    // Fast overrides based on your copies
    if (bookId == pmbokId) return 18; // PMBOK 7
    if (bookId == prince2Id) return 4; // PRINCE2 (7th)
    if (bookId == isoId) return 3; // ISO 21502
    // Try TOC bookmark titled 'Contents' or 'Table of Contents'
    final toc = _bookIdToToc[bookId] ?? const <TocEntry>[];
    for (final e in toc) {
      final t = e.title.toLowerCase();
      if (t.contains('table of contents') || t == 'contents') {
        return e.page;
      }
    }
    // Fallback: scan first 25 pages for a heading 'Contents' or 'Table of Contents'
    final doc = _bookIdToDoc[bookId];
    if (doc == null) return null;
    final extractor = PdfTextExtractor(doc);
    final total = doc.pages.count;
    final end = total < 25 ? total : 25;
    for (int p = 1; p <= end; p++) {
      try {
        final text = extractor.extractText(
          startPageIndex: p - 1,
          endPageIndex: p - 1,
        );
        final head = text
            .trimLeft()
            .split(RegExp(r'\n|\r'))
            .firstWhere((s) => s.trim().isNotEmpty, orElse: () => '');
        final h = head.toLowerCase();
        if (h.startsWith('table of contents') || h == 'contents') {
          return p;
        }
      } catch (_) {}
    }
    return null;
  }

  Map<String, dynamic> computeInsights(Map<String, String> bookToText) {
    final Map<String, Set<String>> tokens = {
      for (final e in bookToText.entries) e.key: _tokenize(e.value),
    };
    final common = _intersectionAll(tokens.values.toList()).toList();
    common.sort();

    List<String> diffs(String a, String b) {
      final setA = tokens[a];
      final setB = tokens[b];
      if (setA == null || setB == null) return const <String>[];
      final onlyA = setA.difference(setB);
      return onlyA.take(10).toList();
    }

    List<String> uniques(String key, List<String> othersKeys) {
      final set = tokens[key];
      if (set == null) return const <String>[];
      final others = <String>{};
      for (final k in othersKeys) {
        final s = tokens[k];
        if (s != null) others.addAll(s);
      }
      final uniq = set.difference(others);
      return uniq.take(10).toList();
    }

    final similarities =
        common.take(10).map((e) => e.replaceAll('_', ' ')).toList();

    final differences = <String>[];
    if (tokens.containsKey(pmbokId) && tokens.containsKey(prince2Id)) {
      differences.addAll(
        diffs(pmbokId, prince2Id).map((e) => 'PMBOK vs PRINCE2: $e'),
      );
    }
    if (tokens.containsKey(pmbokId) && tokens.containsKey(isoId)) {
      differences.addAll(diffs(pmbokId, isoId).map((e) => 'PMBOK vs ISO: $e'));
    }
    if (tokens.containsKey(prince2Id) && tokens.containsKey(isoId)) {
      differences.addAll(
        diffs(prince2Id, isoId).map((e) => 'PRINCE2 vs ISO: $e'),
      );
    }

    final unique = <String, List<String>>{};
    if (tokens.containsKey(pmbokId)) {
      unique['PMBOK'] =
          uniques(pmbokId, [
            prince2Id,
            isoId,
          ]).map((e) => e.replaceAll('_', ' ')).toList();
    }
    if (tokens.containsKey(prince2Id)) {
      unique['PRINCE2'] =
          uniques(prince2Id, [
            pmbokId,
            isoId,
          ]).map((e) => e.replaceAll('_', ' ')).toList();
    }
    if (tokens.containsKey(isoId)) {
      unique['ISO'] =
          uniques(isoId, [
            pmbokId,
            prince2Id,
          ]).map((e) => e.replaceAll('_', ' ')).toList();
    }

    return {
      'Similarities': similarities,
      'Differences': differences.take(12).toList(),
      'Unique': unique,
    };
  }

  // Helpers
  List<TocEntry> _extractToc(PdfDocument doc) {
    final result = <TocEntry>[];
    void walk(dynamic collection, int level) {
      if (collection == null) return;
      try {
        final int count = collection.count as int;
        for (int i = 0; i < count; i++) {
          final item = collection[i];
          int pageNumber = 1;
          try {
            final dest = item.destination;
            final page = dest?.page;
            final idx = page?.index as int?;
            pageNumber = (idx ?? 0) + 1;
          } catch (_) {}
          final title = (item.title?.toString() ?? '').trim();
          if (title.isNotEmpty) {
            result.add(TocEntry(title: title, page: pageNumber, level: level));
          }
          walk(item.nested, level + 1);
        }
      } catch (_) {
        // ignore unexpected shapes
      }
    }

    try {
      walk(doc.bookmarks, 0);
    } catch (_) {
      // some PDFs may not expose bookmarks; ignore
    }
    return result;
  }

  int? _bestMatchPage(String bookId, String normTopic) {
    final toc = _bookIdToToc[bookId];
    if (toc == null || toc.isEmpty) return null;
    int? bestPage;
    double bestScore = -1;
    for (final e in toc) {
      final s = _similarity(_normalizeTitle(e.title), normTopic);
      if (s > bestScore) {
        bestScore = s;
        bestPage = e.page;
      }
    }
    return bestPage;
  }

  String _normalizeTitle(String s) {
    final t =
        s
            .toLowerCase()
            .replaceAll(RegExp(r'[^a-z0-9 ]+'), ' ')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
    return t;
  }

  double _similarity(String a, String b) {
    final ta = a.split(' ').where((e) => e.isNotEmpty).toSet();
    final tb = b.split(' ').where((e) => e.isNotEmpty).toSet();
    if (ta.isEmpty || tb.isEmpty) return 0;
    final inter = ta.intersection(tb).length.toDouble();
    final union = ta.union(tb).length.toDouble();
    return inter / union;
  }

  final Set<String> _stop = {
    'the',
    'and',
    'of',
    'to',
    'a',
    'in',
    'for',
    'on',
    'by',
    'with',
    'is',
    'are',
    'as',
    'an',
    'that',
    'this',
    'from',
    'at',
    'it',
    'be',
    'or',
    'into',
    'within',
    'through',
    'using',
    'use',
  };

  Set<String> _tokenize(String text) {
    final words =
        text
            .toLowerCase()
            .replaceAll(RegExp(r'[^a-z0-9 ]+'), ' ')
            .split(RegExp(r'\s+'))
            .where((w) => w.length >= 3 && !_stop.contains(w))
            .toList();
    final freq = <String, int>{};
    for (final w in words) {
      freq[w] = (freq[w] ?? 0) + 1;
    }
    final sorted =
        freq.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(100).map((e) => e.key).toSet();
  }

  Set<String> _intersectionAll(List<Set<String>> sets) {
    if (sets.isEmpty) return <String>{};
    var inter = sets.first.toSet();
    for (int i = 1; i < sets.length; i++) {
      inter = inter.intersection(sets[i]);
    }
    return inter;
  }
}
