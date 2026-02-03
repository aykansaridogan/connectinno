import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/note.dart';
import '../models/note_adapter.dart';

/// Repository: handles raw data storage and simulated backend using Hive for persistence.
class NoteRepository {
  late final Box _box;

  NoteRepository._create(this._box);

  /// Initialize Hive and open box. Call from `main` before runApp.
  static Future<NoteRepository> init() async {
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(NoteAdapter());
    final box = await Hive.openBox('notes');
    final repo = NoteRepository._create(box);

    // seed initial data if empty
    if (box.isEmpty) {
      final seed = [
        Note(id: '1', title: 'Alışveriş listesi', content: 'Süt, Ekmek, Yumurta'),
        Note(id: '2', title: 'Toplantı notları', content: 'Sprint planlama, görevler, zamanlama'),
        Note(id: '3', title: 'Öğrenme', content: 'Flutter provider ve state management'),
      ];
      for (var n in seed) {
        await box.put(n.id, n);
      }
    }
    return repo;
  }

  List<Note> getAllCached() => _box.values.cast<Note>().toList();

  Note? getById(String id) => _box.get(id) as Note?;

  List<Note> searchLocal({String? query, String filter = 'both'}) {
    final q = (query ?? '').trim().toLowerCase();
    final all = _box.values.cast<Note>().toList();
    if (q.isEmpty) return all;
    return all.where((n) {
      final t = n.title.toLowerCase();
      final c = n.content.toLowerCase();
      if (filter == 'title') return t.contains(q);
      if (filter == 'content') return c.contains(q);
      return t.contains(q) || c.contains(q);
    }).toList();
  }

