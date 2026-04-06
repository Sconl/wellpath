// lib/core/maps/impl/web_map.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// CHANGELOG
// ─────────────────────────────────────────────────────────────────────────────
//   v1.0.0 — Initial. flutter_map + OSM implementation of AppMapWidget.
//   v1.1.0 — Removed dependency on flutter_map_cancellable_tile_provider (discontinued).
//            flutter_map 6.0+ handles tile request cancellation automatically.
//
//   DEPENDENCIES — add to pubspec.yaml:
//     flutter_map: ^6.0.0
//     latlong2: ^0.9.0
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../app_map_types.dart';
import '../../style/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONFIG
// ─────────────────────────────────────────────────────────────────────────────

// ── Tile source ──
// Standard OSM tiles — free, no account required.
// For a dark theme on web that matches the Mapbox dark style on mobile,
// swap to Stadia.Maps Alidade Smooth Dark (free tier, requires a Stadia account):
//   https://tiles.stadiamaps.com/tiles/alidade_smooth_dark/{z}/{x}/{y}{r}.png
// Just update _kOsmTileUrl here when a Stadia key is available.
const String _kOsmTileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
const String _kUserAgentPackage = 'com.wellpath.app';

// ── Pin appearance ──
// flutter_map's CircleMarker. Colors read at build time from AppColors.
const double _kPinRadius = 9.0;
const double _kPinRadiusSelected = 11.0;
const double _kPinStrokeWidth = 2.0;
const double _kPinOpacity = 0.85;

// ─────────────────────────────────────────────────────────────────────────────
// _OsmController — AppMapController implementation for flutter_map
// ─────────────────────────────────────────────────────────────────────────────

class _OsmController implements AppMapController {
  final MapController _ctrl;
  final double _defaultZoom;
  final void Function(List<AppMapPin>) _onPinsChanged;

  _OsmController({
    required MapController ctrl,
    required double defaultZoom,
    required void Function(List<AppMapPin>) onPinsChanged,
  })  : _ctrl = ctrl,
        _defaultZoom = defaultZoom,
        _onPinsChanged = onPinsChanged;

  @override
  Future<void> animateTo(double lat, double lng, {double? zoom}) async {
    // MapController.move is synchronous — wrapped in Future for interface compat.
    _ctrl.move(LatLng(lat, lng), zoom ?? _defaultZoom);
  }

  @override
  Future<void> setPins(List<AppMapPin> pins) async {
    // Drives setState in the owning widget via the injected callback — correct
    // way to trigger reactive updates from outside a StatefulWidget.
    _onPinsChanged(pins);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AppMapWidget — flutter_map + OSM implementation
//
// Satisfies the same interface as mobile_map.dart so the conditional export
// in app_map_widget.dart works transparently. Feature layer code that imports
// app_map_widget.dart gets this implementation on web with no branching.
// ─────────────────────────────────────────────────────────────────────────────

class AppMapWidget extends StatefulWidget {
  final double initialLat;
  final double initialLng;
  final double initialZoom;
  final String styleUri; // ignored on web — OSM tiles always used
  final List<AppMapPin> initialPins;
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
    _pins = List.of(widget.initialPins);

    // Notify caller after first frame — MapController isn't fully ready
    // until FlutterMap has laid out at least once.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctrl = _OsmController(
        ctrl: _mapCtrl,
        defaultZoom: widget.initialZoom,
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
        initialZoom: widget.initialZoom,
      ),
      children: [
        // ── Tile layer ───────────────────────────────────────────────────
        // CancellableNetworkTileProvider cancels in-flight HTTP tile requests
        // when the user scrolls or zooms quickly. Without this, stale requests
        // The default tile provider in flutter_map handles HTTP tile requests
        // and cancellation automatically.
        TileLayer(
          urlTemplate: _kOsmTileUrl,
          userAgentPackageName: _kUserAgentPackage,
        ),

        // ── Pin layer ────────────────────────────────────────────────────
        // CircleMarker visually matches Mapbox's CircleAnnotationManager
        // on mobile. No bitmap assets required on either platform.
        CircleLayer(
          circles: _pins
              .map((p) => CircleMarker(
                    point: LatLng(p.lat, p.lng),
                    radius: p.selected ? _kPinRadiusSelected : _kPinRadius,
                    color:
                        (p.selected ? AppColors.secondary : AppColors.primary)
                            .withValues(alpha: _kPinOpacity),
                    borderStrokeWidth: _kPinStrokeWidth,
                    borderColor: Colors.white,
                    useRadiusInMeter: false,
                  ))
              .toList(),
        ),
      ],
    );
  }
}
