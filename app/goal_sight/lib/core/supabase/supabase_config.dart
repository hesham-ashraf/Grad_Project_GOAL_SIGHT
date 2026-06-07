import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Supabase project URL, read from the `.env` file (key `SUPABASE_URL`).
/// Empty when the env file is missing or the key is unset.
String get supabaseUrl => dotenv.maybeGet('SUPABASE_URL') ?? '';

/// Supabase anon key, read from the `.env` file (key `SUPABASE_ANON_KEY`).
/// Empty when the env file is missing or the key is unset.
String get supabaseAnonKey => dotenv.maybeGet('SUPABASE_ANON_KEY') ?? '';

/// True only when both connection values are present, so the app can decide
/// whether to initialize Supabase or fall back to mock data.
bool get hasSupabaseConfig =>
    supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
