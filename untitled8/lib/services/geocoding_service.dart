import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class GeocodingService {
  // Primary method using geocoding package
  static Future<LocationResult?> searchLocation(String query) async {
    if (query.trim().isEmpty) return null;
    
    try {
      print('Searching for: $query');
      
      // Try using geocoding package first
      final locations = await locationFromAddress(query);
      
      if (locations.isNotEmpty) {
        final place = locations.first;
        print('Found via geocoding package: ${place.latitude}, ${place.longitude}');
        
        // Get formatted address
        String formattedAddress = query;
        try {
          final placemarks = await placemarkFromCoordinates(
            place.latitude, 
            place.longitude,
          );
          
          if (placemarks.isNotEmpty) {
            final p = placemarks.first;
            formattedAddress = [
              p.name,
              p.locality,
              p.administrativeArea,
              p.country,
            ].where((s) => s != null && s.isNotEmpty).join(', ');
          }
        } catch (e) {
          print('Reverse geocoding error: $e');
        }
        
        return LocationResult(
          latitude: place.latitude,
          longitude: place.longitude,
          formattedAddress: formattedAddress,
          displayName: query,
        );
      }
    } catch (e) {
      print('Geocoding package error: $e. Trying fallback...');
      // Fallback to OpenStreetMap Nominatim API
      return await _fallbackGeocode(query);
    }
    
    return null;
  }
  
  // Fallback: OpenStreetMap Nominatim API (free, no API key needed)
  static Future<LocationResult?> _fallbackGeocode(String query) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?'
        'q=${Uri.encodeComponent(query)}'
        '&format=json'
        '&limit=1'
      );
      
      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'SafetyGuardianApp/1.0', // Required by Nominatim
        },
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          final place = data.first;
          print('Found via Nominatim fallback: ${place['lat']}, ${place['lon']}');
          return LocationResult(
            latitude: double.parse(place['lat']),
            longitude: double.parse(place['lon']),
            formattedAddress: place['display_name'],
            displayName: place['display_name'].split(',').first,
          );
        }
      }
    } catch (e) {
      print('Nominatim fallback error: $e');
    }
    return null;
  }
}

class LocationResult {
  final double latitude;
  final double longitude;
  final String formattedAddress;
  final String displayName;
  
  LocationResult({
    required this.latitude,
    required this.longitude,
    required this.formattedAddress,
    required this.displayName,
  });
}
