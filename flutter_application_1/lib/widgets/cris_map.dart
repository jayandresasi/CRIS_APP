import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

enum CRISMapLayerType { standard, satellite }

extension CRISMapLayerTypeX on CRISMapLayerType {
  String get label {
    switch (this) {
      case CRISMapLayerType.standard:
        return 'Standard';
      case CRISMapLayerType.satellite:
        return 'Satellite';
    }
  }

  IconData get icon {
    switch (this) {
      case CRISMapLayerType.standard:
        return Icons.map;
      case CRISMapLayerType.satellite:
        return Icons.satellite_alt;
    }
  }

  String get urlTemplate {
    switch (this) {
      case CRISMapLayerType.standard:
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
      case CRISMapLayerType.satellite:
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
    }
  }
}

class CRISMap extends StatefulWidget {
  const CRISMap({
    super.key,
    required this.center,
    this.zoom = 12,
    this.markers = const [],
    this.height = 220,
  });

  final LatLng center;
  final double zoom;
  final List<CRISMapMarker> markers;
  final double height;

  @override
  State<CRISMap> createState() => _CRISMapState();
}

class _CRISMapState extends State<CRISMap> {
  CRISMapLayerType _activeLayer = CRISMapLayerType.standard;

  @override
  Widget build(BuildContext context) {
    final maxZoom = _activeLayer == CRISMapLayerType.satellite ? 20.0 : 21.0;

    return SizedBox(
      height: widget.height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: widget.center,
                initialZoom: widget.zoom,
                maxZoom: maxZoom,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: CRISMapLayerType.standard.urlTemplate,
                  userAgentPackageName: 'com.example.cris_app',
                  maxNativeZoom: 19,
                  maxZoom: 21,
                  tileDimension: 256,
                ),
                if (_activeLayer == CRISMapLayerType.satellite)
                  TileLayer(
                    urlTemplate: _activeLayer.urlTemplate,
                    userAgentPackageName: 'com.example.cris_app',
                    maxNativeZoom: 19,
                    maxZoom: 19,
                    tileDimension: 256,
                    tileBuilder: (context, tileWidget, tile) {
                      return Opacity(opacity: 0.75, child: tileWidget);
                    },
                    errorTileCallback: (tile, error, stackTrace) {
                      debugPrint(
                          'Satellite tile load failed: $tile, error: $error');
                    },
                  ),
                MarkerLayer(
                  markers: widget.markers
                      .map(
                        (marker) => Marker(
                          point: marker.position,
                          width: 40,
                          height: 40,
                          child: Tooltip(
                            message: marker.label,
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            textStyle: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                            child: Icon(
                              Icons.location_pin,
                              color: marker.color,
                              size: 34,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
            Positioned(
              right: 12,
              bottom: 12,
              child: CRISMapLayerSwitcher(
                activeLayer: _activeLayer,
                onChanged: (layer) => setState(() => _activeLayer = layer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CRISMapLayerSwitcher extends StatelessWidget {
  const CRISMapLayerSwitcher({
    super.key,
    required this.activeLayer,
    required this.onChanged,
  });

  final CRISMapLayerType activeLayer;
  final ValueChanged<CRISMapLayerType> onChanged;

  @override
  Widget build(BuildContext context) {
    final nextLayer = activeLayer == CRISMapLayerType.standard
        ? CRISMapLayerType.satellite
        : CRISMapLayerType.standard;

    return FloatingActionButton.extended(
      heroTag: 'cris_map_layer_switcher',
      onPressed: () => onChanged(nextLayer),
      icon: Icon(activeLayer.icon),
      label: Text('${activeLayer.label} view'),
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
    );
  }
}

class CRISMapMarker {
  const CRISMapMarker({
    required this.label,
    required this.position,
    this.color = Colors.redAccent,
  });

  final String label;
  final LatLng position;
  final Color color;
}
