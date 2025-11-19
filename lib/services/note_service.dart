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
            final notes = <Note>[];
            try {
              if (event.snapshot.exists && event.snapshot.value != null) {
                final data = event.snapshot.value;
                if (data is Map) {
                  data.forEach((key, value) {
                    try {
                      if (value is Map) {
                        notes.add(Note.fromMap(value as Map<dynamic, dynamic>, key.toString()));
                      }
                    } catch (e) {
                      print('Error parsing note $key: $e');
                    }
                  });
                }
              }
            } catch (e) {
              print('Error loading notes: $e');
            }
            return notes..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          });
    }
    return Stream.value([]);
  }

  Future<void> updateNote(Note updatedNote) async {
    final user = _firebaseService.getCurrentUser();
    if (user != null) {
      await _firebaseService.database
          .ref('users/${user.uid}/notes/${updatedNote.id}')
          .set(updatedNote.toMap());
    }
  }

  Future<void> deleteNote(String noteId) async {
    final user = _firebaseService.getCurrentUser();
    if (user != null) {
      await _firebaseService.database.ref('users/${user.uid}/notes/$noteId').remove();
    }
  }
}
