// lib/core/maps/impl/mobile_map.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// CHANGELOG
// ─────────────────────────────────────────────────────────────────────────────
//   v1.0.0 — Initial. Mapbox implementation of AppMapWidget.
//            Uses MapWidget (correct Flutter widget) not MapboxMap (which was
//            the native SDK type — wrong layer). Token is NOT passed here;
//            it must be set via MapboxOptions.setAccessToken() in main.dart.
//            Pins via CircleAnnotationManager — no bitmap assets required.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../app_map_types.dart';
import '../../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONFIG
// ─────────────────────────────────────────────────────────────────────────────

// ── Pin appearance ──
// Colors as int — CircleAnnotationOptions.circleColor takes int ARGB.
// These mirror AppColors.primary and AppColors.secondary without importing
// app_theme at constant-evaluation time (getters can't be const).
const int    _kPinColorDefault  = 0xFF00CC66;   // green — matches AppColors.primary
const int    _kPinColorSelected = 0xFF0099CC;   // blue  — matches AppColors.secondary
const int    _kPinStrokeColor   = 0xFFFFFFFF;   // white ring
const double _kPinRadius        = 9.0;
const double _kPinRadiusSelected = 11.0;
const double _kPinStrokeWidth   = 2.5;

// ── Animation ──
const int _kFlyDurationMs = 600;

// ─────────────────────────────────────────────────────────────────────────────
// _MapboxController — AppMapController implementation for Mapbox
// ─────────────────────────────────────────────────────────────────────────────

class _MapboxController implements AppMapController {
  final MapboxMap _map;
  final double    _defaultZoom;
  CircleAnnotationManager? _circleManager;

  _MapboxController(this._map, {required double defaultZoom})
      : _defaultZoom = defaultZoom;

  // Lazily created on first pin operation — avoids async in constructor.
  Future<CircleAnnotationManager> _manager() async {
    return _circleManager ??=
        await _map.annotations.createCircleAnnotationManager();
  }

  @override
  Future<void> animateTo(double lat, double lng, {double? zoom}) async {
    await _map.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(lng, lat)),
        zoom:   zoom ?? _defaultZoom,
      ),
      MapAnimationOptions(duration: _kFlyDurationMs),
    );
  }

  @override
  Future<void> setPins(List<AppMapPin> pins) async {
    final mgr = await _manager();
    await mgr.deleteAll();
    if (pins.isEmpty) return;

    final options = pins.map((p) => CircleAnnotationOptions(
      geometry:          Point(coordinates: Position(p.lng, p.lat)),
      circleRadius:      p.selected ? _kPinRadiusSelected : _kPinRadius,
      circleColor:       p.selected ? _kPinColorSelected  : _kPinColorDefault,
      circleStrokeWidth: _kPinStrokeWidth,
      circleStrokeColor: _kPinStrokeColor,
    )).toList();

    await mgr.createMulti(options);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AppMapWidget — Mapbox implementation
//
// Uses MapWidget (the Flutter widget layer) with MapboxMap as the controller
// object returned in onMapCreated. The distinction matters:
//   MapWidget       → what you put in the widget tree (extends Widget)
//   MapboxMap       → the controller you get back in onMapCreated (not a widget)
//
// Token: set once in main.dart via MapboxOptions.setAccessToken().
//        Never pass it again here.
// ─────────────────────────────────────────────────────────────────────────────

class AppMapWidget extends StatefulWidget {
  final double initialLat;
  final double initialLng;
  final double initialZoom;
  final String styleUri;
  final List<AppMapPin>              initialPins;
  final void Function(AppMapController)? onMapReady;

  const AppMapWidget({
    super.key,
    required this.initialLat,
    required this.initialLng,
    required this.initialZoom,
    required this.styleUri,
    this.initialPins = const [],
    this.onMapReady,
  });

  @override
  State<AppMapWidget> createState() => _AppMapWidgetState();
}

class _AppMapWidgetState extends State<AppMapWidget> {
  _MapboxController? _ctrl;

  Future<void> _onMapCreated(MapboxMap mapboxMap) async {
    // mapboxMap is the controller object — NOT a widget.
    // MapWidget (above in the tree) is the widget.
    final ctrl = _MapboxController(
      mapboxMap,
      defaultZoom: widget.initialZoom,
    );
    _ctrl = ctrl;

    if (widget.initialPins.isNotEmpty) {
      await ctrl.setPins(widget.initialPins);
    }

    widget.onMapReady?.call(ctrl);
  }

  @override
  Widget build(BuildContext context) {
    // MapWidget is the correct Flutter widget from mapbox_maps_flutter.
    // styleUri, cameraOptions, and onMapCreated are direct parameters —
    // no MapInitOptions or ResourceOptions needed.
    return MapWidget(
      key: ValueKey('mapbox-${widget.initialLat}-${widget.initialLng}'),
      styleUri: widget.styleUri,
      cameraOptions: CameraOptions(
        center: Point(
            coordinates: Position(widget.initialLng, widget.initialLat)),
        zoom: widget.initialZoom,
      ),
      onMapCreated: _onMapCreated,
    );
  }
}