/// API Configuration for Math Scanner AI.
/// 
/// Configure your AI API keys and endpoints here.
/// For production, these should be loaded from environment variables
/// or a secure configuration source.
class ApiConfig {
  ApiConfig._();

  /// Base URL for the AI API.
  /// Options:
  /// - OpenAI: 'https://api.openai.com/v1'
  /// - Local server: 'http://localhost:8000/api'
  /// - Custom backend: 'https://your-backend.com/api'
  static const String baseUrl = 'https://api.openai.com/v1';

  /// API Key for authentication.
  /// WARNING: Do NOT hardcode production keys here.
  /// Use environment variables or secure storage in production.
  static const String apiKey = '';

  /// AI Model to use for solving.
  static const String model = 'gpt-4o-mini';

  /// Request timeout in seconds.
  static const int timeoutSeconds = 60;

  /// Max tokens for AI response.
  static const int maxTokens = 2000;

  /// Temperature for AI response (0.0 = deterministic, 1.0 = creative).
  static const double temperature = 0.2;

  /// Whether to use the local math solver as fallback.
  static const bool enableLocalFallback = true;

  /// Maximum history items to store locally.
  static const int maxHistoryItems = 100;
}
