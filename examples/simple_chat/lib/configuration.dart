/// Enum for selecting which AI backend to use.
enum AiBackend {
  /// Use Firebase AI
  firebase,

  /// Use Google Generative AI
  googleGenerativeAi,
}

/// Configuration for which AI backend to use.
/// Change this value to switch between backends.
const AiBackend aiBackend = AiBackend.googleGenerativeAi;
