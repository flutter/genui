/// Signature of callbacks that have no arguments and return no data.
typedef VoidCallback = void Function();

// TODO(polinach): move to leak_tracker.
const bool kTrackMemoryLeaks = bool.fromEnvironment(
  'leak_tracker.track_memory_leaks',
);
