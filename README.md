<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/tools/pub/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/to/develop-packages).
-->

# Foundation Models Framework
<p align="center">
  <a href="https://pub.dev/packages/foundation_models_framework">
    <img src="https://img.shields.io/pub/v/foundation_models_framework?label=pub.dev&color=blue" alt="Pub Version">
  </a>
  <a href="https://pub.dev/packages/foundation_models_framework/score">
    <img src="https://img.shields.io/pub/points/foundation_models_framework?color=green" alt="Pub Points">
  </a>
  <a href="https://pub.dev/packages/foundation_models_framework/score">
    <img src="https://img.shields.io/pub/popularity/foundation_models_framework?color=brightgreen" alt="Popularity">
  </a>
  <a href="https://opensource.org/licenses/MIT">
    <img src="https://img.shields.io/badge/license-MIT-yellow.svg" alt="License">
  </a>
  <img src="https://img.shields.io/badge/platform-iOS%2026%2B%20%7C%20macOS%2015%2B-lightgrey" alt="Platforms">
  <img src="https://img.shields.io/badge/status-BETA-orange" alt="Status">
</p>

> **⚠️ BETA STATUS**: This package is in beta. Core functionality including streaming is stable, but structured generation and tool calling features are still in development.

A Flutter package for integrating with Apple's Foundation Models framework on iOS and macOS devices. This package provides access to on-device AI capabilities through language model sessions, leveraging Apple Intelligence features.

## Features

- ✅ **Cross-Platform Support**: Works on both iOS 26.0+ and macOS 15.0+
- ✅ **Persistent Sessions**: Maintain conversation context across multiple interactions
- ✅ **Streaming Responses**: Real-time token streaming with delta updates
- ✅ **Tool/Function Calling**: Define tools that the model can request to call
- ✅ **Generation Options**: Control temperature, token limits, and sampling strategies
- ✅ **Transcript History**: Access full conversation history with role-based entries
- ✅ **Guardrail Levels**: Configure content safety levels (strict/standard/permissive)
- ✅ **Rich Responses**: Get detailed responses with raw content and transcript metadata
- ✅ **Security Features**: Built-in prompt validation and injection protection
- ✅ **Type-safe API**: Built with Pigeon for reliable platform communication
- ✅ **Privacy-First**: All processing happens on-device with Apple Intelligence

## Requirements

### For App Installation
- **iOS Minimum**: 15.0 or later (app can be installed, but features only work on iOS 26.0+)
- **macOS**: 15.0 or later
- **Flutter**: 3.0.0 or later
- **Dart**: 3.8.1 or later
- **Xcode**: 16.0 or later

### For Foundation Models Features
- **iOS**: 26.0 or later with Apple Intelligence enabled
- **macOS**: 15.0 or later with Apple Intelligence enabled

> **Important**: The package can be installed on iOS 15.0+ devices, but Foundation Models features will only function on iOS 26.0+ with Apple Intelligence. On unsupported devices, the `checkAvailability()` method will return an appropriate error.

## Installation

Add this package to your `pubspec.yaml`:

```yaml
dependencies:
  foundation_models_framework: ^0.2.0
```

Then run:

```bash
flutter pub get
```

## Apple Intelligence Requirement on macOS
To use this package on macOS, you must enable Apple Intelligence in your system settings.
Go to System `Settings → Apple Intelligence & Siri`, enable `Apple Intelligence`, and allow the system to finish downloading the required on-device models.
Without this step, the Foundation Models framework will not be available and the package will return an availability error.

</br>
<img width="703" height="259" alt="SCR-20251124-ndla-4" src="https://github.com/user-attachments/assets/d96e625d-882f-42b7-8e7f-2cf9113d9597" />



## iOS Setup

### 1. Update iOS Deployment Target

In your `ios/Podfile`, set the iOS deployment target to 15.0 or higher:

```ruby
platform :ios, '15.0'
```

