import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (success && mounted) {
        // Check if user needs to reset password
        final needsReset = await authProvider.needsPasswordReset();
        
        if (needsReset) {
          Navigator.pushReplacementNamed(context, '/password_reset');
        } else {
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Image.asset(
                      'assets/logo.png',
                      height: 120,
                    ),

                    const SizedBox(height: 48),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!value.contains('@')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    Consumer<AuthProvider>(
                      builder: (context, authProvider, child) {
                        if (authProvider.isLoading) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        return ElevatedButton(
                          onPressed: _handleLogin,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Sign In',
                            style: TextStyle(fontSize: 16),
                          ),
                        );
                      },
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/forgot_password');
                      },
                      child: const Text('Forgot Password?'),
                    ),
                    Consumer<AuthProvider>(
                      builder: (context, authProvider, child) {
                        if (authProvider.errorMessage != null) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Text(
                              authProvider.errorMessage!,
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
