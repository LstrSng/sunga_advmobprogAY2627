import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

String get host => dotenv.env['HOST'] ?? 'https://dummyjson.com';

// Shared brand color for the splash background, the signin button, and the
// Profile tab's header.
const brandNavy = Color(0xFF2A2A72);
