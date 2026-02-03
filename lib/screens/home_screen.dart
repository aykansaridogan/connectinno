import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../services/note_service.dart';
import '../models/note.dart';
import 'create_note_screen.dart';
import 'note_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  String _filter = 'both';
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(NoteService noteService) {
    // local results update happens via build using searchLocal
    // debounce backend fetch to avoid frequent calls
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      () async {
        await noteService.fetchBackendAndMerge(query: _searchController.text, filter: _filter);
      }();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final noteService = Provider.of<NoteService>(context);

    final List<Note> results = List.from(noteService.searchLocal(query: _searchController.text, filter: _filter));
    // pinned notes first
    results.sort((a, b) => (b.pinned ? 1 : 0) - (a.pinned ? 1 : 0));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes'),
        actions: [
          IconButton(
            tooltip: 'Sync backend',
            onPressed: noteService.isLoading ? null : () async => await noteService.syncAll(),
            icon: noteService.isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.sync),
          ),
          IconButton(
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Çıkış yap'),
                  content: const Text('Çıkış yapmak istediğinize emin misiniz?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('İptal')),
                    TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Evet')),
                  ],
                ),
              );
              if (ok == true) {
                await auth.logout();
                if (context.mounted) Navigator.pushReplacementNamed(context, '/login');
              }
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Hoşgeldiniz, ${auth.userEmail ?? 'Kullanıcı'}'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Ara notlarda... (başlık veya içerik)',
                    ),
                    onChanged: (_) => _onSearchChanged(noteService),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _filter,
                  items: const [
                    DropdownMenuItem(value: 'both', child: Text('Both')),
                    DropdownMenuItem(value: 'title', child: Text('Title')),
                    DropdownMenuItem(value: 'content', child: Text('Content')),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _filter = v);
                    _onSearchChanged(noteService);
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (noteService.isLoading) const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                const SizedBox(width: 8),
                Text('Gösteriliyor: ${results.length}'),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
                child: results.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Not bulunamadı'),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateNoteScreen())),
                            icon: const Icon(Icons.add),
                            label: const Text('Yeni Not Oluştur'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async => await noteService.syncAll(),
                      child: ListView.separated(
                        itemCount: results.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, i) {
                          final n = results[i];
                          return ListTile(
                            leading: n.pinned ? const Icon(Icons.push_pin, color: Colors.orange) : null,
                            title: Text(n.title),
                            subtitle: Text(n.content),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('${n.updatedAt.hour}:${n.updatedAt.minute.toString().padLeft(2, '0')}'),
                                IconButton(
                                  tooltip: n.pinned ? 'Unpin' : 'Pin',
                                  icon: Icon(n.pinned ? Icons.push_pin : Icons.push_pin_outlined),
                                  onPressed: () async => await noteService.togglePin(n.id),
                                ),
                                IconButton(
                                  tooltip: 'Delete',
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        title: const Text('Sil'),
                                        content: const Text('Bu notu silmek istediğinize emin misiniz?'),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('İptal')),
                                          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sil')),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      await noteService.deleteNote(n.id);
                                      ScaffoldMessenger.of(context).clearSnackBars();
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                        content: const Text('Not silindi'),
                                        action: SnackBarAction(label: 'Undo', onPressed: () async => await noteService.undoDelete()),
                                        duration: const Duration(seconds: 4),
                                      ));
                                    }
                                  },
                                ),
                              ],
                            ),
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NoteDetailScreen(noteId: n.id))),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateNoteScreen())),
        child: const Icon(Icons.add),
        tooltip: 'Create Note',
      ),
    );
  }
}
