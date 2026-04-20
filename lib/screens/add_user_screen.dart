import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../models/user.dart';
import '../theme/app_theme.dart';
import '../widgets/admin_app_bar.dart';
import '../widgets/admin_drawer.dart';
import 'dart:math';

class AddUserScreen extends StatefulWidget {
  const AddUserScreen({super.key});

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  final _firestoreService = FirestoreService();
  final _authService = AuthService();

  String _selectedRole = 'guard';
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
  }

  // 🔐 Generate random secure password
  String _generateTempPassword() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final rand = Random();
    return List.generate(
      10,
          (index) => chars[rand.nextInt(chars.length)],
    ).join();
  }

  Future<void> _addUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final tempPassword = _generateTempPassword();

      // 1. Create Firebase Auth user
      final userCredential =
      await _authService.registerWithEmailAndPassword(
        email: email,
        password: tempPassword,
      );

      final uid = userCredential.user!.uid;

      // 2. Save user in Firestore
      final newUser = User(
        id: uid,
        name: _nameController.text.trim(),
        email: email,
        role: _selectedRole,
        phoneNumber: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        hasResetPassword: false,
        createdAt: DateTime.now(),
      );

      await _firestoreService.saveUser(newUser);

      // 3. Send password reset email (Firebase Auth)
      await _authService.sendPasswordResetEmail(email);

      if (!mounted) return;

      setState(() => _isLoading = false);

      // Clear fields
      _nameController.clear();
      _emailController.clear();
      _phoneController.clear();

      _showSuccessDialog(newUser);
    } catch (e) {
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  void _showSuccessDialog(User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('User Created Successfully'),
        content: Text(
          'Name: ${user.name}\n'
              'Email: ${user.email}\n\n'
              '✔ A password reset email has been sent.\n'
              '✔ User must reset password before login.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AdminDrawer(),
      appBar: AdminAppBar(
        title: 'Add User',
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/user_management');
            },
            tooltip: 'View All Users',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: (v) =>
                v == null || v.isEmpty ? 'Enter name' : null,
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter email';
                  if (!_isValidEmail(v)) return 'Enter valid email';
                  return null;
                },
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
              ),

              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: _selectedRole,
                items: const [
                  DropdownMenuItem(value: 'guard', child: Text('Guard')),
                  DropdownMenuItem(value: 'manager', child: Text('Manager')),
                ],
                onChanged: (value) =>
                    setState(() => _selectedRole = value!),
                decoration: const InputDecoration(labelText: 'Role'),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _addUser,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Create User'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}