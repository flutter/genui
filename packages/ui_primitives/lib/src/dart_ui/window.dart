import 'geometry.dart';

/// A configurable display that a [FlutterView] renders on.
///
/// Use [FlutterView.display] to get the current display for that view.
class Display {
  const Display._({
    required this.id,
    required this.devicePixelRatio,
    required this.size,
    required this.refreshRate,
  });

  /// A unique identifier for this display.
  ///
  /// This identifier is unique among a list of displays the Flutter framework
  /// is aware of, and is not derived from any platform specific identifiers for
  /// displays.
  final int id;

  /// The device pixel ratio of this display.
  ///
  /// This value is the same as the value of [FlutterView.devicePixelRatio] for
  /// all view objects attached to this display.
  final double devicePixelRatio;

  /// The physical size of this display.
  final Size size;

  /// The refresh rate in FPS of this display.
  final double refreshRate;

  @override
  String toString() =>
      'Display(id: $id, size: $size, devicePixelRatio: $devicePixelRatio, refreshRate: $refreshRate)';
}

// /// A view into which a Flutter [Scene] is drawn.
// ///
// /// Each [FlutterView] has its own layer tree that is rendered
// /// whenever [render] is called on it with a [Scene].
// ///
// /// References to [FlutterView] objects are obtained via the [PlatformDispatcher].
// ///
// /// ## Insets and Padding
// ///
// /// {@animation 300 300 https://flutter.github.io/assets-for-api-docs/assets/widgets/window_padding.mp4}
// ///
// /// In this illustration, the black areas represent system UI that the app
// /// cannot draw over. The red area represents view padding that the view may not
// /// be able to detect gestures in and may not want to draw in. The grey area
// /// represents the system keyboard, which can cover over the bottom view padding
// /// when visible.
// ///
// /// The [viewInsets] are the physical pixels which the operating
// /// system reserves for system UI, such as the keyboard, which would fully
// /// obscure any content drawn in that area.
// ///
// /// The [viewPadding] are the physical pixels on each side of the
// /// display that may be partially obscured by system UI or by physical
// /// intrusions into the display, such as an overscan region on a television or a
// /// "notch" on a phone. Unlike the insets, these areas may have portions that
// /// show the user view-painted pixels without being obscured, such as a
// /// notch at the top of a phone that covers only a subset of the area. Insets,
// /// on the other hand, either partially or fully obscure the window, such as an
// /// opaque keyboard or a partially translucent status bar, which cover an area
// /// without gaps.
// ///
// /// The [padding] property is computed from both
// /// [viewInsets] and [viewPadding]. It will allow a
// /// view inset to consume view padding where appropriate, such as when a phone's
// /// keyboard is covering the bottom view padding and so "absorbs" it.
// ///
// /// Clients that want to position elements relative to the view padding
// /// regardless of the view insets should use the [viewPadding]
// /// property, e.g. if you wish to draw a widget at the center of the screen with
// /// respect to the iPhone "safe area" regardless of whether the keyboard is
// /// showing.
// ///
// /// [padding] is useful for clients that want to know how much
// /// padding should be accounted for without concern for the current inset(s)
// /// state, e.g. determining whether a gesture should be considered for scrolling
// /// purposes. This value varies based on the current state of the insets. For
// /// example, a visible keyboard will consume all gestures in the bottom part of
// /// the [viewPadding] anyway, so there is no need to account for
// /// that in the [padding], which is always safe to use for such
// /// calculations.
// class FlutterView {
//   FlutterView._(this.viewId, this.platformDispatcher, this._viewConfiguration);

//   /// The opaque ID for this view.
//   final int viewId;

//   /// The platform dispatcher that this view is registered with, and gets its
//   /// information from.
//   final PlatformDispatcher platformDispatcher;

//   /// The configuration of this view.
//   _ViewConfiguration _viewConfiguration;

