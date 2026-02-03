import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/note.dart';
import '../repositories/note_repository.dart';

class NoteService extends ChangeNotifier {
  final NoteRepository _repo;
  bool _loading = false;

  NoteService([NoteRepository? repo]) : _repo = repo ?? NoteRepository();

  bool get isLoading => _loading;

  List<Note> get cachedNotes => _repo.getAllCached();

  List<Note> searchLocal({String? query, String filter = 'both'}) {
    return _repo.searchLocal(query: query, filter: filter);
  }

  Future<void> fetchBackendAndMerge({String? query, String filter = 'both'}) async {
    _loading = true;
    notifyListeners();
    try {
      await _repo.fetchBackend(query: query, filter: filter);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> syncAll() => fetchBackendAndMerge();

  Future<void> togglePin(String id) async {
    await _repo.togglePin(id);
    notifyListeners();
  }

  Future<void> deleteNote(String id) async {
    await _repo.delete(id);
    notifyListeners();
  }

  Future<void> undoDelete() async {
    await _repo.undoDelete();
    notifyListeners();
  }

  Future<Note> createNote({required String title, required String content, bool pinned = false}) async {
    final n = await _repo.createNote(title: title, content: content, pinned: pinned);
    notifyListeners();
    return n;
  }

  Future<void> updateNote(String id, {required String title, required String content, bool? pinned}) async {
    await _repo.updateNote(id, title: title, content: content, pinned: pinned);
    notifyListeners();
  }

  Note? getNoteById(String id) => _repo.getById(id);
}
