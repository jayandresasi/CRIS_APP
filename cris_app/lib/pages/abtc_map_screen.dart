import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

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
  Position? _userPosition;
  String? _locationMessage;

  @override
  void initState() {
    super.initState();
    _findUserLocation();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
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
              markers: position == null
                  ? const []
                  : [
                      CRISMapMarker(
                        label: 'Your location',
                        position: mapCenter,
                        color: Colors.blue,
                        child: const Icon(
                          Icons.person_pin_circle,
                          color: Colors.blue,
                          size: 42,
                        ),
                      ),
                    ],
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