> **Note**: While the app can be installed on iOS 15.0+, Foundation Models features will only work on iOS 26.0+ with Apple Intelligence. The package handles this gracefully through runtime availability checks.

### 2. Update iOS Project Settings

In your `ios/Runner.xcodeproj`, set:
- **iOS Deployment Target**: 15.0
- **Swift Language Version**: 5.0


## Usage

The package uses `weak_frameworks` for FoundationModels, allowing your app to be installed on iOS 15.0+ devices. Features will be dynamically enabled/disabled based on device capabilities at runtime.

### Device Compatibility

**Physical Device with iOS 26.0+ and Apple Intelligence:**
- Full Foundation Models functionality
- All features including tool calling and streaming
- Real-time AI processing on-device

**Physical Device with iOS 15.0 - 25.x:**
- App can be installed
- `checkAvailability()` will return appropriate error
- Foundation Models features are not available

**Simulator (Any iOS Version):**
- App can be installed
- Foundation Models is not available in simulators
- Use `FoundationModelsFramework.mock()` for testing

### Checking Availability

Before using Foundation Models features, check if they're available on the device:

```dart
import 'package:foundation_models_framework/foundation_models_framework.dart';

final foundationModels = FoundationModelsFramework.instance;

try {
  final availability = await foundationModels.checkAvailability();
  
  if (availability.isAvailable) {
    print('Foundation Models is available on iOS ${availability.osVersion}');
    // Proceed with AI operations
  } else {
    print('Foundation Models not available: ${availability.errorMessage}');
  }
} catch (e) {
  print('Error checking availability: $e');
}
```

### Creating a Language Model Session

Create a session to interact with Apple's Foundation Models:

```dart
// Create a basic session
final session = foundationModels.createSession();

// Create a session with custom instructions and guardrails
final customSession = foundationModels.createSession(
  instructions: 'You are a helpful assistant. Keep responses concise.',
  guardrailLevel: GuardrailLevel.standard,
);

// Send a prompt and get a response
try {
  final response = await session.respond(prompt: 'Hello, how are you?');

  if (response.errorMessage == null) {
    print('Response: ${response.content}');

    // Access transcript history
    if (response.transcriptEntries != null) {
      for (final entry in response.transcriptEntries!) {
        print('${entry?.role}: ${entry?.content}');
      }
    }
  } else {
    print('Error: ${response.errorMessage}');
  }
} catch (e) {
  print('Failed to get response: $e');
}

// Don't forget to dispose when done
await session.dispose();
```

### Using Generation Options

Control the model's generation behavior:

```dart
final session = foundationModels.createSession();

// Configure generation options
final options = GenerationOptionsRequest(
  temperature: 0.7,  // 0.0 = deterministic, 1.0 = creative
  maximumResponseTokens: 500,
  samplingTopK: 40,  // Top-K sampling
);

final response = await session.respond(
  prompt: 'Write a short story',
  options: options,
);

print('Generated: ${response.content}');
```

### Convenience Method for Single Prompts

For single interactions, you can use the convenience method:

```dart
try {
  final response = await foundationModels.sendPrompt(
    'What is the weather like today?',
    instructions: 'Be brief and factual',
    guardrailLevel: GuardrailLevel.strict,
    options: GenerationOptionsRequest(temperature: 0.3),
  );

  if (response.errorMessage == null) {
    print('Response: ${response.content}');
  } else {
    print('Error: ${response.errorMessage}');
  }
} catch (e) {
  print('Failed to send prompt: $e');
}
```

### Session-Based Conversation

For multi-turn conversations, reuse the same session:

```dart
final session = foundationModels.createSession();

// First interaction
var response = await session.respond(prompt: 'Tell me about Swift programming.');
print('AI: ${response.content}');

// Continue the conversation
response = await session.respond(prompt: 'Can you give me an example?');
print('AI: ${response.content}');

// Ask follow-up questions
response = await session.respond(prompt: 'How does that compare to Dart?');
print('AI: ${response.content}');

// Don't forget to dispose when done
await session.dispose();
```

