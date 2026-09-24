
Enhancement 1: UserService Functions

lib/services/user_service.dart

// Lab Activity 5 - Enhancement 1: Firebase Auth methods for user management.
final FirebaseAuth firebaseAuth = FirebaseAuth.instance;

User? get currentUser => firebaseAuth.currentUser;

Stream<User?> get authStateChanges => firebaseAuth.authStateChanges();

// Lab Activity 5 - Enhancement 1: Signs in with email and password using Firebase.
Future<UserCredential> signIn({
  required String email,
  required String password,
}) async {
  return await firebaseAuth.signInWithEmailAndPassword(
    email: email,
    password: password,
  );
}

// Lab Activity 5 - Enhancement 1: Creates a new Firebase account.
Future<UserCredential> createAccount({
  required String email,
  required String password,
}) async {
  return await firebaseAuth.createUserWithEmailAndPassword(
    email: email,
    password: password,
  );
}

// Lab Activity 5 - Enhancement 1: Signs out the Firebase user.
Future<void> signOut() async {
  await firebaseAuth.signOut();
}

// Lab Activity 5 - Enhancement 1: Updates the Firebase display name (username).
Future<void> updateUsername({required String username}) async {
  await currentUser!.updateDisplayName(username);
}

// Lab Activity 5 - Enhancement 1: Re-checks the password, then deletes the Firebase account.
Future<void> deleteAccount({
  required String email,
  required String password,
}) async {
  AuthCredential credential = EmailAuthProvider.credential(
    email: email,
    password: password,
  );

  await currentUser!.reauthenticateWithCredential(credential);
  await currentUser!.delete();
  await firebaseAuth.signOut();
}

// Lab Activity 5 - Enhancement 1: Re-checks the current password, then sets a new one.
Future<void> resetPasswordFromCurrentPassword({
  required String currentPassword,
  required String newPassword,
  required String email,
}) async {
  AuthCredential credential = EmailAuthProvider.credential(
    email: email,
    password: currentPassword,
  );

  await currentUser!.reauthenticateWithCredential(credential);
  await currentUser!.updatePassword(newPassword);
}

// Lab Activity 5 - Enhancement 1: Logout clears the saved session and token.
Future<void> logout() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  } catch (e) {
    throw Exception('Failed to log out: $e');
  }
}

profile_screen.dart – Logout button → clears session and redirects to login


// Lab Activity 5 - Enhancement 1: Logout button clears the session and goes back to login.
Future<void> _logout(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  final loginType = prefs.getString('loginType') ?? 'dummyjson';

  if (loginType == 'firebase') {
    await _userService.signOut();
  }
  await _userService.logout();

  if (!context.mounted) return;
  Navigator.pushNamedAndRemoveUntil(context, '/signin', (route) => false);
}













Enhancement 2: DummyJSON vs Firebase Auth

