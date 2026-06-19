import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Base URL of the Python PDF microservice (FastAPI) that renders player-profile
/// reports. Read from the `.env` file (key `PDF_API_URL`). Empty when unset.
///
/// Example `.env`:
///   PDF_API_URL=http://10.0.2.2:8000   # Android emulator -> host machine
String get pdfApiBaseUrl => dotenv.maybeGet('PDF_API_URL') ?? '';

/// True when a PDF backend is configured, so the manager can export reports.
bool get hasPdfApi => pdfApiBaseUrl.isNotEmpty;