//   /// The [Display] this view is drawn in.
//   Display get display {
//     assert(
//       platformDispatcher._displays.containsKey(_viewConfiguration.displayId),
//     );
//     return platformDispatcher._displays[_viewConfiguration.displayId]!;
//   }

//   /// The number of device pixels for each logical pixel for the screen this
//   /// view is displayed on.
//   ///
//   /// This number might not be a power of two. Indeed, it might not even be an
//   /// integer. For example, the Nexus 6 has a device pixel ratio of 3.5.
//   ///
//   /// Device pixels are also referred to as physical pixels. Logical pixels are
//   /// also referred to as device-independent or resolution-independent pixels.
//   ///
//   /// By definition, there are roughly 38 logical pixels per centimeter, or
//   /// about 96 logical pixels per inch, of the physical display. The value
//   /// returned by [devicePixelRatio] is ultimately obtained either from the
//   /// hardware itself, the device drivers, or a hard-coded value stored in the
//   /// operating system or firmware, and may be inaccurate, sometimes by a
//   /// significant margin.
//   ///
//   /// The Flutter framework operates in logical pixels, so it is rarely
//   /// necessary to directly deal with this property.
//   ///
//   /// When this changes, [PlatformDispatcher.onMetricsChanged] is called. When
//   /// using the Flutter framework, using [MediaQuery.of] to obtain the device
//   /// pixel ratio (via [MediaQueryData.devicePixelRatio]), instead of directly
//   /// obtaining the [devicePixelRatio] from a [FlutterView], will automatically
//   /// cause any widgets dependent on this value to rebuild when it changes,
//   /// without having to listen to [PlatformDispatcher.onMetricsChanged].
//   ///
//   /// See also:
//   ///
//   ///  * [WidgetsBindingObserver], for a mechanism at the widgets layer to
//   ///    observe when this value changes.
//   ///  * [Display.devicePixelRatio], which reports the DPR of the display.
//   ///    The value here is equal to the value exposed on [display].
//   double get devicePixelRatio => _viewConfiguration.devicePixelRatio;

//   /// The sizing constraints in physical pixels for this view.
//   ///
//   /// The view can take on any [Size] that fulfills these constraints. These
//   /// constraints are typically used by an UI framework as the input for its
//   /// layout algorithm to determine an appropriate size for the view. To size
//   /// the view, the selected size must be provided to the [render] method and it
//   /// must satisfy the constraints.
//   ///
//   /// When this changes, [PlatformDispatcher.onMetricsChanged] is called.
//   ///
//   /// At startup, the constraints for the view may not be known before Dart code
//   /// runs. If this value is observed early in the application lifecycle, it may
//   /// report constraints with all dimensions set to zero.
//   ///
//   /// This value does not take into account any on-screen keyboards or other
//   /// system UI. If the constraints are tight, the [padding] and [viewInsets]
//   /// properties provide information about how much of each side of the view may
//   /// be obscured by system UI. If the constraints are loose, this information
//   /// is not known upfront.
//   ///
//   /// See also:
//   ///
//   ///  * [physicalSize], which returns the current size of the view.
//   ViewConstraints get physicalConstraints => _viewConfiguration.viewConstraints;

//   /// The current dimensions of the rectangle as last reported by the platform
//   /// into which scenes rendered in this view are drawn.
//   ///
//   /// If the view is configured with loose [physicalConstraints] this value
//   /// may be outdated by a few frames as it only updates when the size chosen
//   /// for a frame (as provided to the [render] method) is processed by the
//   /// platform. Because of this, [physicalConstraints] should be used instead of
//   /// this value as the root input to the layout algorithm of UI frameworks.
//   ///
//   /// When this changes, [PlatformDispatcher.onMetricsChanged] is called. When
//   /// using the Flutter framework, using [MediaQuery.of] to obtain the size (via
//   /// [MediaQueryData.size]), instead of directly obtaining the [physicalSize]
//   /// from a [FlutterView], will automatically cause any widgets dependent on the
//   /// size to rebuild when the size changes, without having to listen to
//   /// [PlatformDispatcher.onMetricsChanged].
//   ///
//   /// At startup, the size of the view may not be known before Dart code runs.
//   /// If this value is observed early in the application lifecycle, it may
//   /// report [Size.zero].
//   ///
//   /// This value does not take into account any on-screen keyboards or other
//   /// system UI. The [padding] and [viewInsets] properties provide information
//   /// about how much of each side of the view may be obscured by system UI.
//   ///
//   /// See also:
//   ///
//   ///  * [WidgetsBindingObserver], for a mechanism at the widgets layer to
//   ///    observe when this value changes.
//   Size get physicalSize => _viewConfiguration.size;

