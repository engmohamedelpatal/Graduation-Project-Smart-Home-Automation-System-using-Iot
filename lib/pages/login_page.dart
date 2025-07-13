import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'control_page.dart';
import 'create_account_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _errorMessage;

  bool _obscurePassword = true;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final database = FirebaseDatabase.instance;

  Future<void> _login() async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final userId = userCredential.user?.uid;
      if (userId == null) {
        setState(() {
          _errorMessage = "User ID not found";
        });
        return;
      }

      final ref = database.ref('users/$userId');
      final snapshot = await ref.get();

      if (!snapshot.exists) {
        setState(() {
          _errorMessage = "User data not found";
        });
        return;
      }

      final data = snapshot.value as Map;
      final approved = data['approved'] == true;

      if (!approved) {
        setState(() {
          _errorMessage = "Your account is pending approval by admin.";
        });
        return;
      }

      Navigator.pushReplacement(
        // ignore: use_build_context_synchronously
        context,
        MaterialPageRoute(builder: (context) => ControlPageA()),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Login failed: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, 
      body: SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            const SizedBox(height: 30),
            const Text(
              "WELCOME TO ISAM SMART HOME",
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 260,
              width: 400,
              child: Image.asset(
                "assets/WhatsApp Image 2025-06-26 at 16.31.48_84a23164.jpg",
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 22),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 55),
              child: TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                  hintText: "Email",
                ),
              ),
            ),
            const SizedBox(height: 22),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 55),
              child: TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock),
                  hintText: "Password",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
              ),
            ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 55, vertical: 8),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            const SizedBox(height: 40),
            SizedBox(
              width: 200,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
                onPressed: _login,
                child: const Text("Login"),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: 200,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CreateAccountPage()),
                  );
                },
                child: const Text("Create Account"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