### Streaming Responses

For real-time token streaming:

```dart
final session = foundationModels.createSession(
  instructions: 'You are a helpful assistant',
  guardrailLevel: GuardrailLevel.standard,
);

// Stream tokens as they're generated
final stream = session.streamResponse(
  prompt: 'Write a detailed explanation of quantum computing',
  options: GenerationOptionsRequest(
    temperature: 0.7,
    maximumResponseTokens: 1000,
  ),
);

// Process tokens as they arrive
await for (final chunk in stream) {
  if (chunk.delta != null) {
    print('New tokens: ${chunk.delta}');
  }

  if (chunk.isFinal) {
    print('Complete response: ${chunk.cumulative}');
  }

  if (chunk.hasError) {
    print('Error: ${chunk.errorMessage}');
    break;
  }
}
```

### Handling Stream Cancellation

You can cancel a stream at any time:

```dart
final stream = session.streamResponse(prompt: 'Long text generation...');

final subscription = stream.listen((chunk) {
  print('Received: ${chunk.delta}');

  // Cancel after receiving some content
  if (chunk.cumulative?.length ?? 0 > 100) {
    subscription.cancel(); // This will stop the stream
  }
});
```

### Tool/Function Calling

Tool calling allows the model to request execution of defined functions/tools as part of its response. This enables the model to interact with external systems, databases, or APIs to perform actions and retrieve real-time data.

#### Basic Tool Calling Workflow

```dart
// 1. Define your tools
final tools = [
  ToolDefinition(
    name: 'get_weather',
    description: 'Get the current weather for a specific location',
    parameters: ToolParameterSchema(
      type: 'object',
      properties: {
        'location': ToolParameterSchema(
          type: 'string',
          description: 'The city name, e.g. San Francisco',
        ),
        'unit': ToolParameterSchema(
          type: 'string',
          description: 'Temperature unit (celsius or fahrenheit)',
          enum: ['celsius', 'fahrenheit'],
        ),
      },
      required: ['location'],
    ),
  ),
  ToolDefinition(
    name: 'get_time',
    description: 'Get the current time in a specific timezone',
    parameters: ToolParameterSchema(
      type: 'object',
      properties: {
        'timezone': ToolParameterSchema(
          type: 'string',
          description: 'IANA timezone name, e.g. America/New_York',
        ),
      },
      required: ['timezone'],
    ),
  ),
];

// 2. Define a tool handler to execute tools
Future<String> handleToolCall(String toolName, String arguments) async {
  switch (toolName) {
    case 'get_weather':
      final args = jsonDecode(arguments) as Map<String, dynamic>;
      final location = args['location'] as String;
      final unit = args['unit'] as String? ?? 'celsius';
      // Call your weather API here
      return jsonEncode({
        'location': location,
        'temperature': 72,
        'unit': unit,
        'condition': 'sunny',
      });

    case 'get_time':
      final args = jsonDecode(arguments) as Map<String, dynamic>;
      final timezone = args['timezone'] as String;
      // Get current time for timezone
      return jsonEncode({
        'timezone': timezone,
        'current_time': DateTime.now().toIso8601String(),
      });

    default:
      throw UnimplementedError('Tool $toolName not implemented');
  }
}

// 3. Create a session with tool handler
final session = foundationModels.createSession(
  toolHandler: handleToolCall,
);

// 4. Use the automatic tool calling workflow
final response = await session.executeWithTools(
  prompt: 'What is the weather in San Francisco and the current time in New York?',
  tools: tools,
);

print('Final response: ${response.content}');
```

#### Manual Tool Calling

For more control, you can handle tool calls manually:

