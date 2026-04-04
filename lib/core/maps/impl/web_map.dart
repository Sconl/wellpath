// lib/core/maps/impl/web_map.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// CHANGELOG
// ─────────────────────────────────────────────────────────────────────────────
//   v1.0.0 — Initial. flutter_map + OpenStreetMap implementation of
//            AppMapWidget. Zero native SDK dependencies — pure Flutter
//            widget layer. Renders identically to the Mapbox version
//            from the feature layer's perspective:
//              - Same AppMapController interface
//              - Same AppMapPin data
//              - Same animateTo / setPins API
//            styleUri is ignored on web — OSM tiles are always used.
//
//   DEPENDENCIES — add to pubspec.yaml:
//     flutter_map: ^6.0.0
//     latlong2: ^0.9.0
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../app_map_types.dart';
import '../../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONFIG
// ─────────────────────────────────────────────────────────────────────────────

// ── Tile source ──
// OpenStreetMap standard tiles — free, no API key, works everywhere.
// For a dark map on web, use a dark tile provider such as Stadia.Maps:
//   https://tiles.stadiamaps.com/tiles/alidade_smooth_dark/{z}/{x}/{y}.png
// (requires a free Stadia account — worth it if you want theme consistency).
const String _kOsmTileUrl       = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
const String _kUserAgentPackage = 'com.wellpath.app';

// ── Pin appearance ──
// OSM layer uses flutter_map's CircleMarker. Colors read from AppColors
// at build time (not const-evaluated) so we use getter calls here.
const double _kPinRadius         = 9.0;
const double _kPinRadiusSelected = 11.0;
const double _kPinStrokeWidth    = 2.0;
const double _kPinOpacity        = 0.85;

// ── Animation ──
// flutter_map's MapController.move() is instantaneous — no built-in
// fly animation. Wrapping in TickerFuture would add complexity with
// little return; instant move is fine for web.

// ─────────────────────────────────────────────────────────────────────────────
// _OsmController — AppMapController implementation for flutter_map
// ─────────────────────────────────────────────────────────────────────────────

class _OsmController implements AppMapController {
  final MapController                    _ctrl;
  final double                           _defaultZoom;
  final void Function(List<AppMapPin>)   _onPinsChanged;

  _OsmController({
    required MapController ctrl,
    required double        defaultZoom,
    required void Function(List<AppMapPin>) onPinsChanged,
  })  : _ctrl          = ctrl,
        _defaultZoom   = defaultZoom,
        _onPinsChanged = onPinsChanged;

  @override
  Future<void> animateTo(double lat, double lng, {double? zoom}) async {
    // MapController.move is synchronous — wrap in Future for interface compat.
    _ctrl.move(LatLng(lat, lng), zoom ?? _defaultZoom);
  }

  @override
  Future<void> setPins(List<AppMapPin> pins) async {
    // Triggers setState in the owning widget via the callback — this is the
    // correct way to drive reactive UI from outside a StatefulWidget without
    // exposing the state directly.
    _onPinsChanged(pins);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AppMapWidget — flutter_map/OSM implementation
//
// Satisfies the same interface as mobile_map.dart's AppMapWidget so the
// conditional export in app_map_widget.dart works transparently.
// ─────────────────────────────────────────────────────────────────────────────

class AppMapWidget extends StatefulWidget {
  final double initialLat;
  final double initialLng;
  final double initialZoom;
  final String styleUri;   // ignored on web — OSM tiles used unconditionally
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
  late final MapController _mapCtrl;
  List<AppMapPin> _pins = [];

  @override
  void initState() {
    super.initState();
    _mapCtrl = MapController();
    _pins    = List.of(widget.initialPins);

    // Notify caller after the first frame — MapController isn't fully ready
    // until FlutterMap has laid out at least once.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctrl = _OsmController(
        ctrl:          _mapCtrl,
        defaultZoom:   widget.initialZoom,
        onPinsChanged: (pins) {
          if (mounted) setState(() => _pins = pins);
        },
      );
      widget.onMapReady?.call(ctrl);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: _mapCtrl,
      options: MapOptions(
        initialCenter: LatLng(widget.initialLat, widget.initialLng),
        initialZoom:   widget.initialZoom,
      ),
      children: [
        // ── Tile layer ───────────────────────────────────────────────────
        TileLayer(
          urlTemplate:          _kOsmTileUrl,
          userAgentPackageName: _kUserAgentPackage,
        ),

        // ── Pin layer ────────────────────────────────────────────────────
        // CircleLayer renders pins as filled circles — matches Mapbox's
        // CircleAnnotationManager visually. No bitmap assets required.
        CircleLayer(
          circles: _pins.map((p) => CircleMarker(
            point:             LatLng(p.lat, p.lng),
            radius:            p.selected ? _kPinRadiusSelected : _kPinRadius,
            color:             (p.selected
                    ? AppColors.secondary
                    : AppColors.primary)
                .withValues(alpha: _kPinOpacity),
            borderStrokeWidth: _kPinStrokeWidth,
            borderColor:       Colors.white,
            useRadiusInMeter:  false,
          )).toList(),
        ),
      ],
    );
  }
}