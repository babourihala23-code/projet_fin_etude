import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projet_fin_etude/student/student_home.dart';
import 'package:projet_fin_etude/teacher/teacher_home.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const AttendQRApp());
}

class AttendQRApp extends StatelessWidget {
  const AttendQRApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AttendQR',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF38BDF8),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
      ),
      home: const LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController regController = TextEditingController();
  final TextEditingController passController = TextEditingController();
  bool isLoading = false;
  bool _isObscured = true;

  final Color deepIndigo = const Color(0xFF0F172A);
  final Color cardColor = const Color(0xFF1E293B);
  final Color neonBlue = const Color(0xFF38BDF8);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: deepIndigo,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 60),
                Text(
                  'AttendQR',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: neonBlue,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 80),
                //Welcome
                Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Welcome',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Fill out the information below to access your account.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withAlpha(150),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                // inputs
                _buildTextField(
                  hint: 'Registration Number',
                  controller: regController,
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  hint: 'Password',
                  isPassword: true,
                  controller: passController,
                  icon: Icons.lock_outline,
                ),
                const SizedBox(height: 60),
                // login button
                SizedBox(
                  width: 200,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: neonBlue,
                      foregroundColor: deepIndigo,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: deepIndigo,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Login',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String hint,
    bool isPassword = false,
    required TextEditingController controller,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? _isObscured : false,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withAlpha(80)),
        filled: true,
        fillColor: cardColor,
        prefixIcon: Icon(icon, color: neonBlue.withAlpha(150)),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _isObscured
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Colors.white.withAlpha(100),
                ),
                onPressed: () => setState(() => _isObscured = !_isObscured),
              )
            : null,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 20,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withAlpha(15), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: neonBlue, width: 1.5),
        ),
      ),
    );
  }

  // دالة الـ Login
  Future<void> login() async {
    String reg = regController.text.trim();
    String pass = passController.text.trim();

    if (reg.isEmpty || pass.isEmpty) {
      _showSnackBar("Please fill all fields");
      return;
    }

    setState(() => isLoading = true);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('registrationNumber', isEqualTo: reg)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final userDoc = snapshot.docs.first;
        final userData = userDoc.data();
        final dbPassword = userData['password']?.toString() ?? "";
        final role = userData['role']?.toString().toLowerCase() ?? "student";

        if (dbPassword == pass) {
          if (mounted) {
            if (role == 'teacher') {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => TeacherHome(teacherId: reg)),
              );
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => StudentHome(studentId: reg)),
              );
            }
          }
        } else {
          _showSnackBar("Wrong password.");
        }
      } else {
        _showSnackBar("User not found.");
      }
    } catch (e) {
      _showSnackBar("Error: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}
