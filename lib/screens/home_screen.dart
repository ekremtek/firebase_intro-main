import 'dart:io';

import 'package:firebase_intro/models/user_model.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_intro/services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  File? _selectedAvatar;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    _requestNotificationPermissions();
    super.initState();
  }

  void _openImagePicker() async {
    final image = await ImagePicker().pickImage(source: ImageSource.camera);

    if (image != null) {
      setState(() {
        _selectedAvatar = File(image.path);
      });
    }
  }

  Future<UserModel?> _getUser() async {
    try {
      return await _authService.getUser();
    } catch (e) {
      debugPrint("Kullanıcı bilgisi alma hatası: $e");
      return null;
    }
  }

  void _uploadImage() async {
    try {
      if (_selectedAvatar != null) {
        String? url = await _authService.uploadImage(selectedAvatar: _selectedAvatar!);
        if (url != null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Avatar başarıyla yüklendi."),
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Avatar yüklenirken bir hata oluştu."),
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint("Avatar yükleme hatası: $e");
    }
  }

  void _signOut() async {
    try {
      await _authService.signOut();
    } catch (e) {
      debugPrint("Çıkış işlemi hatası: $e");
    }
  }

  void _requestNotificationPermissions() async {
    // FCM Token
    FirebaseMessaging fcm = FirebaseMessaging.instance;
    final permission = await fcm.requestPermission();

    if (permission.authorizationStatus == AuthorizationStatus.authorized) {
      // FCM Token
      final token = await fcm.getToken();

      // kullanıcı hangi grupta?

      await fcm.subscribeToTopic("mobil1a");

      fcm.onTokenRefresh.listen((token) {
        // update token in db.
      });

      debugPrint("Firebase Token: $token");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Firebase App"),
        actions: [IconButton(onPressed: _signOut, icon: const Icon(Icons.logout))],
      ),
      body: Center(
        child: FutureBuilder(
          future: _getUser(),
          builder: (context, AsyncSnapshot<UserModel?> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Text("Hata: ${snapshot.error}");
            } else if (!snapshot.hasData || snapshot.data == null) {
              return const Text("Veri bulunamadı.");
            } else {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    foregroundImage: _selectedAvatar != null
                        ? FileImage(_selectedAvatar!)
                        : snapshot.data!.avatarUrl != null
                            ? NetworkImage(snapshot.data!.avatarUrl!) as ImageProvider<Object>?
                            : null,
                    backgroundColor:
                        _selectedAvatar == null && snapshot.data!.avatarUrl == null ? Colors.deepOrange : null,
                    radius: 40,
                  ),
                  IconButton(
                    onPressed: () {
                      _openImagePicker();
                    },
                    icon:
                        Icon((_selectedAvatar != null || snapshot.data!.avatarUrl != null) ? Icons.update : Icons.add),
                  ),
                  if (_selectedAvatar != null)
                    TextButton(
                      onPressed: () {
                        _uploadImage();
                      },
                      child: const Text("Yükle"),
                    ),
                  Text(
                    "Hoşgeldiniz ${snapshot.data!.firstName} ${snapshot.data!.lastName}",
                  ),
                ],
              );
            }
          },
        ),
      ),
    );
  }
}
