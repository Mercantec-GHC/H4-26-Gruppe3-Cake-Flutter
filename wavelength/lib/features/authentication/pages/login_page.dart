import 'dart:convert';

import 'package:flutter/material.dart';
import '../models/login_model.dart';
import '../models/login_response_model.dart';
import '../services/auth_service.dart';
import 'register_page.dart';
import 'profile_page.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();

}

class _LoginPageState extends State<LoginPage> {
  bool _obscurePassword = true;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  final _secureStorage = FlutterSecureStorage();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/app_icon.png',
                width: 200,
                height: 150,
              ),
              const SizedBox(height: 20),
              const SizedBox(
                width: 200,
                child: Text(
                  'Log ind',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.deepPurple,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 350,
                child: TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Email',
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: 350,
                child: TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Password',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
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
              const SizedBox(height: 20),
              SizedBox(
                width: 350,
                height: 40,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  onPressed: () async {
                    final model = LoginModel(
                      email: _emailController.text.trim(),
                      password: _passwordController.text.trim(),
                    );

                    final response = await _authService.login(model);
                    if(!mounted) return;

                    if (response.statusCode == 200){
                      // Save JWT Token
                      Map<String, dynamic> json = jsonDecode(response.body);

                      LoginResponseModel model = LoginResponseModel.fromJson(json);

                      await _secureStorage.write(key: 'jwtToken', value: model.jwtToken);
                      await _secureStorage.write(key: 'refreshToken', value: model.refreshToken);
                      DateTime expiry = DateTime.now().toUtc().add(Duration(seconds: model.expires));
                      await _secureStorage.write(key: 'jwtExpiry', value: expiry.toString());

                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (context) => const ProfilePage(),
                        ),
                      );
                    } else if (response.statusCode == 401 || response.statusCode == 400) {
                      // Unauthorized - wrong email or password
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Forkert email eller adgangskode. Prøv igen.'),
                          backgroundColor: Colors.red,
                          duration: Duration(seconds: 4),
                        ),
                      );
                    } else {
                      // Other errors
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Login fejlede: ${response.statusCode}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: const Text('Log ind'),
                ),
              ),
              SizedBox(
                width: 300,
                height: 70,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Har du ikke en konto? '),
                    GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (context) => RegisterPage(),
                        ),
                      ),
                      child: const Text(
                        'Opret her',
                        style: TextStyle(
                          color: Colors.deepPurple,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            ]
          ),
        ),
      ),
    );
  }
}