import 'package:firebase_auth/firebase_auth.dart';
import 'package:flexipay/ui/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _loading = false;
  bool _isLogin = true; // Toggle between login/signup
  String? _errorMessage;

  final _formKey = GlobalKey<FormState>();

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      if (_isLogin) {
        // Sign In
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        // Sign Up
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('remember_me', _rememberMe);

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message ?? 'Authentication failed';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [colorScheme.primary.withOpacity(0.8), colorScheme.secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 48),
            child: Card(
              elevation: 16,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              color: Colors.white.withOpacity(0.95),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _isLogin ? 'Welcome Back!' : 'Create Account',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _isLogin
                            ? 'Sign in to your SHAZ account'
                            : 'Sign up and start your journey with SHAZ',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: colorScheme.primary.withOpacity(0.75),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Email TextField
                      TextFormField(
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        controller: _emailController,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.email_outlined),
                          labelText: 'Email',
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (val) {
                          if (val == null || !val.contains('@')) {
                            return 'Enter a valid email';
                          }
                          return null;
                        },
                        keyboardType: TextInputType.emailAddress,
                      ),

                      const SizedBox(height: 20),

                      // Password TextField
                      TextFormField(
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.lock_outline),
                          labelText: 'Password',
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // Remember Me Checkbox
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Keep me Logged In',
                          style: TextStyle(color: colorScheme.primary),
                        ),
                        value: _rememberMe,
                        activeColor: colorScheme.primary,
                        onChanged: (val) => setState(() => _rememberMe = val ?? false),
                      ),

                      const SizedBox(height: 20),

                      // Show error message if any
                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600),
                            textAlign: TextAlign.center,
                          ),
                        ),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            backgroundColor: colorScheme.primary,
                            elevation: 8,
                          ),
                          onPressed: _loading ? null : _submit,
                          child: _loading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text(
                            _isLogin ? 'Login' : 'Sign Up',
                            style: const TextStyle(fontSize: 18,color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Toggle Login/Signup
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isLogin = !_isLogin;
                            _errorMessage = null;
                          });
                        },
                        child: Text(
                          _isLogin ? "Don't have an account? Sign Up" : "Already have an account? Login",
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // SHAZ info footer
                      Opacity(
                        opacity: 0.6,
                        child: Column(
                          children: [
                            const Divider(thickness: 1),
                            const SizedBox(height: 8),
                            Text(
                              'Powered by Qasim Saeed',
                              style: TextStyle(
                                fontSize: 14,
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '© 2025 FlexiPay. All rights reserved.',
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.primary.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
