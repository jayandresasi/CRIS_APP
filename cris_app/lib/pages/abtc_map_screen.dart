import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';

import '../services/location_service.dart';
import '../theme.dart';
import '../widgets/cris_map.dart';

class ABTCMapScreen extends StatefulWidget {
  const ABTCMapScreen({super.key});

  @override
  State<ABTCMapScreen> createState() => _ABTCMapScreenState();
}

class _ABTCMapScreenState extends State<ABTCMapScreen> {
  final _locationService = LocationService();

  StreamSubscription<Position>? _locationSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _facilitiesSubscription;
  Position? _userPosition;
  List<_FacilityLocation> _facilities = const [];
  String? _locationMessage;

  @override
  void initState() {
    super.initState();
    _listenToFacilities();
    _findUserLocation();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _facilitiesSubscription?.cancel();
    super.dispose();
  }

  void _listenToFacilities() {
    _facilitiesSubscription = FirebaseFirestore.instance
        .collection('facilities')
        .snapshots()
        .listen(
      (snapshot) {
        final facilities = snapshot.docs
            .map(_FacilityLocation.fromFirestore)
            .whereType<_FacilityLocation>()
            .toList();
        if (mounted) setState(() => _facilities = facilities);
      },
      onError: (_) {
        if (mounted) {
          setState(() {
            _locationMessage = 'Could not load facility locations.';
          });
        }
      },
    );
  }

  Future<void> _findUserLocation() async {
    try {
      final position = await _locationService.getCurrentLocation();
      _updateUserPosition(position);
      _locationSubscription = _locationService.watchLocation().listen(
        _updateUserPosition,
        onError: (_) {
          if (mounted) {
            setState(() {
              _locationMessage = 'Your location could not be updated.';
            });
          }
        },
      );
    } on LocationServiceException catch (error) {
      if (mounted) setState(() => _locationMessage = error.message);
    } catch (_) {
      if (mounted) {
        setState(() {
          _locationMessage =
              'Your location is unavailable. Allow location access to show it on the map.';
        });
      }
    }
  }

  void _updateUserPosition(Position position) {
    if (!mounted) return;
    setState(() {
      _userPosition = position;
      _locationMessage = null;
    });
  }

  List<CRISMapMarker> _buildMarkers() {
    final markers = <CRISMapMarker>[];
    final position = _userPosition;

    if (position != null) {
      markers.add(
        CRISMapMarker(
          label: 'Your location',
          position: LatLng(position.latitude, position.longitude),
          color: Colors.blue,
          child: const Icon(
            Icons.person_pin_circle,
            color: Colors.blue,
            size: 42,
          ),
        ),
      );
    }

    for (final facility in _facilities) {
      markers.add(
        CRISMapMarker(
          label: facility.name,
          position: LatLng(facility.latitude, facility.longitude),
          color: AppColors.primary,
          child: const Icon(
            Icons.local_hospital,
            color: AppColors.primary,
            size: 34,
          ),
        ),
      );
    }
    return markers;
  }

  @override
  Widget build(BuildContext context) {
    final position = _userPosition;
    final mapCenter = position == null
        ? const LatLng(12.8797, 121.7740)
        : LatLng(position.latitude, position.longitude);

    return Scaffold(
      appBar: AppBar(title: const Text('Locate Animal Bite Centers')),
      body: Stack(
        children: [
          Positioned.fill(
            child: CRISMap(
              center: mapCenter,
              zoom: position == null ? 6 : 15,
              height: MediaQuery.sizeOf(context).height,
              markers: _buildMarkers(),
            ),
          ),
          if (_locationMessage != null)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: _LocationNotice(message: _locationMessage!),
            ),
        ],
      ),
    );
  }
}

class _FacilityLocation {
  const _FacilityLocation({
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  final String name;
  final double latitude;
  final double longitude;

  static _FacilityLocation? fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    final location = data?['location'] as Map<String, dynamic>?;
    final latitude = location?['latitude'];
    final longitude = location?['longitude'];

    if (latitude is! num || longitude is! num) return null;

    return _FacilityLocation(
      name: (data?['facilityName'] ?? data?['facilityType'] ?? 'ABTC Facility')
          .toString(),
      latitude: latitude.toDouble(),
      longitude: longitude.toDouble(),
    );
  }
}

class _LocationNotice extends StatelessWidget {
  const _LocationNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        elevation: 3,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              const Icon(Icons.location_off_outlined, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child:
                    Text(message, style: Theme.of(context).textTheme.bodySmall),
              ),
            ],
          ),
        ),
      );
}