//   /// The number of physical pixels on each side of the display rectangle into
//   /// which the view can render, but over which the operating system will likely
//   /// place system UI, such as the keyboard, that fully obscures any content.
//   ///
//   /// When this property changes, [PlatformDispatcher.onMetricsChanged] is
//   /// called. When using the Flutter framework, using [MediaQuery.of] to obtain
//   /// the insets (via [MediaQueryData.viewInsets]), instead of directly
//   /// obtaining the [viewInsets] from a [FlutterView], will automatically cause
//   /// any widgets dependent on the insets to rebuild when they change, without
//   /// having to listen to [PlatformDispatcher.onMetricsChanged].
//   ///
//   /// The relationship between this [viewInsets],
//   /// [viewPadding], and [padding] are described in
//   /// more detail in the documentation for [FlutterView].
//   ///
//   /// See also:
//   ///
//   ///  * [WidgetsBindingObserver], for a mechanism at the widgets layer to
//   ///    observe when this value changes.
//   ///  * [MediaQuery.of], a simpler mechanism for the same.
//   ///  * [Scaffold], which automatically applies the view insets in material
//   ///    design applications.
//   ViewPadding get viewInsets => _viewConfiguration.viewInsets;

//   /// The number of physical pixels on each side of the display rectangle into
//   /// which the view can render, but which may be partially obscured by system
//   /// UI (such as the system notification area), or physical intrusions in
//   /// the display (e.g. overscan regions on television screens or phone sensor
//   /// housings).
//   ///
//   /// Unlike [padding], this value does not change relative to
//   /// [viewInsets]. For example, on an iPhone X, it will not
//   /// change in response to the soft keyboard being visible or hidden, whereas
//   /// [padding] will.
//   ///
//   /// When this property changes, [PlatformDispatcher.onMetricsChanged] is
//   /// called. When using the Flutter framework, using [MediaQuery.of] to obtain
//   /// the padding (via [MediaQueryData.viewPadding]), instead of directly
//   /// obtaining the [viewPadding] from a [FlutterView], will automatically cause
//   /// any widgets dependent on the padding to rebuild when it changes, without
//   /// having to listen to [PlatformDispatcher.onMetricsChanged].
//   ///
//   /// The relationship between this [viewInsets],
//   /// [viewPadding], and [padding] are described in
//   /// more detail in the documentation for [FlutterView].
//   ///
//   /// See also:
//   ///
//   ///  * [WidgetsBindingObserver], for a mechanism at the widgets layer to
//   ///    observe when this value changes.
//   ///  * [MediaQuery.of], a simpler mechanism for the same.
//   ///  * [Scaffold], which automatically applies the padding in material design
//   ///    applications.
//   ViewPadding get viewPadding => _viewConfiguration.viewPadding;

//   /// The number of physical pixels on each side of the display rectangle into
//   /// which the view can render, but where the operating system will consume
//   /// input gestures for the sake of system navigation.
//   ///
//   /// For example, an operating system might use the vertical edges of the
//   /// screen, where swiping inwards from the edges takes users backward
//   /// through the history of screens they previously visited.
//   ///
//   /// When this property changes, [PlatformDispatcher.onMetricsChanged] is called.
//   ///
//   /// See also:
//   ///
//   ///  * [WidgetsBindingObserver], for a mechanism at the widgets layer to
//   ///    observe when this value changes.
//   ///  * [MediaQuery.of], a simpler mechanism for the same.
//   ViewPadding get systemGestureInsets => _viewConfiguration.systemGestureInsets;

