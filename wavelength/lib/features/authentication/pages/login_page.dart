
import 'package:flutter/material.dart';


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();

}

class _LoginPageState extends State<LoginPage> {
  @override
  Widget build(BuildContext context){
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: .center,
          children: [
            Image.asset(
              'assets/images/app_icon.png',
              width: 150,
              height: 150,
            ),
            const SizedBox(height: 20),
            const Text('Log ind', style: TextStyle(color: Colors.deepPurple, fontSize: 40, fontWeight: FontWeight.bold)),
            TextField(
              decoration: InputDecoration(border: OutlineInputBorder(), labelText: 'Email')
            ),

            TextField(
              obscureText: true,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Password'
              )
            ),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                textStyle: const TextStyle(fontSize: 20),
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),              
              onPressed: () {},
              child: const Text('Log ind')
            )
          ]
        )
      )
    );
  }
}