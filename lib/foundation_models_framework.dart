export 'src/foundation_models_api.g.dart';

import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math';

import 'package:flutter/services.dart';

import 'src/foundation_models_api.g.dart';

/// Callback type for handling tool execution requests.
typedef ToolHandler = Future<String> Function(String toolName, String arguments);

/// Guardrail configuration levels matching native guardrail options.
enum GuardrailLevel { strict, standard, permissive }

extension _GuardrailLevelValue on GuardrailLevel {
  String get value {
    switch (this) {
      case GuardrailLevel.strict:
        return 'strict';
      case GuardrailLevel.standard:
        return 'standard';
      case GuardrailLevel.permissive:
        return 'permissive';
    }
  }
}

/// Represents a streaming chunk emitted by Foundation Models.
class StreamChunk {
  const StreamChunk({
    required this.streamId,
    this.delta,
    this.cumulative,
    this.rawContent,
    required this.isFinal,
    this.errorCode,
    this.errorMessage,
  });

  factory StreamChunk.fromMap(Map<dynamic, dynamic> map) {
    return StreamChunk(
      streamId: map['streamId'] as String,
      delta: map['delta'] as String?,
      cumulative: map['cumulative'] as String?,
      rawContent: map['rawContent'] as String?,
      isFinal: map['isFinal'] as bool? ?? false,
      errorCode: map['errorCode'] as String?,
      errorMessage: map['errorMessage'] as String?,
    );
  }

  final String streamId;
  final String? delta;
  final String? cumulative;
  final String? rawContent;
  final bool isFinal;
  final String? errorCode;
  final String? errorMessage;

  bool get hasError => errorMessage != null || errorCode != null;
}

/// A language model session for interacting with Apple's Foundation Models framework.
///
/// This class manages lifecycle operations required by the native SDK, including
/// session creation, prewarming, prompt routing, and teardown.
class LanguageModelSession {
  LanguageModelSession({
    this.instructions,
    this.guardrailLevel,
    FoundationModelsApi? api,
    bool isMock = false,
    this.toolHandler,
  }) : _api = api ?? FoundationModelsApi(),
       _isMock = isMock,
       _sessionId = _generateSessionId();

  final FoundationModelsApi _api;
  final bool _isMock;
  final String _sessionId;
  final String? instructions;
  final GuardrailLevel? guardrailLevel;
  final ToolHandler? toolHandler;

  bool _isInitialized = false;
  List<ToolDefinition>? _registeredTools;

  /// Lazily initialize the native session if needed.
  Future<void> _ensureInitialized() async {
    if (_isMock || _isInitialized) {
      return;
    }

    final request = SessionRequest(
      sessionId: _sessionId,
      instructions: instructions,
      guardrailLevel: guardrailLevel?.value,
    );
    await _api.createSession(request);
    _isInitialized = true;
  }

  /// Prewarm the session to reduce first-token latency.
  Future<void> prewarm() async {
    if (_isMock) {
      return;
    }
    await _ensureInitialized();
    await _api.prewarmSession(_sessionId);
  }

  /// Send a prompt to the language model and get a structured response.
  Future<ChatResponse> respond({
    required String prompt,
    GenerationOptionsRequest? options,
    List<ToolDefinition>? tools,
    List<ToolResult>? toolResults,
  }) async {
    if (_isMock) {
      return ChatResponse(
        content: 'Mock response to: $prompt',
        rawContent: 'mock',
        transcriptEntries: <TranscriptEntry?>[
          TranscriptEntry(
            id: 'mock-user',
            role: 'user',
            content: prompt,
            segments: <String>[prompt],
          ),
          TranscriptEntry(
            id: 'mock-assistant',
            role: 'assistant',
            content: 'Mock response to: $prompt',
            segments: <String>['Mock response to: $prompt'],
          ),
        ],
        errorMessage: null,
      );
    }

    await _ensureInitialized();

    // Store tools for subsequent requests in this session
    if (tools != null) {
      _registeredTools = tools;
    }

    final request = ChatRequest(
      sessionId: _sessionId,
      prompt: prompt,
      options: options,
      tools: tools ?? _registeredTools,
      toolResults: toolResults,
    );

    return _api.sendPromptToSession(request);
  }

  /// Stream tokens from the language model in real time.
  Stream<StreamChunk> streamResponse({
    required String prompt,
    GenerationOptionsRequest? options,
    List<ToolDefinition>? tools,
    List<ToolResult>? toolResults,
  }) {
    final streamId = _generateStreamId();

    if (_isMock) {
      final content = 'Mock response to: $prompt';
      final chunk = StreamChunk(
        streamId: streamId,
        delta: content,
        cumulative: content,
        rawContent: 'mock',
        isFinal: true,
        errorCode: null,
        errorMessage: null,
      );
      return Stream<StreamChunk>.value(chunk);
    }

    // Store tools for subsequent requests in this session
    if (tools != null) {
      _registeredTools = tools;
    }

    final controller = StreamController<StreamChunk>();
    late StreamSubscription<dynamic> subscription;
    bool completed = false;

    subscription = _streamBroadcast
        .map(
          (dynamic event) =>
              StreamChunk.fromMap(event as Map<dynamic, dynamic>),
        )
        .where((chunk) => chunk.streamId == streamId)
        .listen(
          (chunk) {
            controller.add(chunk);

            if (chunk.isFinal) {
              completed = true;
              subscription.cancel();
              controller.close();
            }
          },
          onError: (Object error, StackTrace stack) {
            if (!completed) {
              controller.addError(error, stack);
            }
          },
        );

    () async {
      try {
        await _ensureInitialized();
        final request = ChatStreamRequest(
          streamId: streamId,
          sessionId: _sessionId,
          prompt: prompt,
          options: options,
          tools: tools ?? _registeredTools,
          toolResults: toolResults,
        );
        await _api.startStream(request);
      } catch (error, stack) {
        completed = true;
        await subscription.cancel();
        if (!controller.isClosed) {
          controller.addError(error, stack);
          await controller.close();
        }
      }
    }();

    controller.onCancel = () async {
      await subscription.cancel();
      if (!completed) {
        try {
          await _api.stopStream(streamId);
        } finally {
          completed = true;
        }
      }
    };

    return controller.stream;
  }