//   /// The number of physical pixels on each side of the display rectangle into
//   /// which the view can render, but which may be partially obscured by system
//   /// UI (such as the system notification area), or physical intrusions in
//   /// the display (e.g. overscan regions on television screens or phone sensor
//   /// housings).
//   ///
//   /// This value is calculated by taking `max(0.0, FlutterView.viewPadding -
//   /// FlutterView.viewInsets)`. This will treat a system IME that increases the
//   /// bottom inset as consuming that much of the bottom padding. For example, on
//   /// an iPhone X, [EdgeInsets.bottom] of [FlutterView.padding] is the same as
//   /// [EdgeInsets.bottom] of [FlutterView.viewPadding] when the soft keyboard is
//   /// not drawn (to account for the bottom soft button area), but will be `0.0`
//   /// when the soft keyboard is visible.
//   ///
//   /// When this changes, [PlatformDispatcher.onMetricsChanged] is called. When
//   /// using the Flutter framework, using [MediaQuery.of] to obtain the padding
//   /// (via [MediaQueryData.padding]), instead of directly obtaining the
//   /// [padding] from a [FlutterView], will automatically cause any widgets
//   /// dependent on the padding to rebuild when it changes, without having to
//   /// listen to [PlatformDispatcher.onMetricsChanged].
//   ///
//   /// The relationship between this [viewInsets], [viewPadding], and [padding]
//   /// are described in more detail in the documentation for [FlutterView].
//   ///
//   /// See also:
//   ///
//   /// * [WidgetsBindingObserver], for a mechanism at the widgets layer to
//   ///   observe when this value changes.
//   /// * [MediaQuery.of], a simpler mechanism for the same.
//   /// * [Scaffold], which automatically applies the padding in material design
//   ///   applications.
//   ViewPadding get padding => _viewConfiguration.padding;

//   /// Additional configuration for touch gestures performed on this view.
//   ///
//   /// For example, the touch slop defined in physical pixels may be provided
//   /// by the gesture settings and should be preferred over the framework
//   /// touch slop constant.
//   GestureSettings get gestureSettings => _viewConfiguration.gestureSettings;

//   /// {@template dart.ui.ViewConfiguration.displayFeatures}
//   /// Areas of the display that are obstructed by hardware features.
//   ///
//   /// This list is populated only on Android. If the device has no display
//   /// features, this list is empty.
//   ///
//   /// The coordinate space in which the [DisplayFeature.bounds] are defined spans
//   /// across the screens currently in use. This means that the space between the screens
//   /// is virtually part of the Flutter view space, with the [DisplayFeature.bounds]
//   /// of the display feature as an obstructed area. The [DisplayFeature.type] can
//   /// be used to determine if this display feature obstructs the screen or not.
//   /// For example, [DisplayFeatureType.hinge] and [DisplayFeatureType.cutout] both
//   /// obstruct the display, while [DisplayFeatureType.fold] is a crease in the display.
//   ///
//   /// Folding [DisplayFeature]s like the [DisplayFeatureType.hinge] and
//   /// [DisplayFeatureType.fold] also have a [DisplayFeature.state] which can be
//   /// used to determine the posture the device is in.
//   /// {@endtemplate}
//   ///
//   /// When this changes, [PlatformDispatcher.onMetricsChanged] is called.
//   ///
//   /// See also:
//   ///
//   ///  * [WidgetsBindingObserver], for a mechanism at the widgets layer to
//   ///    observe when this value changes.
//   ///  * [MediaQuery.of], a simpler mechanism to access this data.
//   List<DisplayFeature> get displayFeatures =>
//       _viewConfiguration.displayFeatures;

