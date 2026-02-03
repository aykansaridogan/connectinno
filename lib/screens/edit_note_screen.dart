import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/note_service.dart';

class EditNoteScreen extends StatefulWidget {
  final String noteId;
  const EditNoteScreen({super.key, required this.noteId});

  @override
  State<EditNoteScreen> createState() => _EditNoteScreenState();
}

class _EditNoteScreenState extends State<EditNoteScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  bool _pinned = false;

  @override
  void initState() {
    super.initState();
    final noteService = Provider.of<NoteService>(context, listen: false);
    final note = noteService.getNoteById(widget.noteId);
    _titleController = TextEditingController(text: note?.title ?? '');
    _contentController = TextEditingController(text: note?.content ?? '');
    _pinned = note?.pinned ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final noteService = Provider.of<NoteService>(context, listen: false);
    bool _saving = false;
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Note')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (v) => (v == null || v.isEmpty) ? 'Enter title' : null,
                enabled: !_saving,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: TextFormField(
                  controller: _contentController,
                  decoration: const InputDecoration(labelText: 'Content'),
                  maxLines: null,
                  expands: true,
                  validator: (v) => (v == null || v.isEmpty) ? 'Enter content' : null,
                  enabled: !_saving,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Checkbox(value: _pinned, onChanged: _saving ? null : (v) => setState(() => _pinned = v ?? false)),
                  const Text('Pin note'),
                  const Spacer(),
                  _saving
                      ? const SizedBox(width: 120, child: Center(child: CircularProgressIndicator()))
                      : ElevatedButton(
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              setState(() => _saving = true);
                              try {
                                await noteService.updateNote(widget.noteId, title: _titleController.text.trim(), content: _contentController.text.trim(), pinned: _pinned);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not kaydedildi')));
                                  Navigator.pop(context);
                                }
                              } catch (e) {
                                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
                              } finally {
                                if (mounted) setState(() => _saving = false);
                              }
                            }
                          },
                          child: const Text('Save'),
                        ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
