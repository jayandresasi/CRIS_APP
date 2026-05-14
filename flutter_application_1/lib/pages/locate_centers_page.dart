import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../theme.dart';

class LocateCentersPage extends StatefulWidget {
  const LocateCentersPage({super.key});

  @override
  State<LocateCentersPage> createState() => _LocateCentersPageState();
}

class _LocateCentersPageState extends State<LocateCentersPage> {
  final TextEditingController _searchController = TextEditingController();
  GoogleMapController? _mapController;
  String _searchQuery = '';

  // Default center: Iloilo City, Philippines
  static const LatLng _defaultCenter = LatLng(10.7202, 122.5621);

  // Hardcoded nearby ABTCs — replace with live API data as needed
  final List<_ABTCCenter> _centers = [
    _ABTCCenter(
      name: 'Iloilo City Health Office ABTC',
      address: 'M.H. del Pilar Street, Iloilo City',
      phone: '033-333-1111',
      schedule: 'Monday–Friday, 8:00 AM – 5:00 PM',
      availability: 'Available: March 18–22',
      position: const LatLng(10.7202, 122.5621),
    ),
    _ABTCCenter(
      name: 'Western Visayas Medical Center ABTC',
      address: 'Q. Abeto Street, Mandurriao, Iloilo City',
      phone: '033-321-2841',
      schedule: 'Monday–Saturday, 8:00 AM – 6:00 PM',
      availability: 'Available: March 19–23',
      position: const LatLng(10.7356, 122.5494),
    ),
    _ABTCCenter(
      name: 'Iloilo Provincial Hospital ABTC',
      address: 'Luna Street, Pototan, Iloilo',
      phone: '033-529-0011',
      schedule: 'Monday–Friday, 8:00 AM – 5:00 PM',
      availability: 'Available: March 18–25',
      position: const LatLng(10.9503, 122.6347),
    ),
    _ABTCCenter(
      name: 'La Paz Health Center ABTC',
      address: 'Diversion Road, La Paz, Iloilo City',
      phone: '033-320-0055',
      schedule: 'Monday–Friday, 7:00 AM – 4:00 PM',
      availability: 'Available: March 20–24',
      position: const LatLng(10.7287, 122.5497),
    ),
  ];

  List<_ABTCCenter> get _filtered {
    if (_searchQuery.isEmpty) return _centers;
    final q = _searchQuery.toLowerCase();
    return _centers
        .where(
          (c) =>
              c.name.toLowerCase().contains(q) ||
              c.address.toLowerCase().contains(q),
        )
        .toList();
  }

  Set<Marker> get _markers => _filtered
      .map(
        (c) => Marker(
          markerId: MarkerId(c.name),
          position: c.position,
          infoWindow: InfoWindow(title: c.name, snippet: c.address),
        ),
      )
      .toSet();

  @override
  void dispose() {
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.accent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Locate Animal Bite Centers',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(
        children: [
          // ── Search bar ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search centers or address',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          // ── Google Map ────────────────────────────────────────
          SizedBox(
            height: 220,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: GoogleMap(
                  initialCameraPosition: const CameraPosition(
                    target: _defaultCenter,
                    zoom: 13,
                  ),
                  markers: _markers,
                  onMapCreated: (c) => _mapController = c,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Nearby ABTC label ─────────────────────────────────
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Nearby ABTC',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // ── Center list ───────────────────────────────────────
          Expanded(
            child: _filtered.isEmpty
                ? const Center(child: Text('No centers found.'))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _CenterCard(center: _filtered[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Model ──────────────────────────────────────────────────────────────────────
class _ABTCCenter {
  final String name;
  final String address;
  final String phone;
  final String schedule;
  final String availability;
  final LatLng position;

  const _ABTCCenter({
    required this.name,
    required this.address,
    required this.phone,
    required this.schedule,
    required this.availability,
    required this.position,
  });
}

// ── Center Card ────────────────────────────────────────────────────────────────
class _CenterCard extends StatelessWidget {
  final _ABTCCenter center;
  const _CenterCard({required this.center});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              center.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 14,
                  color: Colors.grey,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    center.address,
                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(Icons.phone_outlined, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(center.phone, style: const TextStyle(fontSize: 12)),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'Schedule: ${center.schedule}',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 4),
            Text(
              center.availability,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