//   /// The radii of the display corners in physical pixels.
//   ///
//   /// This is currently populated only on Android API 31+. On earlier Android
//   /// versions, iOS, and other platforms, this value is `null`.
//   DisplayCornerRadii? get displayCornerRadii =>
//       _viewConfiguration.displayCornerRadii;

//   /// Updates the view's rendering on the GPU with the newly provided [Scene].
//   ///
//   /// This function must be called within the scope of the
//   /// [PlatformDispatcher.onBeginFrame] or [PlatformDispatcher.onDrawFrame]
//   /// callbacks being invoked.
//   ///
//   /// If this function is called a second time during a single
//   /// [PlatformDispatcher.onBeginFrame]/[PlatformDispatcher.onDrawFrame]
//   /// callback sequence or called outside the scope of those callbacks, the call
//   /// will be ignored.
//   ///
//   /// To record graphical operations, first create a [PictureRecorder], then
//   /// construct a [Canvas], passing that [PictureRecorder] to its constructor.
//   /// After issuing all the graphical operations, call the
//   /// [PictureRecorder.endRecording] function on the [PictureRecorder] to obtain
//   /// the final [Picture] that represents the issued graphical operations.
//   ///
//   /// Next, create a [SceneBuilder], and add the [Picture] to it using
//   /// [SceneBuilder.addPicture]. With the [SceneBuilder.build] method you can
//   /// then obtain a [Scene] object, which you can display to the user via this
//   /// [render] function.
//   ///
//   /// If the view is configured with loose [physicalConstraints] (i.e.
//   /// [ViewConstraints.isTight] returns false) a `size` satisfying those
//   /// constraints must be provided. This method does not check that the provided
//   /// `size` actually meets the constraints (this should be done in a higher
//   /// level), but an illegal `size` may result in undefined rendering behavior.
//   /// If no `size` is provided, [physicalSize] is used instead.
//   ///
//   /// See also:
//   ///
//   /// * [SchedulerBinding], the Flutter framework class which manages the
//   ///   scheduling of frames.
//   /// * [RendererBinding], the Flutter framework class which manages layout and
//   ///   painting.
//   void render(Scene scene, {Size? size}) {
//     _render(
//       viewId,
//       scene as _NativeScene,
//       size?.width ?? physicalSize.width,
//       size?.height ?? physicalSize.height,
//     );
//   }

//   @Native<Void Function(Int64, Pointer<Void>, Double, Double)>(
//     symbol: 'PlatformConfigurationNativeApi::Render',
//   )
//   external static void _render(
//     int viewId,
//     _NativeScene scene,
//     double width,
//     double height,
//   );

//   /// Change the retained semantics data about this [FlutterView].
//   ///
//   /// [PlatformDispatcher.setSemanticsTreeEnabled] must be called with true
//   /// before sending update through this method.
//   ///
//   /// This function disposes the given update, which means the semantics update
//   /// cannot be used further.
//   void updateSemantics(SemanticsUpdate update) =>
//       _updateSemantics(viewId, update as _NativeSemanticsUpdate);

//   @Native<Void Function(Int64, Pointer<Void>)>(
//     symbol: 'PlatformConfigurationNativeApi::UpdateSemantics',
//   )
//   external static void _updateSemantics(
//     int viewId,
//     _NativeSemanticsUpdate update,
//   );

//   @override
//   String toString() => 'FlutterView(id: $viewId)';
// }

/// Additional accessibility features that may be enabled by the platform.
///
/// It is not possible to enable these settings from Flutter, instead they are
/// used by the platform to indicate that additional accessibility features are
/// enabled.
//
// When changes are made to this class, the equivalent APIs in each of the
// embedders *must* be updated.
class AccessibilityFeatures {
  const AccessibilityFeatures._(this._index);

