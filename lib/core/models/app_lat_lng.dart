// lib/core/models/app_lat_lng.dart

class AppLatLng {
  final double lat;
  final double lng;
  const AppLatLng(this.lat, this.lng);

  bool get isFallback =>
      lat == -4.0435 && lng == 39.6682; // from discover_providers
}
