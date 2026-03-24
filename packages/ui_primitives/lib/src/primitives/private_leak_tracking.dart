import 'package:leak_tracker/leak_tracker.dart';

// TODO(polinach): move this constant to leak_tracker package.
const bool kTrackMemoryLeaks = bool.fromEnvironment(
  'leak_tracker.track_memory_leaks',
);

/// The name of this library.
///
/// Private, used for leak tracking.
const String _thisLibraryName = 'package:ui_primitives/ui_primitives.dart';

/// If leak tracking is enabled, dispatch object creation.
///
/// Should be called only from within an assert.
///
/// Returns true to make it easier to be wrapped into `assert`.
bool debugMaybeDispatchCreated(String className, Object object) {
  if (kTrackMemoryLeaks) {
    LeakTracking.dispatchObjectCreated(
      library: _thisLibraryName,
      className: className,
      object: object,
    );
  }
  return true;
}

/// If leak tracking is enabled, dispatch object disposal.
///
/// Should be called only from within an assert.
///
/// Returns true to make it easier to be wrapped into `assert`.
bool debugMaybeDispatchDisposed(Object object) {
  if (kTrackMemoryLeaks) {
    LeakTracking.dispatchObjectDisposed(object: object);
  }
  return true;
}
