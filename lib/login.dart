// ignore_for_file: use_build_context_synchronously, prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'register.dart';
import 'home.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _message = '';

  @override
  void initState() {
    super.initState();
    checkForToken();
  }

  Future<void> checkForToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('access_token');
    if (accessToken != null) {
      String? username = prefs.getString('username');
      if (username != null) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (context) => HomeScreen(
                  username: username,
                  accessToken: accessToken,
                )));
      }
    }
  }

  void _login() async {
    var url = Uri.parse('http://165.227.117.48/login');
    var response = await http.post(url,
        body: jsonEncode({
          'username': _usernameController.text,
          'password': _passwordController.text,
        }),
        headers: {
          'Content-Type': 'application/json',
        });

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      setState(() {
        _message = data['message'];
      });
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String accessToken = data['access_token'];
      await prefs.setString('access_token', accessToken);
      await prefs.setString('username', _usernameController.text);

      Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (context) => HomeScreen(
                username: _usernameController.text,
                accessToken: accessToken,
              )));
    } else {
      setState(() {
        _message = 'Failed to log in. Please check your credentials.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Login Page"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: "Username",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: "Password",
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _login,
              child: const Text('Log In'),
            ),
            if (_message.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(_message, style: TextStyle(color: Colors.red)),
              ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RegistrationPage(),
                  ),
                );
              },
              child: const Text('Register'),
            ),
          ],
        ),
      ),
    );
  }
}
