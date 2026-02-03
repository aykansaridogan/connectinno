import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/note_service.dart';
import 'edit_note_screen.dart';

class NoteDetailScreen extends StatelessWidget {
  final String noteId;
  const NoteDetailScreen({super.key, required this.noteId});

  @override
  Widget build(BuildContext context) {
    final noteService = Provider.of<NoteService>(context);
    final note = noteService.getNoteById(noteId);
    if (note == null) {
      return Scaffold(appBar: AppBar(title: const Text('Note')), body: const Center(child: Text('Note not found')));
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Note'),
        actions: [
          IconButton(
            icon: Icon(note.pinned ? Icons.push_pin : Icons.push_pin_outlined),
            onPressed: () async => await noteService.togglePin(note.id),
          ),
          IconButton(
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
                await noteService.deleteNote(note.id);
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: const Text('Not silindi'),
                  action: SnackBarAction(label: 'Undo', onPressed: () async => await noteService.undoDelete()),
                ));
                Navigator.pop(context);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditNoteScreen(noteId: note.id))),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(note.title, style: Theme.of(context).textTheme.headline6),
            const SizedBox(height: 12),
            Text(note.content),
          ],
        ),
      ),
    );
  }
}
