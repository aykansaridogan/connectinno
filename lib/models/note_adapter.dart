import 'package:hive/hive.dart';
import 'note.dart';

class NoteAdapter extends TypeAdapter<Note> {
  @override
  final int typeId = 0;

  @override
  Note read(BinaryReader reader) {
    final id = reader.readString();
    final title = reader.readString();
    final content = reader.readString();
    final updatedAt = DateTime.parse(reader.readString());
    final pinned = reader.readBool();
    return Note(id: id, title: title, content: content, updatedAt: updatedAt, pinned: pinned);
  }

  @override
  void write(BinaryWriter writer, Note obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.title);
    writer.writeString(obj.content);
    writer.writeString(obj.updatedAt.toIso8601String());
    writer.writeBool(obj.pinned);
  }
}
