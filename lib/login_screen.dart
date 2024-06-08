import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main.dart'; // Import FirebaseAuthService and UserProfile
import 'video_feed_screen.dart';
import 'profile_screen.dart';
import 'user_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuthService _authService = FirebaseAuthService();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email'),
                validator: (value) => value!.isEmpty ? 'Please enter email' : null,
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) => value!.isEmpty ? 'Please enter password' : null,
              ),
              SizedBox(height: 40),
              ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () async {
                  if (_formKey.currentState!.validate()) {
                    setState(() {
                      _isLoading = true;
                    });

                    UserCredential? user =
                    await _authService.signInWithEmailAndPassword(
                      _emailController.text,
                      _passwordController.text,
                    );

                    setState(() {
                      _isLoading = false;
                    });

                    if (user != null) {
                      // Fetch or create user profile
                      UserProfile? userProfile = await _authService.getUserProfile(user.user!.uid);
                      if (userProfile == null) {
                        userProfile = UserProfile(
                          uid: user.user!.uid,
                          email: _emailController.text,
                          username: 'new_user', // Default username
                        );
                        await _authService.createOrUpdateUserProfile(userProfile);
                      }
                      SharedPreferences prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('isLoggedIn', true);

                      // Navigate to VideoFeedScreen
                      Navigator.pushReplacementNamed(context, '/feed');
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('Invalid email or password')),
                      );
                    }
                  }
                },
                child: _isLoading
                    ? CircularProgressIndicator()
                    : Text('Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}