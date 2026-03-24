// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// TODO(polina-c): move this to leak_tracker package and
// document pure dart leak tracking.
// Do not publish this API.
const bool kTrackLeaks = bool.fromEnvironment('leak_tracker.track_leaks');

const bool kReleaseMode = bool.fromEnvironment('dart.vm.product');
