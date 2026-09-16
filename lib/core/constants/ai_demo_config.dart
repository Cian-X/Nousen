class AiDemoConfig {
  const AiDemoConfig._();

  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  static bool get hasGeminiApiKey => geminiApiKey.trim().isNotEmpty;

  /// Gates all on-device ONNX predictions while the models are being rebuilt.
  /// Rules-based insights remain enabled.
  static const bool onDeviceMlEnabled = false;
}
