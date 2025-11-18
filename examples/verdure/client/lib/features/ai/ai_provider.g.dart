// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// A provider for the A2A server URL.

@ProviderFor(a2aServerUrl)
const a2aServerUrlProvider = A2aServerUrlProvider._();

/// A provider for the A2A server URL.

final class A2aServerUrlProvider
    extends $FunctionalProvider<AsyncValue<String>, String, FutureOr<String>>
    with $FutureModifier<String>, $FutureProvider<String> {
  /// A provider for the A2A server URL.
  const A2aServerUrlProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'a2aServerUrlProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$a2aServerUrlHash();

  @$internal
  @override
  $FutureProviderElement<String> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String> create(Ref ref) {
    return a2aServerUrl(ref);
  }
}

String _$a2aServerUrlHash() => r'fb16ccf2eefdfdf9b81b39fde313a810d4a46b7d';

/// A provider for the A2UI agent connector.

@ProviderFor(a2uiAgentConnector)
const a2uiAgentConnectorProvider = A2uiAgentConnectorProvider._();

/// A provider for the A2UI agent connector.

final class A2uiAgentConnectorProvider
    extends
        $FunctionalProvider<
          AsyncValue<A2uiAgentConnector>,
          A2uiAgentConnector,
          FutureOr<A2uiAgentConnector>
        >
    with
        $FutureModifier<A2uiAgentConnector>,
        $FutureProvider<A2uiAgentConnector> {
  /// A provider for the A2UI agent connector.
  const A2uiAgentConnectorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'a2uiAgentConnectorProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$a2uiAgentConnectorHash();

  @$internal
  @override
  $FutureProviderElement<A2uiAgentConnector> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<A2uiAgentConnector> create(Ref ref) {
    return a2uiAgentConnector(ref);
  }
}

String _$a2uiAgentConnectorHash() =>
    r'e5a3ac7de14b11c412702a3b07acce472a57d77d';

/// The AI provider.

@ProviderFor(Ai)
const aiProvider = AiProvider._();

/// The AI provider.
final class AiProvider extends $AsyncNotifierProvider<Ai, AiClientState> {
  /// The AI provider.
  const AiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'aiProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$aiHash();

  @$internal
  @override
  Ai create() => Ai();
}

String _$aiHash() => r'52d35fd967ce52d5fc89c3852302e91409c88b68';

/// The AI provider.

abstract class _$Ai extends $AsyncNotifier<AiClientState> {
  FutureOr<AiClientState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<AiClientState>, AiClientState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<AiClientState>, AiClientState>,
              AsyncValue<AiClientState>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