  /// Execute a tool call workflow: send prompt, handle tool calls automatically, and return final response.
  ///
  /// This method handles the complete tool calling loop:
  /// 1. Sends the initial prompt with tools
  /// 2. If the model requests tool calls, executes them using [toolHandler]
  /// 3. Sends tool results back to the model
  /// 4. Returns the final response
  ///
  /// Requires [toolHandler] to be set in the session.
  Future<ChatResponse> executeWithTools({
    required String prompt,
    required List<ToolDefinition> tools,
    GenerationOptionsRequest? options,
    int maxIterations = 5,
  }) async {
    if (toolHandler == null) {
      throw StateError('toolHandler must be set to use executeWithTools');
    }

    var currentPrompt = prompt;
    var iteration = 0;

    while (iteration < maxIterations) {
      final response = await respond(
        prompt: currentPrompt,
        options: options,
        tools: tools,
      );

      // If no tool calls, return the response
      if (response.toolCalls == null || response.toolCalls!.isEmpty) {
        return response;
      }

      // Execute tool calls
      final toolResults = <ToolResult>[];
      for (final toolCall in response.toolCalls!) {
        try {
          final result = await toolHandler!(toolCall.name, toolCall.arguments);
          toolResults.add(ToolResult(
            toolCallId: toolCall.id,
            content: result,
          ));
        } catch (e) {
          toolResults.add(ToolResult(
            toolCallId: toolCall.id,
            content: 'Error: $e',
          ));
        }
      }

      // Send tool results back
      final followUpResponse = await respond(
        prompt: '',  // Empty prompt when just sending tool results
        options: options,
        tools: tools,
        toolResults: toolResults,
      );

      // If the model made more tool calls, continue the loop
      if (followUpResponse.toolCalls != null &&
          followUpResponse.toolCalls!.isNotEmpty) {
        iteration++;
        continue;
      }

      return followUpResponse;
    }

    throw StateError('Maximum tool iterations exceeded');
  }

  /// Dispose of the native session resources.
  Future<void> dispose() async {
    if (_isMock || !_isInitialized) {
      return;
    }
    await _api.disposeSession(_sessionId);
    _isInitialized = false;
  }

  static final Random _random = Random();

  static String _generateSessionId() {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final randomBits = _random.nextInt(0x7fffffff);
    return 'session-$timestamp-$randomBits';
  }

  static String _generateStreamId() {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final randomBits = _random.nextInt(0x7fffffff);
    return 'stream-$timestamp-$randomBits';
  }

  static const EventChannel _streamChannel = EventChannel(
    'dev.flutter.pigeon.foundation_models_framework/stream',
  );

  static final Stream<dynamic> _streamBroadcast = _streamChannel
      .receiveBroadcastStream()
      .asBroadcastStream();
}

/// Main class for interacting with Apple's Foundation Models framework.
class FoundationModelsFramework {
  FoundationModelsFramework._internal()
    : _api = FoundationModelsApi(),
      _isMock = false;
  FoundationModelsFramework._mock()
    : _api = FoundationModelsApi(),
      _isMock = true;

  static final FoundationModelsFramework _instance =
      FoundationModelsFramework._internal();

  static FoundationModelsFramework get instance => _instance;

  final FoundationModelsApi _api;
  final bool _isMock;

  /// Create a mock instance for testing in simulators or development
  factory FoundationModelsFramework.mock() {
    return FoundationModelsFramework._mock();
  }

  /// Check if Foundation Models framework is available on the current device.
  Future<AvailabilityResponse> checkAvailability() async {
    if (_isMock) {
      return AvailabilityResponse(
        isAvailable: false,
        osVersion: Platform.operatingSystemVersion,
        reasonCode: 'mock',
        errorMessage:
            'Mock implementation - Foundation Models requires physical device with iOS 26.0+ and Apple Intelligence',
      );
    }
    return _api.checkAvailability();
  }

  /// Create a new language model session.
  LanguageModelSession createSession({
    String? instructions,
    GuardrailLevel? guardrailLevel,
    ToolHandler? toolHandler,
  }) {
    if (_isMock) {
      return LanguageModelSession(
        instructions: instructions,
        guardrailLevel: guardrailLevel,
        api: _api,
        isMock: true,
        toolHandler: toolHandler,
      );
    }
    return LanguageModelSession(
      instructions: instructions,
      guardrailLevel: guardrailLevel,
      api: _api,
      toolHandler: toolHandler,
    );
  }

  /// Convenience method to send a single prompt without managing a session.
  Future<ChatResponse> sendPrompt(
    String prompt, {
    String? instructions,
    GuardrailLevel? guardrailLevel,
    GenerationOptionsRequest? options,
  }) async {
    final session = createSession(
      instructions: instructions,
      guardrailLevel: guardrailLevel,
    );
    try {
      return await session.respond(prompt: prompt, options: options);
    } finally {
      await session.dispose();
    }
  }
}
