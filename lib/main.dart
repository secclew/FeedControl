import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';
import 'auth/login_page.dart';
import 'pages/feed_page.dart';
import 'pages/interesses_page.dart'; // ✅ importa a tela de interesses

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const FeedControlApp());
}

class FeedControlApp extends StatelessWidget {
  const FeedControlApp({super.key});

  Future<bool> _temInteresses(String uid) async {
    final doc = await FirebaseFirestore.instance.collection("users").doc(uid).get();
    if (!doc.exists) return false;
    final data = doc.data();
    if (data == null) return false;
    return (data["interesses"] != null && (data["interesses"] as List).isNotEmpty);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FeedControl',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),

      routes: {
        '/login': (context) => const LoginPage(),
        '/feed': (context) => const FeedPage(),
        '/interesses': (context) => const InteressesPage(),
      },


      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasData) {
            final user = snapshot.data!;
            // ✅ Verifica se já tem interesses salvos
            return FutureBuilder<bool>(
              future: _temInteresses(user.uid),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.data == true) {
                  return const FeedPage();
                } else {
                  return const InteressesPage();
                }
              },
            );
          }

          return const LoginPage();
        },
      ),
    );
  }
}
