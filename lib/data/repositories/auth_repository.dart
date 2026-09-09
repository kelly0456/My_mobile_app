import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_model.dart';

class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  String? _verificationId;

  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    required String phoneNumber,
    String role = 'customer',
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final firebaseUser = credential.user;
    if (firebaseUser == null) {
      throw Exception('Unable to create Firebase account.');
    }

    try {
      await firebaseUser.sendEmailVerification();
    } catch (e) {
      debugPrint('Failed to send verification email: $e');
    }

    final user = UserModel(
      uid: firebaseUser.uid,
      name: name.trim(),
      email: email.trim(),
      phoneNumber: phoneNumber.trim(),
      role: role,
      emailVerified: false,
      phoneVerified: false,
      createdAt: DateTime.now(),
    );

    try {
      await _firestore.collection('users').doc(firebaseUser.uid).set(user.toMap());
    } catch (e) {
      await firebaseUser.delete();
      rethrow;
    }
    return user;
  }

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final firebaseUser = credential.user;
      if (firebaseUser == null) throw Exception('Unable to login.');

      await firebaseUser.reload();
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('Authenticated user not found.');

      if (!currentUser.emailVerified) {
        await _auth.signOut();
        throw Exception('Please verify your email before logging in.');
      }

      final snapshot = await _firestore.collection('users').doc(currentUser.uid).get();
      if (!snapshot.exists) throw Exception('User profile does not exist in Firestore.');

      return UserModel.fromMap(snapshot.data()!);
    } on FirebaseAuthException catch (e) {
      debugPrint('LOGIN ERROR CODE: ${e.code}');
      rethrow;
    }
  }

  Future<void> sendPhoneVerificationCode({required String phoneNumber}) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber.trim(),
      verificationCompleted: (PhoneAuthCredential credential) async {
        try {
          await _auth.currentUser?.linkWithCredential(credential);
        } catch (e) {
          debugPrint('Auto-link failed: $e');
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        throw Exception(e.message ?? 'Phone verification failed.');
      },
      codeSent: (String verificationId, int? resendToken) {
        _verificationId = verificationId;
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  Future<void> verifyPhoneCode({required String smsCode}) async {
    if (_verificationId == null) {
      throw Exception('Verification session has expired.');
    }
    final credential = PhoneAuthProvider.credential(
      verificationId: _verificationId!,
      smsCode: smsCode.trim(),
    );
    final user = _auth.currentUser;
    if (user == null) throw Exception('No authenticated user found.');

    try {
      await user.linkWithCredential(credential);
      await _firestore.collection('users').doc(user.uid).update({
        'phoneVerified': true,
      });
      _verificationId = null;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Phone verification failed.');
    }
  }

  Future<void> resendVerificationEmail() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No authenticated user found.');
    await user.sendEmailVerification();
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<void> updateUserImage({required String uid, required String imageUrl}) async {
    await _firestore.collection('users').doc(uid).update({'userImage': imageUrl});
  }

  Future<String> uploadProfileImage({
    required String uid,
    required XFile imageFile,
  }) async {
    try {
      final ref = _storage.ref().child('user_images').child('$uid.jpg');
      final bytes = await imageFile.readAsBytes();
      await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      final url = await ref.getDownloadURL();
      return url;
    } catch (e) {
      throw Exception('Failed to upload profile image: $e');
    }
  }

  Future<void> forgotPassword({required String email}) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<UserModel?> getCurrentUser() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;
    await firebaseUser.reload();
    final currentUser = _auth.currentUser;
    if (currentUser == null || !currentUser.emailVerified) return null;

    final snapshot = await _firestore.collection('users').doc(currentUser.uid).get();
    if (!snapshot.exists || snapshot.data() == null) return null;

    return UserModel.fromMap(snapshot.data()!);
  }

  Stream<List<UserModel>> getUsers() {
    return _firestore
        .collection('users')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList();
    });
  }

  Future<void> updateUserRole({required String uid, required String role}) async {
    if (role != 'admin' && role != 'customer') throw Exception('Invalid user role.');
    await _firestore.collection('users').doc(uid).update({'role': role});
  }

  Future<void> deleteUserProfile(String uid) async {
    await _firestore.collection('users').doc(uid).delete();
  }
}