```dart
final session = foundationModels.createSession(
  toolHandler: handleToolCall,
);

// First prompt
var response = await session.respond(
  prompt: 'What is the weather in Tokyo?',
  tools: tools,
);

// Check if the model requested tool calls
if (response.toolCalls != null && response.toolCalls!.isNotEmpty) {
  print('Model requested ${response.toolCalls!.length} tool calls');

  // Execute each tool call
  final toolResults = <ToolResult>[];
  for (final toolCall in response.toolCalls!) {
    print('Executing tool: ${toolCall.name}');
    print('Arguments: ${toolCall.arguments}');

    try {
      final result = await handleToolCall(toolCall.name, toolCall.arguments);
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

  // Send tool results back to the model
  response = await session.respond(
    prompt: '', // Empty prompt when just sending tool results
    tools: tools,
    toolResults: toolResults,
  );
}

print('Final response: ${response.content}');

await session.dispose();
```

#### Advanced Tool Definition with Complex Parameters

```dart
final tools = [
  ToolDefinition(
    name: 'search_database',
    description: 'Search a database of products',
    parameters: ToolParameterSchema(
      type: 'object',
      properties: {
        'query': ToolParameterSchema(
          type: 'string',
          description: 'The search query',
        ),
        'filters': ToolParameterSchema(
          type: 'object',
          description: 'Optional filters to apply',
          properties: {
            'category': ToolParameterSchema(type: 'string'),
            'minPrice': ToolParameterSchema(type: 'number'),
            'maxPrice': ToolParameterSchema(type: 'number'),
            'inStock': ToolParameterSchema(type: 'boolean'),
          },
        ),
        'sortBy': ToolParameterSchema(
          type: 'string',
          enum: ['relevance', 'price_asc', 'price_desc', 'name'],
        ),
        'limit': ToolParameterSchema(
          type: 'integer',
          description: 'Maximum number of results (1-100)',
          minimum: 1,
          maximum: 100,
        ),
      },
      required: ['query'],
    ),
  ),
];
```

#### Tool Calling with Streaming

Tool calling also works with streaming responses:

```dart
final session = foundationModels.createSession(
  toolHandler: handleToolCall,
);

// Stream the initial response
final stream = session.streamResponse(
  prompt: 'What is the weather in Paris?',
  tools: tools,
);

await for (final chunk in stream) {
  if (chunk.isFinal) {
    // The final chunk may contain tool calls
    if (chunk.toolCalls != null && chunk.toolCalls!.isNotEmpty) {
      // Execute tools and send results back
      final response = ChatResponse(
        content: chunk.cumulative ?? '',
        toolCalls: chunk.toolCalls,
      );

      // Continue with tool results...
    }
  }
}
```

#### Error Handling in Tool Calling

```dart
Future<String> safeToolHandler(String toolName, String arguments) async {
  try {
    return await handleToolCall(toolName, arguments);
  } on SocketException catch (e) {
    return jsonEncode({
      'error': 'Network error',
      'message': e.toString(),
    });
  } on FormatException catch (e) {
    return jsonEncode({
      'error': 'Invalid arguments format',
      'message': e.toString(),
    });
  } catch (e) {
    return jsonEncode({
      'error': 'Unexpected error',
      'message': e.toString(),
    });
  }
}
```

## API Reference

### FoundationModelsFramework

The main class for accessing Foundation Models functionality.

#### Methods

##### `checkAvailability()`
- **Returns**: `Future<AvailabilityResponse>`
- **Description**: Checks if Foundation Models is available on the device
- **Note**: Returns true only if iOS 26.0+/macOS 15.0+ and Apple Intelligence is available

##### `createSession({String? instructions, GuardrailLevel? guardrailLevel, ToolHandler? toolHandler})`
- **Parameters**:
  - `instructions`: Optional system instructions for the session
  - `guardrailLevel`: Content safety level (strict/standard/permissive)
  - `toolHandler`: Optional callback for handling tool execution requests
- **Returns**: `LanguageModelSession`
- **Description**: Creates a new language model session with optional configuration