  static const int _kAccessibleNavigationIndex = 1 << 0;
  static const int _kInvertColorsIndex = 1 << 1;
  static const int _kDisableAnimationsIndex = 1 << 2;
  static const int _kBoldTextIndex = 1 << 3;
  static const int _kReduceMotionIndex = 1 << 4;
  static const int _kHighContrastIndex = 1 << 5;
  static const int _kOnOffSwitchLabelsIndex = 1 << 6;
  static const int _kNoAnnounceIndex = 1 << 7;
  static const int _kNoAutoPlayAnimatedImagesIndex = 1 << 8;
  static const int _kNoAutoPlayVideosIndex = 1 << 9;
  static const int _kDeterministicCursorIndex = 1 << 10;

  // A bitfield which represents each enabled feature.
  final int _index;

  /// Whether there is a running accessibility service which is changing the
  /// interaction model of the device.
  ///
  /// For example, TalkBack on Android and VoiceOver on iOS enable this flag.
  bool get accessibleNavigation => _kAccessibleNavigationIndex & _index != 0;

  /// The platform is inverting the colors of the application.
  bool get invertColors => _kInvertColorsIndex & _index != 0;

  /// The platform is requesting that animations be disabled or simplified.
  bool get disableAnimations => _kDisableAnimationsIndex & _index != 0;

  /// The platform is requesting that text be rendered at a bold font weight.
  ///
  /// Only supported on iOS and Android API 31+.
  bool get boldText => _kBoldTextIndex & _index != 0;

  /// The platform is requesting that certain animations be simplified and
  /// parallax effects removed.
  ///
  /// Only supported on iOS.
  bool get reduceMotion => _kReduceMotionIndex & _index != 0;

  /// The platform is requesting that UI be rendered with darker colors.
  ///
  /// Only supported on iOS.
  bool get highContrast => _kHighContrastIndex & _index != 0;

  /// The platform is requesting to show on/off labels inside switches.
  ///
  /// Only supported on iOS.
  bool get onOffSwitchLabels => _kOnOffSwitchLabelsIndex & _index != 0;

  /// Whether the platform supports accessibility  announcement API,
  /// i.e. [SemanticsService.sendAnnouncement].
  ///
  /// Some platforms do not support or discourage the use of
  /// announcement. Using [SemanticsService.sendAnnouncement] on those platform
  /// may be ignored. Consider using other way to convey message to the
  /// user. For example, Android discourages the uses of direct message
  /// announcement, and rather encourages using other semantic
  /// properties such as [SemanticsProperties.liveRegion] to convey
  /// message to the user.
  ///
  /// Returns `false` on platforms where announcements are deprecated or
  /// unsupported by the underlying platform.
  ///
  /// Returns `true` on platforms where such announcements are
  /// generally supported without discouragement. (iOS, web etc)
  // This index check is inverted (== 0 vs != 0); far more platforms support
  // "announce" than discourage it.
  bool get supportsAnnounce => _kNoAnnounceIndex & _index == 0;

  /// Whether the platform allows auto-playing animated images.
  ///
  /// Only supported on iOS.
  ///
  /// Always returns `true` on other platforms.
  // This index check is inverted (== 0 vs != 0) since most of the platforms
  // don't have an option to disable animated images auto play.
  bool get autoPlayAnimatedImages =>
      _kNoAutoPlayAnimatedImagesIndex & _index == 0;

  /// Whether the platform allows auto-playing videos.
  ///
  /// Only supported on iOS.
  ///
  /// Always returns `true` on other platforms.
  // This index check is inverted (== 0 vs != 0) since most of the platforms
  // don't have an option to disable videos auto play.
  bool get autoPlayVideos => _kNoAutoPlayVideosIndex & _index == 0;

  /// The platform is requesting to show deterministic (non-blinking) cursor in
  /// editable text fields.
  ///
  /// Only supported on iOS.
  bool get deterministicCursor => _kDeterministicCursorIndex & _index != 0;

