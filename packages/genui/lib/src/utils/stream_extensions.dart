import 'dart:async';
import 'package:stream_transform/stream_transform.dart';

/// Extensions for [Iterable] of [Stream]s.
extension CombineLatestAll<T> on Iterable<Stream<T>> {
  /// Combines all streams in this iterable into a single stream that emits a
  /// list of the latest values from each stream.
  ///
  /// The resulting stream will not emit until every stream in the iterable has
  /// emitted at least one value.
  Stream<List<T>> combineLatestAll() {
    if (isEmpty) return Stream.value([]);

    return first.combineLatestAll(skip(1));
  }
}

/// Extensions for [Stream].
extension SwitchMapExtension<T> on Stream<T> {
  /// Maps each event to a new stream, and switches to emitting events from
  /// the most recent inner stream.
  Stream<R> switchMap<R>(Stream<R> Function(T) convert) {
    late StreamController<R> controller;
    StreamSubscription<T>? outerSubscription;
    StreamSubscription<R>? innerSubscription;

    void cancelInner() {
      innerSubscription?.cancel();
      innerSubscription = null;
    }

    controller = StreamController<R>(
      sync: true,
      onListen: () {
        outerSubscription = listen(
          (event) {
            cancelInner();
            final Stream<R> innerStream = convert(event);
            innerSubscription = innerStream.listen(
              (innerEvent) => controller.add(innerEvent),
              onError: (Object error, StackTrace? stackTrace) =>
                  controller.addError(error, stackTrace),
              onDone: () {
                if (outerSubscription == null) {
                  controller.close();
                }
              },
            );
          },
          onError: (Object error, StackTrace? stackTrace) =>
              controller.addError(error, stackTrace),
          onDone: () {
            if (innerSubscription == null) {
              controller.close();
            }
          },
        );
      },
      onCancel: () {
        cancelInner();
        outerSubscription?.cancel();
        outerSubscription = null;
      },
    );

    return controller.stream;
  }
}
