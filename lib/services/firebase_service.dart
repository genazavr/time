import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();

  factory FirebaseService() {
    return _instance;
  }

  FirebaseService._internal();

  late FirebaseAuth _auth;
  late FirebaseDatabase _database;

  FirebaseAuth get auth => _auth;
  FirebaseDatabase get database => _database;

  Future<void> initialize() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    _auth = FirebaseAuth.instance;
    _database = FirebaseDatabase.instance;
  }

  Future<UserCredential> register(String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> login(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  User? getCurrentUser() {
    return _auth.currentUser;
  }

  Future<void> saveUserData(String userId, Map<String, dynamic> data) async {
    await _database.ref('users/$userId').set(data);
  }

  Future<Map<dynamic, dynamic>?> getUserData(String userId) async {
    final snapshot = await _database.ref('users/$userId').get();
    if (snapshot.exists) {
      return snapshot.value as Map<dynamic, dynamic>;
    }
    return null;
  }
}
