class AiConfig {
  static const groqApiKey = String.fromEnvironment('GROQ_API_KEY');
  static const groqModel = String.fromEnvironment(
    'GROQ_MODEL',
    defaultValue: 'openai/gpt-oss-20b',
  );

  static const responsesUrl = 'https://api.groq.com/openai/v1/responses';

  static bool get isConfigured => groqApiKey.isNotEmpty;
}