  @override
  String toString() {
    final features = <String>[];
    if (accessibleNavigation) {
      features.add('accessibleNavigation');
    }
    if (invertColors) {
      features.add('invertColors');
    }
    if (disableAnimations) {
      features.add('disableAnimations');
    }
    if (boldText) {
      features.add('boldText');
    }
    if (reduceMotion) {
      features.add('reduceMotion');
    }
    if (highContrast) {
      features.add('highContrast');
    }
    if (onOffSwitchLabels) {
      features.add('onOffSwitchLabels');
    }
    if (supportsAnnounce) {
      features.add('supportsAnnounce');
    }
    if (autoPlayAnimatedImages) {
      features.add('autoPlayAnimatedImages');
    }
    if (autoPlayVideos) {
      features.add('autoPlayVideos');
    }
    if (deterministicCursor) {
      features.add('deterministicCursor');
    }
    return 'AccessibilityFeatures$features';
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is AccessibilityFeatures && other._index == _index;
  }

  @override
  int get hashCode => _index.hashCode;
}

/// Describes the contrast of a theme or color palette.
enum Brightness {
  /// The color is dark and will require a light text color to achieve readable
  /// contrast.
  ///
  /// For example, the color might be dark grey, requiring white text.
  dark,

  /// The color is light and will require a dark text color to achieve readable
  /// contrast.
  ///
  /// For example, the color might be bright white, requiring black text.
  light,
}

/// Additional data available on each flutter frame.
///
/// See also:
///
///  * [Window.frameData] and [PlatformDispatcher.frameData], which expose the
///    frame data for the current frame.
///  * [PlatformDispatcher.onFrameDataChanged], which notifies listeners when
///    a window's frame data has changed.
class FrameData {
  const FrameData._({this.frameNumber = -1});

  /// The number of the current frame.
  ///
  /// This number monotonically increases, but doesn't necessarily
  /// start at a particular value.
  ///
  /// If not provided, defaults to -1.
  final int frameNumber;
}

/// Platform specific configuration for gesture behavior, such as touch slop.
///
/// These settings are provided via [FlutterView.gestureSettings] to each
/// view, and should be favored for configuring gesture behavior over the
/// framework constants.
///
/// A `null` field indicates that the platform or view does not have a preference
/// and the fallback constants should be used instead.
class GestureSettings {
  /// Create a new [GestureSettings] value.
  ///
  /// Consider using [GestureSettings.copyWith] on an existing settings object
  /// to ensure that newly added fields are correctly set.
  const GestureSettings({this.physicalTouchSlop, this.physicalDoubleTapSlop});

  /// The number of physical pixels a pointer is allowed to drift before it is
  /// considered an intentional movement.
  ///
  /// If `null`, the framework's default touch slop configuration should be used
  /// instead.
  final double? physicalTouchSlop;

  /// The number of physical pixels that the first and second tap of a double tap
  /// can drift apart to still be recognized as a double tap.
  ///
  /// If `null`, the framework's default double tap slop configuration should be used
  /// instead.
  final double? physicalDoubleTapSlop;

  /// Create a new [GestureSettings] object from an existing value, overwriting
  /// all of the provided fields.
  GestureSettings copyWith({
    double? physicalTouchSlop,
    double? physicalDoubleTapSlop,
  }) {
    return GestureSettings(
      physicalTouchSlop: physicalTouchSlop ?? this.physicalTouchSlop,
      physicalDoubleTapSlop:
          physicalDoubleTapSlop ?? this.physicalDoubleTapSlop,
    );
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is GestureSettings &&
        other.physicalTouchSlop == physicalTouchSlop &&
        other.physicalDoubleTapSlop == physicalDoubleTapSlop;
  }

  @override
  int get hashCode => Object.hash(physicalTouchSlop, physicalDoubleTapSlop);

  @override
  String toString() =>
      'GestureSettings(physicalTouchSlop: $physicalTouchSlop, physicalDoubleTapSlop: $physicalDoubleTapSlop)';
}
