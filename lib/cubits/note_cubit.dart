import 'package:bloc/bloc.dart';

import '../models/note.dart';
import '../services/note_service.dart';

class NoteState {
  final List<Note> notes;
  final bool isLoading;

  NoteState({required this.notes, this.isLoading = false});

  NoteState copyWith({List<Note>? notes, bool? isLoading}) => NoteState(notes: notes ?? this.notes, isLoading: isLoading ?? this.isLoading);
}

class NoteCubit extends Cubit<NoteState> {
  final NoteService _service;

  NoteCubit(this._service) : super(NoteState(notes: _service.cachedNotes, isLoading: _service.isLoading));

  void loadLocal({String query = '', String filter = 'both'}) {
    final res = _service.searchLocal(query: query, filter: filter);
    // ensure pinned sorting as UI expects
    res.sort((a, b) => (b.pinned ? 1 : 0) - (a.pinned ? 1 : 0));
    emit(state.copyWith(notes: res));
  }

  Future<void> fetchBackend({String? query, String filter = 'both'}) async {
    emit(state.copyWith(isLoading: true));
    await _service.fetchBackendAndMerge(query: query, filter: filter);
    final res = _service.searchLocal(query: query ?? '', filter: filter);
    res.sort((a, b) => (b.pinned ? 1 : 0) - (a.pinned ? 1 : 0));
    emit(state.copyWith(notes: res, isLoading: false));
  }
  Future<void> togglePin(String id) async {
    await _service.togglePin(id);
    loadLocal();
  }

  Future<void> deleteNote(String id) async {
    await _service.deleteNote(id);
    loadLocal();
  }

  Future<void> undoDelete() async {
    await _service.undoDelete();
    loadLocal();
  }

  Future<void> createNote({required String title, required String content, bool pinned = false}) async {
    await _service.createNote(title: title, content: content, pinned: pinned);
    loadLocal();
  }

  Future<void> updateNote(String id, {required String title, required String content, bool? pinned}) async {
    await _service.updateNote(id, title: title, content: content, pinned: pinned);
    loadLocal();
  }
}