  Future<List<Note>> fetchBackend({String? query, String filter = 'both'}) async {
    // Try fetching from Supabase first; fall back to local mock if something fails.
    try {
      final client = Supabase.instance.client;
      // build select query; if query provided, use ilike on title/content or use full-text on server
      final sb = client.from('notes').select();
      final res = await sb.execute();
      if (res.error != null) throw res.error!;
      final data = res.data as List<dynamic>;
      final fetched = data.map((d) {
        final map = Map<String, dynamic>.from(d as Map);
        return Note(
          id: map['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(),
          title: map['title']?.toString() ?? '',
          content: map['content']?.toString() ?? '',
          updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : DateTime.now(),
          pinned: map['pinned'] == true || map['pinned']?.toString() == 't',
        );
      }).toList();

      for (var nb in fetched) {
        if (!_box.values.cast<Note>().any((c) => c.id == nb.id)) {
          await _box.put(nb.id, nb);
        }
      }
      // Optionally filter fetched by query client-side for now
      if (query == null || query.trim().isEmpty) return fetched;
      final q = query.toLowerCase();
      return fetched.where((n) {
        final t = n.title.toLowerCase();
        final c = n.content.toLowerCase();
        if (filter == 'title') return t.contains(q);
        if (filter == 'content') return c.contains(q);
        return t.contains(q) || c.contains(q);
      }).toList();
    } catch (e) {
      // fallback to existing mock backend
      await Future.delayed(const Duration(seconds: 1));
      final backend = <Note>[
        Note(id: 'b1', title: 'Backend: Proje Planı', content: 'MVP, teslim tarihleri'),
        Note(id: 'b2', title: 'Backend: Fikirler', content: 'Yeni özellik önerileri'),
        Note(id: 'b3', title: 'Toplantı özet', content: 'Katılımcılar ve aksiyonlar'),
      ];

      final filtered = (query == null || query.trim().isEmpty)
          ? backend
          : backend.where((n) {
              final q = query.toLowerCase();
              if (filter == 'title') return n.title.toLowerCase().contains(q);
              if (filter == 'content') return n.content.toLowerCase().contains(q);
              return n.title.toLowerCase().contains(q) || n.content.toLowerCase().contains(q);
            }).toList();

      for (var nb in filtered) {
        if (!_box.values.cast<Note>().any((c) => c.id == nb.id)) {
          await _box.put(nb.id, nb);
        }
      }
      return filtered;
    }
  }

  Future<Note> createNote({required String title, required String content, bool pinned = false}) async {
    final client = Supabase.instance.client;
    try {
      final res = await client.from('notes').insert({
        'title': title,
        'content': content,
        'pinned': pinned,
      }).execute();
      if (res.error != null) throw res.error!;
      final data = (res.data as List).first as Map<String, dynamic>;
      final n = Note(
        id: data['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(),
        title: data['title']?.toString() ?? title,
        content: data['content']?.toString() ?? content,
        updatedAt: data['updated_at'] != null ? DateTime.parse(data['updated_at']) : DateTime.now(),
        pinned: data['pinned'] == true || data['pinned']?.toString() == 't',
      );
      await _box.put(n.id, n);
      return n;
    } catch (e) {
      // fallback to local create with generated id
      final id = DateTime.now().microsecondsSinceEpoch.toString();
      final n = Note(id: id, title: title, content: content, pinned: pinned);
      await _box.put(n.id, n);
      return n;
    }
  }

  Future<void> updateNote(String id, {required String title, required String content, bool? pinned}) async {
    final client = Supabase.instance.client;
    final old = _box.get(id) as Note?;
    if (old == null) return;
    try {
      final payload = {
        'title': title,
        'content': content,
      };
      if (pinned != null) payload['pinned'] = pinned;
      final res = await client.from('notes').update(payload).eq('id', id).execute();
      if (res.error != null) throw res.error!;
      final data = (res.data as List).first as Map<String, dynamic>;
      final updated = Note(
        id: data['id']?.toString() ?? id,
        title: data['title']?.toString() ?? title,
        content: data['content']?.toString() ?? content,
        updatedAt: data['updated_at'] != null ? DateTime.parse(data['updated_at']) : DateTime.now(),
        pinned: data['pinned'] == true || data['pinned']?.toString() == 't',
      );
      await _box.put(id, updated);
    } catch (e) {
      // fallback local update
      final updated = Note(id: id, title: title, content: content, updatedAt: DateTime.now(), pinned: pinned ?? old.pinned);
      await _box.put(id, updated);
    }
  }

  Future<void> togglePin(String id) async {
    final client = Supabase.instance.client;
    final n = _box.get(id) as Note?;
    if (n == null) return;
    final newPinned = !n.pinned;
    try {
      final res = await client.from('notes').update({'pinned': newPinned}).eq('id', id).execute();
      if (res.error != null) throw res.error!;
      final data = (res.data as List).first as Map<String, dynamic>;
      final updated = Note(
        id: data['id']?.toString() ?? id,
        title: data['title']?.toString() ?? n.title,
        content: data['content']?.toString() ?? n.content,
        updatedAt: data['updated_at'] != null ? DateTime.parse(data['updated_at']) : DateTime.now(),
        pinned: data['pinned'] == true || data['pinned']?.toString() == 't',
      );
      await _box.put(id, updated);
    } catch (e) {
      // fallback local toggle
      await _box.put(id, Note(id: n.id, title: n.title, content: n.content, updatedAt: n.updatedAt, pinned: newPinned));
    }
  }

  Note? _lastDeleted;
  String? _lastDeletedKey;

  Future<void> delete(String id) async {
    final client = Supabase.instance.client;
    final n = _box.get(id) as Note?;
    if (n == null) return;
    _lastDeleted = n;
    _lastDeletedKey = id;
    try {
      final res = await client.from('notes').delete().eq('id', id).execute();
      if (res.error != null) throw res.error!;
      await _box.delete(id);
    } catch (e) {
      // fallback local delete
      await _box.delete(id);
    }
  }

  Future<void> undoDelete() async {
    final client = Supabase.instance.client;
    if (_lastDeleted == null || _lastDeletedKey == null) return;
    final n = _lastDeleted!;
    try {
      final res = await client.from('notes').insert({
        'id': n.id,
        'title': n.title,
        'content': n.content,
        'pinned': n.pinned,
      }).execute();
      if (res.error != null) throw res.error!;
      await _box.put(n.id, n);
    } catch (e) {
      // fallback local restore
      await _box.put(n.id, n);
    }
    _lastDeleted = null;
    _lastDeletedKey = null;
  }
}
