import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Base URL of the ML analysis backend (the service that runs the 4 models and
/// returns the 4 JSON files + the analyzed match video). Read from the `.env`
/// file (key `ANALYSIS_API_URL`). Empty when unset — in that case the app
/// falls back to the built-in [SimulatedAnalysisEngine] so the upload→analysis
/// flow stays demoable without the backend.
///
/// Example `.env`:
///   ANALYSIS_API_URL=https://your-ml-service.example.com
String get analysisApiBaseUrl => dotenv.maybeGet('ANALYSIS_API_URL') ?? '';

/// True when an analysis backend is configured (so the real
/// [ModelAnalysisEngine] should be used instead of the simulator).
bool get hasAnalysisApi => analysisApiBaseUrl.isNotEmpty;
