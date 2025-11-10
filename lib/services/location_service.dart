import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';

/// Location Service
///
/// Handles location permissions and getting current position for SOS feature.
class LocationService {
  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Check location permission status
  Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  /// Request location permission
  Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  /// Get current location with permission handling
  ///
  /// Returns Position if successful, throws exception if failed.
  /// Handles all permission scenarios automatically.
  Future<Position> getCurrentLocation() async {
    try {
      // 1. Check if location services are enabled
      bool serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception(
          'Layanan lokasi tidak aktif. '
          'Silakan aktifkan GPS di pengaturan perangkat.',
        );
      }

      // 2. Check permission
      LocationPermission permission = await checkPermission();

      // 3. Handle denied permission
      if (permission == LocationPermission.denied) {
        permission = await requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception(
            'Izin akses lokasi ditolak. '
            'Aplikasi memerlukan akses lokasi untuk mengirim SOS.',
          );
        }
      }

      // 4. Handle permanently denied
      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          'Izin akses lokasi ditolak permanen. '
          'Silakan aktifkan di pengaturan aplikasi.',
        );
      }

      // 5. Get current position
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      if (kDebugMode) {
        print('📍 Location obtained: ${position.latitude}, ${position.longitude}');
      }

      return position;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting location: $e');
      }
      rethrow;
    }
  }

  /// Generate Google Maps URL from coordinates
  ///
  /// Returns a URL that opens Google Maps at the specified location.
  /// Format: https://www.google.com/maps?q=lat,lng
  String getGoogleMapsUrl(double latitude, double longitude) {
    return 'https://www.google.com/maps?q=$latitude,$longitude';
  }

  /// Get current location and Google Maps URL
  ///
  /// Convenience method that gets location and generates URL in one call.
  /// Returns Map with 'position' and 'url' keys.
  Future<Map<String, dynamic>> getCurrentLocationWithUrl() async {
    try {
      final position = await getCurrentLocation();
      final url = getGoogleMapsUrl(position.latitude, position.longitude);

      return {
        'position': position,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'url': url,
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting location with URL: $e');
      }
      rethrow;
    }
  }

  /// Format location as readable string
  String formatLocation(Position position) {
    return '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
  }

  /// Calculate distance between two positions in meters
  double getDistanceBetween(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }
}
