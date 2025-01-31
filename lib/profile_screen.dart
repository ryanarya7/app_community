import 'dart:convert';
import 'package:flutter/material.dart';
import 'odoo_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/cupertino.dart';

class ProfileScreen extends StatelessWidget {
  final OdooService odooService;

  const ProfileScreen({super.key, required this.odooService});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Map<String, dynamic>>(
        future: (() async {
          try {
            await odooService.checkSession(); // Validasi sesi
            return odooService.fetchUser(); // Ambil data pengguna
          } catch (e) {
            if (e.toString().contains('Session expired')) {
              throw Exception('Session expired. Please log in again.');
            }
            rethrow;
          }
        })(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            final error = snapshot.error.toString();
            if (error.contains('Session expired')) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Session expired. Please log in again.",
                      style: GoogleFonts.poppins(
                        textStyle: TextStyle(fontSize: 16, color: Colors.red),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 50, vertical: 15),
                      ),
                      child: const Text("Login"),
                    ),
                  ],
                ),
              );
            }
            return Center(
              child: Text("Error loading data: $error"),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: Text("No user data available"));
          }

          final user = snapshot.data!;
          return Stack(
            children: [
              // Background
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue[300]!, Colors.blue[700]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
              // Profile Content
              Positioned.fill(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Animated Avatar
                      CircleAvatar(
                        radius: 60,
                        backgroundImage: (user['image_1920'] != null &&
                                user['image_1920'] is String)
                            ? MemoryImage(base64Decode(user['image_1920']))
                            : null,
                        child: (user['image_1920'] == null ||
                                user['image_1920'] is! String)
                            ? const Icon(CupertinoIcons.person,
                                size: 60, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(height: 16),
                      // User Name
                      Text(
                        user['name'],
                        style: GoogleFonts.poppins(
                          textStyle: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // User Login
                      Text(
                        user['login'],
                        style: GoogleFonts.lato(
                          textStyle: TextStyle(
                            fontSize: 18,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Logout Button
                      ElevatedButton.icon(
                        onPressed: () {
                          odooService.logout();
                          Navigator.pushReplacementNamed(context, '/login');
                        },
                        icon: const Icon(CupertinoIcons.square_arrow_up,
                            color: Colors.white),
                        label: Text(
                          "Logout",
                          style: GoogleFonts.poppins(
                            textStyle:
                                TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 50, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
