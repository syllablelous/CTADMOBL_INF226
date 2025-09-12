import 'package:flutter_dotenv/flutter_dotenv.dart';

String get host => dotenv.env['HOST'] ?? 'http://10.0.2.2:8000';
