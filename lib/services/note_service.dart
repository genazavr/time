import '../models/note_model.dart';
import 'firebase_service.dart';

class NoteService {
  static final NoteService _instance = NoteService._internal();
  final _firebaseService = FirebaseService();

  factory NoteService() {
    return _instance;
  }

  NoteService._internal();

  Future<void> addNote(String userId, NoteModel note) async {
    final ref = _firebaseService.database.ref('users/$userId/notes').push();
    await ref.set(note.toMap());
  }

  Future<List<NoteModel>> getNotes(String userId) async {
    final snapshot = await _firebaseService.database.ref('users/$userId/notes').get();
    if (snapshot.exists) {
      final notes = <NoteModel>[];
      final data = snapshot.value as Map<dynamic, dynamic>;
      data.forEach((key, value) {
        notes.add(NoteModel.fromMap(value, key, userId));
      });
      return notes;
    }
    return [];
  }

  Future<void> updateNote(String userId, String noteId, NoteModel note) async {
    await _firebaseService.database
        .ref('users/$userId/notes/$noteId')
        .update(note.toMap());
  }

  Future<void> deleteNote(String userId, String noteId) async {
    await _firebaseService.database.ref('users/$userId/notes/$noteId').remove();
  }

  Stream<List<NoteModel>> watchNotes(String userId) {
    return _firebaseService.database
        .ref('users/$userId/notes')
        .onValue
        .map((event) {
          if (event.snapshot.exists) {
            final notes = <NoteModel>[];
            final data = event.snapshot.value as Map<dynamic, dynamic>;
            data.forEach((key, value) {
              notes.add(NoteModel.fromMap(value, key, userId));
            });
            return notes;
          }
          return [];
        });
  }
}
