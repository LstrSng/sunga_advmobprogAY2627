import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

// constants
import '../constants.dart';

// services
import '../services/user_service.dart';

// widgets
import '../widgets/custom_text.dart';

// Lab Activity 5 - Enhancement 2: Signup screen with Firebase Auth.
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fNameController = TextEditingController();
  final _lNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _contactNoController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _fNameController.dispose();
    _lNameController.dispose();
    _ageController.dispose();
    _contactNoController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Lab Activity 5 - Enhancement 2: Creates the Firebase account and saves the signup details.
  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final userService = UserService();

      // Firebase Auth registration
      final credential = await userService.createAccount(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Save user display name and profile info
      final displayName = _usernameController.text.trim().isNotEmpty
          ? _usernameController.text.trim()
          : '${_fNameController.text.trim()} ${_lNameController.text.trim()}'
                .trim();

      await credential.user?.updateDisplayName(displayName);

      await prefs.setString('loginType', 'firebase');
      await prefs.setString('firstName', _fNameController.text.trim());
      await prefs.setString('lastName', _lNameController.text.trim());
      await prefs.setString('username', _usernameController.text.trim());
      await prefs.setString('email', _emailController.text.trim());
      await prefs.setString('contactNo', _contactNoController.text.trim());
      await prefs.setString('age', _ageController.text.trim());
      await userService.getToken(forceRefresh: true);

      // DummyJSON /users/add (simulated — see dummyjson.com/users). Non-fatal:
      // the Firebase account is already created if this request fails.
      try {
        await userService.addUser({
          'firstName': _fNameController.text.trim(),
          'lastName': _lNameController.text.trim(),
          'age': int.parse(_ageController.text.trim()),
          'phone': _contactNoController.text.trim(),
          'username': _usernameController.text.trim(),
          'email': _emailController.text.trim(),
        });
      } catch (_) {}

      if (!mounted) return;
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account created successfully!')),
      );
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration failed: ${e.toString()}')),
      );
    }
  }

  InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: CustomText(
          text: 'Create Account',
          fontSize: 18.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // First Name
                TextFormField(
                  controller: _fNameController,
                  decoration: _fieldDecoration('First Name'),
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'First name is required'
                      : null,
                ),
                SizedBox(height: 12.h),

                // Last Name
                TextFormField(
                  controller: _lNameController,
                  decoration: _fieldDecoration('Last Name'),
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'Last name is required'
                      : null,
                ),
                SizedBox(height: 12.h),

                // Age
                TextFormField(
                  controller: _ageController,
                  decoration: _fieldDecoration('Age'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Age is required';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Enter a valid number';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 12.h),

                // Contact Number
                TextFormField(
                  controller: _contactNoController,
                  decoration: _fieldDecoration('Contact Number'),
                  keyboardType: TextInputType.phone,
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'Contact number is required'
                      : null,
                ),
                SizedBox(height: 12.h),

                // Username
                TextFormField(
                  controller: _usernameController,
                  decoration: _fieldDecoration('Username'),
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'Username is required'
                      : null,
                ),
                SizedBox(height: 12.h),

                // Email Address
                TextFormField(
                  controller: _emailController,
                  decoration: _fieldDecoration('Email Address'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Email is required';
                    }
                    if (!value.contains('@')) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 12.h),

                // Lab Activity 5 - Enhancement 2: Password validation (required, at least 6 characters).
                // Password (min 6 characters)
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: _fieldDecoration('Password'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password is required';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 24.h),

                // Register button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brandNavy,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                    onPressed: _isLoading ? null : _register,
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 10.h),
                      child: _isLoading
                          ? SizedBox(
                              width: 20.w,
                              height: 20.w,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : CustomText(
                              text: 'Sign Up',
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),

                // Back to sign-in link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomText(
                      text: 'Already have an account? ',
                      fontSize: 13.sp,
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: CustomText(
                        text: 'Log In',
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: brandNavy,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
