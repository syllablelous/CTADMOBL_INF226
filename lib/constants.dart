import 'package:flutter_dotenv/flutter_dotenv.dart';

String get host => dotenv.env['HOST'] ?? 'http://localhost:3000';