##### `sendPrompt(String prompt, {String? instructions, GuardrailLevel? guardrailLevel, GenerationOptionsRequest? options})`
- **Parameters**:
  - `prompt`: The text prompt to send
  - `instructions`: Optional system instructions
  - `guardrailLevel`: Optional content safety level
  - `options`: Optional generation configuration
- **Returns**: `Future<ChatResponse>`
- **Description**: Convenience method to send a single prompt without managing a session

### LanguageModelSession

A persistent session for interacting with Apple's Foundation Models.

#### Methods

##### `respond({required String prompt, GenerationOptionsRequest? options, List<ToolDefinition>? tools, List<ToolResult>? toolResults})`
- **Parameters**:
  - `prompt`: The text prompt to send to the model
  - `options`: Optional generation configuration
  - `tools`: Optional list of tools the model can call
  - `toolResults`: Optional list of tool execution results from previous calls
- **Returns**: `Future<ChatResponse>`
- **Description**: Sends a prompt to the language model and returns the response. If tool calls are requested, they will be included in the response.

##### `executeWithTools({required String prompt, required List<ToolDefinition> tools, GenerationOptionsRequest? options, int maxIterations = 5})`
- **Parameters**:
  - `prompt`: The text prompt to send to the model
  - `tools`: List of tools the model can call
  - `options`: Optional generation configuration
  - `maxIterations`: Maximum number of tool call iterations (default: 5)
- **Returns**: `Future<ChatResponse>`
- **Description**: Automatically handles the complete tool calling workflow - sends prompt, executes tools via the toolHandler, sends results back, and returns the final response
- **Note**: Requires `toolHandler` to be set when creating the session

##### `prewarm()`
- **Returns**: `Future<void>`
- **Description**: Pre-warms the session to reduce first-token latency

##### `dispose()`
- **Returns**: `Future<void>`
- **Description**: Disposes of the session and releases resources

##### `streamResponse({required String prompt, GenerationOptionsRequest? options, List<ToolDefinition>? tools, List<ToolResult>? toolResults})`
- **Parameters**:
  - `prompt`: The text prompt to send to the model
  - `options`: Optional generation configuration
  - `tools`: Optional list of tools the model can call
  - `toolResults`: Optional list of tool execution results from previous calls
- **Returns**: `Stream<StreamChunk>`
- **Description**: Streams response tokens in real-time as they are generated

### Data Classes

#### `AvailabilityResponse`
- `bool isAvailable`: Whether Foundation Models is available
- `String osVersion`: The OS version
- `String? reasonCode`: Structured reason code if unavailable
- `String? errorMessage`: Human-readable error message

#### `ChatResponse`
- `String content`: The response content from the model
- `String? rawContent`: Raw response data
- `List<TranscriptEntry?>? transcriptEntries`: Conversation history
- `String? errorMessage`: Error message if the request failed
- `List<ToolCall>? toolCalls`: Tool calls requested by the model (if any)

#### `ToolDefinition`
- `String name`: The unique name/identifier of the tool
- `String? description`: Description of what the tool does
- `ToolParameterSchema? parameters`: Schema defining the tool's input parameters

#### `ToolCall`
- `String id`: Unique identifier for this tool call
- `String name`: Name of the tool being called
- `String arguments`: JSON string containing the arguments for the tool call

#### `ToolResult`
- `String toolCallId`: ID of the tool call this result is for
- `String content`: The result of the tool execution (typically JSON)

#### `ToolParameterSchema`
- `String type`: The data type (e.g., 'string', 'number', 'object', 'array')
- `String? description`: Description of the parameter
- `Map<String, ToolParameterSchema>? properties`: For object types, the nested properties
- `List<String>? required`: List of required property names
- `ToolParameterSchema? items`: For array types, the schema of array items
- `List<String>? enum`: Optional list of allowed values

