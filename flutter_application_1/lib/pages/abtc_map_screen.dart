import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/abtc_model.dart';
import '../repositories/firestore_abtc_repository.dart';
import '../services/location_service.dart';
import '../services/nearest_abtc_service.dart';
import '../theme.dart';
import '../widgets/abtc_list_widget.dart';
import '../widgets/abtc_marker_widget.dart';
import '../widgets/cris_map.dart';
import 'abtc_details_screen.dart';

class ABTCMapScreen extends StatefulWidget {
  const ABTCMapScreen({super.key});

  @override
  State<ABTCMapScreen> createState() => _ABTCMapScreenState();
}

class _ABTCMapScreenState extends State<ABTCMapScreen> {
  final _repository = FirestoreABTCRepository();
  final _locationService = LocationService();
  final _nearestService = NearestABTCService();
  final _searchController = TextEditingController();

  StreamSubscription<Position>? _locationSubscription;
  List<ABTCModel> _abtcs = const [];
  List<ABTCWithDistance> _rankedABTCs = const [];
  Position? _userPosition;
  String _query = '';
  String? _loadError;
  String? _locationMessage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadABTCs();
    _findUserLocation();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadABTCs() async {
    try {
      // This is deliberately the only Firestore read for this screen visit.
      final abtcs = await _repository.fetchABTCs();
      if (!mounted) return;
      setState(() {
        _abtcs = abtcs;
        _isLoading = false;
        _recalculateDistances();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = 'Unable to load Animal Bite Treatment Centers. Check your internet connection and try again.';
      });
    }
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
          _locationMessage = 'Your location is unavailable. Allow location access to find the nearest center.';
        });
      }
    }
  }

  void _updateUserPosition(Position position) {
    if (!mounted) return;
    setState(() {
      _userPosition = position;
      _locationMessage = null;
      _recalculateDistances();
    });
  }

  void _recalculateDistances() {
    _rankedABTCs = _nearestService.sortByDistance(
      abtcs: _abtcs,
      userLatitude: _userPosition?.latitude,
      userLongitude: _userPosition?.longitude,
    );
  }

  List<ABTCWithDistance> get _filteredABTCs {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return _rankedABTCs;
    return _rankedABTCs.where((center) {
      final abtc = center.abtc;
      return abtc.name.toLowerCase().contains(query) ||
          abtc.municipality.toLowerCase().contains(query) ||
          abtc.barangay.toLowerCase().contains(query);
    }).toList(growable: false);
  }

  String? get _nearestABTCId {
    for (final center in _rankedABTCs) {
      if (center.distanceInMeters != null) return center.abtc.id;
    }
    return null;
  }

  LatLng? get _mapCenter {
    final position = _userPosition;
    if (position != null) return LatLng(position.latitude, position.longitude);
    for (final abtc in _abtcs) {
      if (abtc.hasCoordinates) return LatLng(abtc.latitude!, abtc.longitude!);
    }
    return null;
  }

  List<CRISMapMarker> get _markers {
    final markers = <CRISMapMarker>[];
    final position = _userPosition;
    if (position != null) {
      markers.add(
        CRISMapMarker(
          label: 'Your location',
          position: LatLng(position.latitude, position.longitude),
          color: Colors.blue,
          child: const Icon(Icons.person_pin_circle, color: Colors.blue, size: 42),
        ),
      );
    }
    for (final center in _filteredABTCs) {
      final abtc = center.abtc;
      if (!abtc.hasCoordinates) continue;
      markers.add(
        CRISMapMarker(
          label: abtc.name,
          position: LatLng(abtc.latitude!, abtc.longitude!),
          child: ABTCMarkerWidget(abtc: abtc, onTap: () => _showCenterInfo(abtc)),
        ),
      );
    }
    return markers;
  }

  void _showCenterInfo(ABTCModel abtc) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(abtc.name, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              _InfoLine(icon: Icons.location_on_outlined, text: abtc.completeAddress),
              const SizedBox(height: 7),
              _InfoLine(icon: Icons.schedule_outlined, text: abtc.schedule),
              const SizedBox(height: 7),
              _InfoLine(icon: Icons.medical_information_outlined, text: abtc.availability),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        _openDetails(abtc);
                      },
                      child: const Text('View Details'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        _openDirections(abtc);
                      },
                      icon: const Icon(Icons.directions),
                      label: const Text('Directions'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openDetails(ABTCModel abtc) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ABTCDetailsScreen(abtc: abtc)),
    );
  }

  Future<void> _openDirections(ABTCModel abtc) async {
    final origin = _userPosition;
    if (origin == null) {
      _showMessage('Your current location is needed to open directions.');
      return;
    }
    if (!abtc.hasCoordinates) {
      _showMessage('Directions are unavailable because this center has no valid coordinates.');
      return;
    }

    final uri = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'origin': '${origin.latitude},${origin.longitude}',
      'destination': '${abtc.latitude},${abtc.longitude}',
      'travelmode': 'driving',
    });
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && mounted) {
      _showMessage('Google Maps could not be opened on this device.');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final mapCenter = _mapCenter;
    return Theme(
      data: Theme.of(context).copyWith(useMaterial3: true),
      child: Scaffold(
        appBar: AppBar(title: const Text('Animal Bite Treatment Centers')),
        body: Stack(
          children: [
            Positioned.fill(
              child: mapCenter == null
                  ? const _MapUnavailable()
                  : CRISMap(
                      center: mapCenter,
                      zoom: _userPosition == null ? 12 : 15,
                      markers: _markers,
                      height: MediaQuery.sizeOf(context).height,
                    ),
            ),
            Positioned(
              top: 14,
              left: 16,
              right: 16,
              child: _SearchBar(
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value),
              ),
            ),
            if (_locationMessage != null)
              Positioned(
                top: 78,
                left: 16,
                right: 16,
                child: _LocationNotice(message: _locationMessage!),
              ),
            DraggableScrollableSheet(
              initialChildSize: 0.36,
              minChildSize: 0.25,
              maxChildSize: 0.82,
              builder: (context, scrollController) => Material(
                elevation: 12,
                color: Theme.of(context).colorScheme.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
                clipBehavior: Clip.antiAlias,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: _isLoading
                      ? ListView(
                          key: const ValueKey('loading'),
                          controller: scrollController,
                          children: const [
                            SizedBox(height: 22),
                            Center(child: CircularProgressIndicator()),
                          ],
                        )
                      : ABTCListWidget(
                          key: ValueKey(_loadError ?? _filteredABTCs.length),
                          centers:
                              _loadError == null ? _filteredABTCs : const [],
                          scrollController: scrollController,
                          nearestABTCId: _nearestABTCId,
                          emptyMessage: _loadError ??
                              (_abtcs.isEmpty
                                  ? 'No Animal Bite Treatment Centers are currently available.'
                                  : 'No centers found for your search.'),
                          onViewDetails: _openDetails,
                          onDirections: _openDirections,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(16),
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: 'Search by name, municipality, or barangay',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      );
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
              Expanded(child: Text(message, style: Theme.of(context).textTheme.bodySmall)),
            ],
          ),
        ),
      );
}

class _MapUnavailable extends StatelessWidget {
  const _MapUnavailable();

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: AppColors.cream,
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Text(
              'The map will appear when a location or a center with valid coordinates is available.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      );
}
