import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

// constants
import '../constants.dart';

// services
import '../services/user_service.dart';

// widgets
import '../widgets/custom_text.dart';
import '../utils/error_message.dart';

// Lab Activity 5 - Enhancement 2: Sign-in supports DummyJSON and Firebase Auth.
class SigninScreen extends StatefulWidget {
  const SigninScreen({super.key});

  @override
  State<SigninScreen> createState() => _SigninScreenState();
}

class _SigninScreenState extends State<SigninScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Lab Activity 6: Ignore stray spaces/quotes around the username or email.
    final identifier = _identifierController.text.trim().replaceAll(
      RegExp(r'''^["']+|["']+$'''),
      '',
    );
    final password = _passwordController.text;
    // Lab Activity 5 - Enhancement 2: Input with @ uses Firebase, otherwise DummyJSON.
    final isEmail = identifier.contains('@');

    try {
      final prefs = await SharedPreferences.getInstance();
      final userService = UserService();

      if (isEmail) {
        // Lab Activity 5 - Enhancement 2: Firebase sign in, then refresh the token.
        await userService.signIn(email: identifier, password: password);
        await prefs.setString('loginType', 'firebase');
        await userService.getToken(forceRefresh: true);
        // Lab Activity 6 - Enhancement 1: Make sure the user is in the chat list.
        await userService.trySaveUserToFirestore();

        if (!mounted) return;
        setState(() => _isLoading = false);
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        // Lab Activity 5 - Enhancement 2: DummyJSON sign in through /auth/login.
        // loginUser already saves the response to SharedPreferences.
        final response = await userService.loginUser(identifier, password);
        await prefs.setString('loginType', 'dummyjson');

        if (!mounted) return;
        setState(() => _isLoading = false);
        Navigator.pushReplacementNamed(context, '/home', arguments: response);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage(e))));
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
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/nubdexchange_logo.png',
                      width: 32.w,
                    ),
                    SizedBox(width: 8.w),
                    CustomText(
                      text: 'Welcome',
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ],
                ),
                SizedBox(height: 32.h),
                TextFormField(
                  controller: _identifierController,
                  decoration: _fieldDecoration('Username or Email'),
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'Username or Email is required'
                      : null,
                ),
                SizedBox(height: 16.h),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: _fieldDecoration('Password'),
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'Password is required'
                      : null,
                ),
                SizedBox(height: 24.h),
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
                    onPressed: _isLoading ? null : _login,
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
                              text: 'Log In',
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                    ),
                  ),
                ),
                SizedBox(height: 20.h),
                // Lab Activity 5 - Enhancement 2: Link to sign-up screen.
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomText(
                      text: "Don't have an account? ",
                      fontSize: 13.sp,
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/signup'),
                      child: CustomText(
                        text: 'Sign Up',
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
