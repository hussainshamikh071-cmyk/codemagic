import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../services/openrouter_service.dart';
import '../services/geocoding_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  LatLng? _currentP;
  String _currentAddress = "Detecting...";
  final MapController _mapController = MapController();
  final OpenRouterService _openRouterService = OpenRouterService();

  SafetyAssessment? _currentSafetyAssessment;
  bool _isAnalyzing = false;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  Future<void> _getLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    final initialPos = await Geolocator.getCurrentPosition();
    if (mounted) {
      setState(() {
        _currentP = LatLng(initialPos.latitude, initialPos.longitude);
      });
      _updateCurrentAddress(initialPos.latitude, initialPos.longitude);
    }

    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) async {
      if (mounted) {
        setState(() {
          _currentP = LatLng(position.latitude, position.longitude);
        });
      }
    });
  }

  Future<void> _updateCurrentAddress(double lat, double lng) async {
    try {
      final address = await GeocodingService.searchLocation("$lat, $lng");
      if (address != null && mounted) {
        setState(() {
          _currentAddress = address.formattedAddress;
        });
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> _searchAndAnalyzeLocation(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isSearching = true;
      _isAnalyzing = true;
    });

    try {
      final location = await GeocodingService.searchLocation(query);

      if (location != null && mounted) {
        _mapController.move(LatLng(location.latitude, location.longitude), 15);
        
        final assessment = await _openRouterService.analyzeLocation(
          locationName: location.displayName,
          lat: location.latitude,
          lng: location.longitude,
        );
        
        setState(() {
          _currentSafetyAssessment = assessment;
        });
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location not found. Try a different search term.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search failed: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
          _isAnalyzing = false;
        });
      }
    }
  }

  Future<void> _analyzeSafety(String locationName, double lat, double lng) async {
    setState(() => _isAnalyzing = true);
    try {
      final assessment = await _openRouterService.analyzeLocation(
        locationName: locationName,
        lat: lat,
        lng: lng,
      );
      setState(() => _currentSafetyAssessment = assessment);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Analysis failed: $e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      setState(() => _isAnalyzing = false);
    }
  }

  void _onSOSPressed(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('SOS Triggered', style: TextStyle(color: Colors.white)),
        content: const Text('Emergency alert has been sent!', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: Stack(
        children: [
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.redAccent.withOpacity(0.1)),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  _buildHeader(),
                  const SizedBox(height: 20),
                  _buildSearchBar(),
                  const SizedBox(height: 20),
                  if (_isAnalyzing || _isSearching) _buildLoadingShimmer(),
                  if (_currentSafetyAssessment != null && !_isAnalyzing && !_isSearching) 
                    _buildSafetyCard(_currentSafetyAssessment!),
                  if (_currentSafetyAssessment == null && !_isAnalyzing && !_isSearching) 
                    _buildDefaultSafetyScore(),
                  const SizedBox(height: 20),
                  _buildMapComponent(),
                  const SizedBox(height: 20),
                  _buildSOSSection(context),
                  const SizedBox(height: 20),
                  _buildLocationCard(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Hello, User', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            Text('You are currently safe', style: TextStyle(color: Colors.white70)),
          ],
        ),
        const CircleAvatar(backgroundColor: Colors.white24, child: Icon(Icons.person, color: Colors.white))
      ],
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search any location...',
              hintStyle: const TextStyle(color: Colors.white38),
              prefixIcon: const Icon(Icons.search, color: Colors.redAccent),
              suffixIcon: _isSearching 
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.redAccent)),
                  )
                : _searchController.text.isNotEmpty 
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white38),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _currentSafetyAssessment = null;
                        });
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
            ),
            onSubmitted: (value) => _searchAndAnalyzeLocation(value),
          ),
        ),
        const SizedBox(width: 10),
        IconButton(
          icon: const Icon(Icons.my_location, color: Colors.redAccent),
          onPressed: () {
            if (_currentP != null) {
              _mapController.move(_currentP!, 15);
              _analyzeSafety(_currentAddress, _currentP!.latitude, _currentP!.longitude);
            }
          },
        )
      ],
    );
  }

  Widget _buildDefaultSafetyScore() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(20)),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Overall Safety Score', style: TextStyle(color: Colors.white70)),
          Text('85%', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 18))
        ],
      ),
    );
  }

  Widget _buildSafetyCard(SafetyAssessment assessment) {
    return Card(
      color: Colors.white.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                _buildCircularScore(assessment.safetyScore, assessment.riskColor),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("${assessment.riskLevel.toUpperCase()} RISK",
                          style: TextStyle(color: assessment.riskColor, fontWeight: FontWeight.bold, fontSize: 18)),
                      Text(assessment.locationName, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.white10, height: 25),
            _buildTipsRow(assessment),
          ],
        ),
      ),
    );
  }

  Widget _buildCircularScore(int score, Color color) {
    return SizedBox(
      height: 60, width: 60,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(value: score / 100, strokeWidth: 6, backgroundColor: Colors.white10, valueColor: AlwaysStoppedAnimation<Color>(color)),
          Text('$score', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
    );
  }

  Widget _buildTipsRow(SafetyAssessment assessment) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("AI Recommendations:", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 8),
        Text("☀️ Day: ${assessment.daytimeSafety}", style: const TextStyle(color: Colors.white70, fontSize: 11)),
        const SizedBox(height: 4),
        Text("🌙 Night: ${assessment.nighttimeSafety}", style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }

  Widget _buildLoadingShimmer() {
    return Container(
      height: 120, width: double.infinity,
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(20)),
      child: const Center(child: CircularProgressIndicator(color: Colors.redAccent)),
    );
  }

  Widget _buildMapComponent() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 200, width: double.infinity,
        child: _currentP == null
            ? Container(color: Colors.white.withOpacity(0.05), child: const Center(child: Text("Loading Map...", style: TextStyle(color: Colors.white38))))
            : FlutterMap(
                mapController: _mapController,
                options: MapOptions(initialCenter: _currentP!, initialZoom: 15.0),
                children: [
                  TileLayer(urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', subdomains: const ['a', 'b', 'c']),
                  MarkerLayer(markers: [
                    Marker(point: _currentP!, width: 40, height: 40, child: const Icon(Icons.location_on, color: Colors.redAccent, size: 40)),
                  ]),
                ],
              ),
      ),
    );
  }

  Widget _buildSOSSection(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const Text('Tap for Help', style: TextStyle(color: Colors.white, fontSize: 18)),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => _onSOSPressed(context),
            child: Container(
              width: 140, height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle, color: Colors.redAccent,
                boxShadow: [BoxShadow(color: Colors.redAccent.withOpacity(0.6), blurRadius: 30, spreadRadius: 10)],
              ),
              child: const Center(child: Text('SOS', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(20)),
          child: Row(
            children: [
              const Icon(Icons.location_on, color: Colors.redAccent),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Current Location', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    Text(_currentAddress, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
