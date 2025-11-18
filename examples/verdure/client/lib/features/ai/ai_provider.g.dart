// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// A provider for the A2UI agent connector.

@ProviderFor(a2uiAgentConnector)
const a2uiAgentConnectorProvider = A2uiAgentConnectorProvider._();

/// A provider for the A2UI agent connector.

final class A2uiAgentConnectorProvider
    extends
        $FunctionalProvider<
          A2uiAgentConnector,
          A2uiAgentConnector,
          A2uiAgentConnector
        >
    with $Provider<A2uiAgentConnector> {
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
  $ProviderElement<A2uiAgentConnector> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  A2uiAgentConnector create(Ref ref) {
    return a2uiAgentConnector(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(A2uiAgentConnector value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<A2uiAgentConnector>(value),
    );
  }
}

String _$a2uiAgentConnectorHash() =>
    r'f0d18a323b98dbac590cc8c5d4017f052b689efc';

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

String _$aiHash() => r'b1c6a122ca56bcc4a8de14dbf41dbe59e57fa4c1';

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
