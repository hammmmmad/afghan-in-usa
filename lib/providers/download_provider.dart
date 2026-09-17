import 'package:flutter/material.dart';

import '../services/storage_service.dart';

/// Keeps the per-document download counters and in-flight progress.
class DownloadProvider extends ChangeNotifier {
  DownloadProvider() {
    _counts = StorageService.instance.downloadCounts;
  }

  Map<String, int> _counts = <String, int>{};
  final Map<String, double> _progress = <String, double>{};

  int countFor(String documentId) => _counts[documentId] ?? 0;
  double? progressFor(String documentId) => _progress[documentId];
  bool isBusy(String documentId) => _progress.containsKey(documentId);

  void setProgress(String documentId, double value) {
    _progress[documentId] = value.clamp(0.0, 1.0);
    notifyListeners();
  }

  void clearProgress(String documentId) {
    _progress.remove(documentId);
    notifyListeners();
  }

  Future<void> bump(String documentId) async {
    final int next = await StorageService.instance.bumpDownload(documentId);
    _counts = Map<String, int>.from(_counts)..[documentId] = next;
    notifyListeners();
  }
}
