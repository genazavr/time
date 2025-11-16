import '../models/note.dart';
import 'firebase_service.dart';

class NoteService {
  static final NoteService _instance = NoteService._internal();
  final _firebaseService = FirebaseService();

  factory NoteService() {
    return _instance;
  }

  NoteService._internal();

  Future<void> addNote(Note note) async {
    final user = _firebaseService.getCurrentUser();
    if (user != null) {
      final ref = _firebaseService.database.ref('users/${user.uid}/notes').push();
      await ref.set(note.toMap());
    }
  }

  Stream<List<Note>> getNotes() {
    final user = _firebaseService.getCurrentUser();
    if (user != null) {
      return _firebaseService.database
          .ref('users/${user.uid}/notes')
          .onValue
          .map((event) {
            if (event.snapshot.exists) {
              final notes = <Note>[];
              final data = event.snapshot.value as Map<dynamic, dynamic>;
              data.forEach((key, value) {
                notes.add(Note.fromMap(value, key));
              });
              return notes;
            }
            return [];
          });
    }
    return Stream.value([]);
  }

  Future<void> updateNote(Note updatedNote) async {
    final user = _firebaseService.getCurrentUser();
    if (user != null) {
      await _firebaseService.database
          .ref('users/${user.uid}/notes/${updatedNote.id}')
          .update(updatedNote.toMap());
    }
  }

  Future<void> deleteNote(String noteId) async {
    final user = _firebaseService.getCurrentUser();
    if (user != null) {
      await _firebaseService.database.ref('users/${user.uid}/notes/$noteId').remove();
    }
  }
}
