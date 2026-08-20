import 'package:flutter_dotenv/flutter_dotenv.dart';

var host = dotenv.env['HOST'];

// Enhancement 3: there is no auth/session in this app yet, so cart calls
// are scoped to a fixed demo user id (see https://dummyjson.com/docs/carts).
const demoUserId = 1;
