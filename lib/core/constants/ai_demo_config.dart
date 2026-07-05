class AiDemoConfig {
  const AiDemoConfig._();

  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  static bool get hasGeminiApiKey => geminiApiKey.trim().isNotEmpty;
}
