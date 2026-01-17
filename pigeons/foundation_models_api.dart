import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/src/foundation_models_api.g.dart',
    swiftOut: 'ios/Classes/FoundationModelsApi.g.swift',
    dartPackageName: 'foundation_models_framework',
  ),
)
/// Data class describing a tool parameter schema for function calling
class ToolParameterSchema {
  const ToolParameterSchema({
    required this.type,
    this.description,
    this.properties,
    this.required,
    this.items,
  });

  final String type;
  final String? description;
  final Map<String, ToolParameterSchema>? properties;
  final List<String>? required;
  final ToolParameterSchema? items;
}

/// Data class describing a tool/function that can be called by the model
class ToolDefinition {
  const ToolDefinition({
    required this.name,
    this.description,
    this.parameters,
  });

  final String name;
  final String? description;
  final ToolParameterSchema? parameters;
}

/// Data class representing a tool call made by the model
class ToolCall {
  const ToolCall({
    required this.id,
    required this.name,
    required this.arguments,
  });

  final String id;
  final String name;
  final String arguments;
}

/// Data class representing the result of a tool execution
class ToolResult {
  const ToolResult({
    required this.toolCallId,
    required this.content,
  });

  final String toolCallId;
  final String content;
}

/// Data class describing GenerationOptions sent from Dart to Swift.
class GenerationOptionsRequest {
  const GenerationOptionsRequest({
    this.temperature,
    this.maximumResponseTokens,
    this.samplingTopK,
    this.samplingProbabilityThreshold,
  });

  final double? temperature;
  final int? maximumResponseTokens;
  final int? samplingTopK;
  final double? samplingProbabilityThreshold;
}

/// Data class for chat request routed to an existing session
class ChatRequest {
  const ChatRequest({
    required this.sessionId,
    required this.prompt,
    this.options,
    this.tools,
    this.toolResults,
  });

  final String sessionId;
  final String prompt;
  final GenerationOptionsRequest? options;
  final List<ToolDefinition>? tools;
  final List<ToolResult>? toolResults;
}

/// Data class for streaming request routed to an existing session.
class ChatStreamRequest {
  const ChatStreamRequest({
    required this.streamId,
    required this.sessionId,
    required this.prompt,
    this.options,
    this.tools,
    this.toolResults,
  });

  final String streamId;
  final String sessionId;
  final String prompt;
  final GenerationOptionsRequest? options;
  final List<ToolDefinition>? tools;
  final List<ToolResult>? toolResults;
}

/// Data class for transcript entries returned from Swift
class TranscriptEntry {
  const TranscriptEntry({
    required this.id,
    required this.role,
    required this.content,
    this.segments,
  });

  final String id;
  final String role;
  final String content;
  final List<String>? segments;
}

/// Data class for chat response
class ChatResponse {
  const ChatResponse({
    required this.content,
    this.rawContent,
    this.transcriptEntries,
    this.errorMessage,
    this.toolCalls,
  });

  final String content;
  final String? rawContent;
  final List<TranscriptEntry?>? transcriptEntries;
  final String? errorMessage;
  final List<ToolCall>? toolCalls;
}

/// Data class describing a request to create or configure a session
class SessionRequest {
  const SessionRequest({
    required this.sessionId,
    this.instructions,
    this.guardrailLevel,
  });

  final String sessionId;
  final String? instructions;
  final String? guardrailLevel;
}

/// Data class for availability check response
class AvailabilityResponse {
  const AvailabilityResponse({
    required this.isAvailable,
    required this.osVersion,
    this.reasonCode,
    this.errorMessage,
  });

  final bool isAvailable;
  final String osVersion;
  final String? reasonCode;
  final String? errorMessage;
}

/// Host API for Foundation Models operations
@HostApi()
abstract class FoundationModelsApi {
  /// Check if Foundation Models framework is available on the device
  @async
  AvailabilityResponse checkAvailability();

  /// Create or update a session with the provided identifier
  @async
  void createSession(SessionRequest request);

  /// Prewarm a session to reduce first-token latency
  @async
  void prewarmSession(String sessionId);

  /// Send a prompt to an existing session and receive a structured response
  @async
  ChatResponse sendPromptToSession(ChatRequest request);

  /// Dispose of an existing session and release native resources
  @async
  void disposeSession(String sessionId);

  /// Start a streaming response for a prompt using an existing session
  @async
  void startStream(ChatStreamRequest request);

  /// Cancel an active streaming response
  @async
  void stopStream(String streamId);
}
