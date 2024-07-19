import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_intro/models/user_model.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  User? get currentUser => _auth.currentUser;

  // Kaydolma işlemi
  Future<String?> createUserWithEmailAndPassword(
      String email, String password, String name, String lastName) async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;

      if (user != null) {
        await _db.collection("users").doc(user.uid).set(
          {
            'firstName': name,
            'lastName': lastName,
            'email': email,
            'registerDate': DateTime.now()
          },
        );
      }

      return user?.uid;
    } catch (e) {
      debugPrint("Kaydolma hatası: $e");
      return null;
    }
  }

  // Giriş yapma işlemi
  Future<String?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = userCredential.user;
      return user?.uid;
    } catch (e) {
      debugPrint("Giriş hatası: $e");
      return null;
    }
  }

  // Çıkış yapma işlemi
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint("Çıkış hatası: $e");
    }
  }

  // Kullanıcı bilgilerini getirme
  Future<UserModel?> getUser() async {
    try {
      if (currentUser != null) {
        var userInfo =
            await _db.collection("users").doc(currentUser!.uid).get();
        var userJson = userInfo.data();
        return UserModel.fromMap(userJson!);
      }
    } catch (e) {
      debugPrint("Kullanıcı bilgisi getirme hatası: $e");
    }
    return null;
  }

  // Avatar yükleme
  Future<String?> uploadImage({required File selectedAvatar}) async {
    try {
      final avatarPath =
          _storage.ref().child("avatars").child("${currentUser!.uid}.jpg");
      await avatarPath.putFile(selectedAvatar);
      final url = await avatarPath.getDownloadURL();

      await _db
          .collection("users")
          .doc(currentUser!.uid)
          .update({'avatarUrl': url});

      return url;
    } catch (e) {
      debugPrint("Avatar yükleme hatası: $e");
      return null;
    }
  }
}