user_service.dart` – DummyJSON login (`/auth/login`)


Future<Map<String, dynamic>> loginUser(
  String username,
  String password,
) async {
  final response = await http
      .post(
        Uri.parse('$host/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
          'expiresInMins': 60,
        }),
      )
      .timeout(const Duration(seconds: 10));

  if (response.statusCode == 200) {
    data = jsonDecode(response.body);
    await saveUserData(data);
    return data;
  } else {
    throw Exception(response.body);
  }
}

// Lab Activity 5 - Enhancement 2: DummyJSON sign up through /users/add (simulated only).
Future<Map<String, dynamic>> addUser(Map<String, dynamic> userData) async {
  final response = await http
      .post(
        Uri.parse('$host/users/add'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(userData),
      )
      .timeout(const Duration(seconds: 10));

  if (response.statusCode == 200 || response.statusCode == 201) {
    return jsonDecode(response.body);
  } else {
    throw Exception(response.body);
  }
}

user_service.dart – Firebase token refresh + session check

// Lab Activity 5 - Enhancement 2: Firebase token refresh.
Future<String?> getToken({bool forceRefresh = false}) async {
  final token = await currentUser?.getIdToken(forceRefresh);
  if (token != null) {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }
  return token;
}

// Lab Activity 5 - Enhancement 2: Checks both the Firebase session and the DummyJSON token.
Future<bool> isLoggedIn() async {
  final firebaseUser = await firebaseAuth.authStateChanges().first;
  if (firebaseUser != null) return true;

  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('accessToken') ?? prefs.getString('token');
  return token != null && token.isNotEmpty;
}

signin_screen.dart – Email → Firebase, Username → DummyJSON

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

    if (!mounted) return;
    setState(() => _isLoading = false);
    Navigator.pushReplacementNamed(context, '/home');
  } else {
    // Lab Activity 5 - Enhancement 2: DummyJSON sign in through /auth/login.
    final response = await userService.loginUser(identifier, password);
    await prefs.setString('loginType', 'dummyjson');

    if (!mounted) return;
    setState(() => _isLoading = false);
    Navigator.pushReplacementNamed(context, '/home', arguments: response);
  }
} catch (e) {
  // shows "Login failed" SnackBar
}


signup_screen.dart – Signup UI (fName, lName, age, contactNo, username, emailAddress, password)

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

    await credential.user?.updateDisplayName(_usernameController.text.trim());

    await prefs.setString('loginType', 'firebase');
    await prefs.setString('firstName', _fNameController.text.trim());
    await prefs.setString('lastName', _lNameController.text.trim());
    await prefs.setString('username', _usernameController.text.trim());
    await prefs.setString('email', _emailController.text.trim());
    await prefs.setString('contactNo', _contactNoController.text.trim());
    await prefs.setString('age', _ageController.text.trim());
    await userService.getToken(forceRefresh: true);

    // DummyJSON /users/add (simulated — see dummyjson.com/users)
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

    Navigator.pushReplacementNamed(context, '/home');
  } catch (e) {
    // shows "Registration failed" SnackBar
  }
}

// Lab Activity 5 - Enhancement 2: Password validation (required, at least 6 characters).
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








Enhancement 3: Profile Screen

user_service.dart – `getUserData()` depends on the LoginType


// Lab Activity 5 - Enhancement 3: Returns Firebase or DummyJSON user data depending on the loginType.
Future<Map<String, dynamic>> getUserData() async {
  final prefs = await SharedPreferences.getInstance();
  final loginType = prefs.getString('loginType') ?? 'dummyjson';

  if (loginType == 'firebase') {
    final user = currentUser;
    return {
      'loginType': 'firebase',
      'uid': user?.uid ?? '',
      'username': user?.displayName ?? prefs.getString('username') ?? '',
      'email': user?.email ?? prefs.getString('email') ?? '',
      'firstName': prefs.getString('firstName') ?? '',
      'lastName': prefs.getString('lastName') ?? '',
      'age': prefs.getString('age') ?? '',
      'contactNo': prefs.getString('contactNo') ?? '',
      'image': user?.photoURL ?? '',
      'token': prefs.getString('token') ?? '',
    };
  }

  return {
    'loginType': 'dummyjson',
    'id': prefs.getInt('id') ?? 0,
    'username': prefs.getString('username') ?? '',
    'email': prefs.getString('email') ?? '',
    'firstName': prefs.getString('firstName') ?? '',
    'lastName': prefs.getString('lastName') ?? '',
    'gender': prefs.getString('gender') ?? '',
    'image': prefs.getString('image') ?? '',
    'accessToken': prefs.getString('accessToken') ?? '',
    'refreshToken': prefs.getString('refreshToken') ?? '',
  };
}


profile_screen.dart` – Fetch via `UserService().getUserData()` and show details by LoginType

// Lab Activity 5 - Enhancement 3: UserService().getUserData() returns the
// Firebase or DummyJSON user depending on the saved loginType.
Future<Map<String, dynamic>> _loadProfile() => _userService.getUserData();

// Lab Activity 5 - Enhancement 3: Shows different details depending on the loginType.
final loginType = profile['loginType'] ?? 'dummyjson';
final isFirebase = loginType == 'firebase';

if (!isFirebase) ...[
  _buildInfoRow(Icons.wc, 'Gender', profile['gender'] ?? ''),
  _buildInfoRow(Icons.badge_outlined, 'User ID', '#${profile['id']}'),
],
if (isFirebase) ...[
  _buildInfoRow(Icons.cake_outlined, 'Age', profile['age']),
  _buildInfoRow(Icons.phone_outlined, 'Contact No.', profile['contactNo']),
  _buildInfoRow(Icons.badge_outlined, 'UID', '${profile['uid']}'),
],


profile_screen.dart` – Update username, change password, delete account


// Lab Activity 5 - Enhancement 3: Update username dialog.
if (loginType == 'firebase') {
  await _userService.updateUsername(username: newUsername);
} else {
  // Update locally in SharedPreferences for DummyJSON
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('username', newUsername);
}

// Lab Activity 5 - Enhancement 3: Change password dialog (Firebase only).
await _userService.resetPasswordFromCurrentPassword(
  currentPassword: currentPwController.text,
  newPassword: newPwController.text,
  email: profile['email'] ?? '',
);

// Lab Activity 5 - Enhancement 3: Delete account confirmation dialog.
await _userService.deleteAccount(
  email: profile['email'] ?? '',
  password: passwordController.text,
);
await _userService.logout();
Navigator.pushNamedAndRemoveUntil(context, '/signin', (route) => false);


settings_screen.dart` – Logout in settings → back to login


// Lab Activity 5 - Enhancement 3: Settings with logout redirect to login.
Future<void> _logout(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  final loginType = prefs.getString('loginType') ?? 'dummyjson';
  final userService = UserService();

  if (loginType == 'firebase') {
    await userService.signOut();
  }
  await userService.logout();

  if (!context.mounted) return;
  Navigator.pushNamedAndRemoveUntil(context, '/signin', (route) => false);
}

// Lab Activity 5 - Enhancement 3: Logout button.
ListTile(
  leading: Icon(Icons.logout, color: Colors.deepOrange.shade300),
  title: CustomText(
    text: 'Log Out',
    fontSize: 16.sp,
    fontWeight: FontWeight.w600,
    color: Colors.deepOrange.shade300,
  ),
  subtitle: CustomText(
    text: 'Sign out and return to login',
    fontSize: 12.sp,
  ),
  onTap: () => _logout(context),
),