#### `ToolHandler`
- **Type**: `Future<String> Function(String toolName, String arguments)`
- **Description**: Callback function type for handling tool execution
- **Parameters**:
  - `toolName`: Name of the tool to execute
  - `arguments`: JSON string of tool arguments
- **Returns**: Future completing with the tool result (typically JSON string)

#### `TranscriptEntry`
- `String id`: Unique identifier for the entry
- `String role`: Role (user/assistant/instructions/etc.)
- `String content`: The text content
- `List<String>? segments`: Individual text segments

#### `GenerationOptionsRequest`
- `double? temperature`: Controls randomness (0.0-1.0)
- `int? maximumResponseTokens`: Maximum tokens to generate
- `int? samplingTopK`: Top-K sampling parameter
- `double? samplingProbabilityThreshold`: Probability threshold for sampling

#### `GuardrailLevel`
- `strict`: Maximum content safety
- `standard`: Balanced safety and flexibility
- `permissive`: More permissive content transformations

#### `StreamChunk`
- `String streamId`: Unique identifier for the stream
- `String? delta`: New tokens in this chunk
- `String? cumulative`: All tokens received so far
- `String? rawContent`: Raw response data
- `bool isFinal`: Whether this is the last chunk
- `String? errorCode`: Error code if streaming failed
- `String? errorMessage`: Error message if streaming failed
- `bool hasError`: Convenience getter for error checking

## Error Handling

The package handles errors gracefully and returns them in the response:

```dart
try {
  final response = await session.respond(prompt: 'Your prompt here');
  
  if (response.errorMessage != null) {
    // Handle specific errors
    switch (response.errorMessage) {
             case 'Foundation Models requires iOS 26.0 or later':
        print('Device not supported');
        break;
      case 'Foundation Models not available on this device':
        print('Apple Intelligence not available');
        break;
      default:
        print('Error: ${response.errorMessage}');
    }
  } else {
    print('Success: ${response.content}');
  }
} catch (e) {
  print('Unexpected error: $e');
}
```



## Important Notes

### Device Compatibility
- **App Installation**: Requires iOS 15.0+ (using weak_frameworks for FoundationModels)
- **Feature Availability**: Foundation Models features require iOS 26.0+ with Apple Intelligence
- **Graceful Degradation**: The package handles availability checks at runtime and returns appropriate errors
- **Simulators**: Foundation Models is not available in simulators (use mock for testing)
- Only works on Apple Intelligence-enabled devices in supported regions

### Architecture
- The package uses `weak_frameworks` to link FoundationModels, which allows the app to build and install on iOS 15.0+
- At runtime, the framework is only loaded on iOS 26.0+ devices with Apple Intelligence
- On unsupported devices, `checkAvailability()` returns a descriptive error message
- This enables a single app binary to support both older devices (without AI features) and newer devices (with AI features)

### Privacy and Performance
- All processing happens on-device using Apple's Foundation Models
- No data is sent to external servers
- Performance may vary based on device capabilities

### Development Considerations
- Always check availability before using features
- Handle errors gracefully for better user experience
- Consider providing fallback options for unsupported devices
- Test on actual devices with Apple Intelligence enabled
- Use `FoundationModelsFramework.mock()` for testing in simulators or on older devices

## Example App

The package includes a complete example app demonstrating:
- Availability checking
- Session creation and management
- Prompt-response interactions
- Error handling

Run the example:

```bash
cd example
flutter run
```

## Contributing

Contributions are welcome! Submit pull requests for any improvements.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for details about changes in each version.

## Support

For issues and questions:
- Create an issue on GitHub
- Check the example app for usage patterns
- Review Apple's Foundation Models documentation
- Check Apple's iOS 26.0+ release notes for hardware compatibility

## References

This package implementation is based on Apple's Foundation Models framework:

- **[Apple Developer Documentation](https://developer.apple.com/documentation/foundationmodels)**: Official API reference
---

**Important**: This package integrates with Apple's Foundation Models framework. Ensure you comply with Apple's terms of service and review their documentation for production use.
