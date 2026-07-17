import 'package:geolocator/geolocator.dart';

import '../models/abtc_model.dart';

class ABTCWithDistance {
  const ABTCWithDistance({required this.abtc, this.distanceInMeters});

  final ABTCModel abtc;
  final double? distanceInMeters;

  String get distanceLabel {
    final distance = distanceInMeters;
    if (distance == null) return 'Distance unavailable';
    if (distance < 1000) return '${distance.round()} m away';
    return '${(distance / 1000).toStringAsFixed(2)} km away';
  }
}

class NearestABTCService {
  List<ABTCWithDistance> sortByDistance({
    required List<ABTCModel> abtcs,
    double? userLatitude,
    double? userLongitude,
  }) {
    final results = abtcs.map((abtc) {
      final canCalculate = userLatitude != null &&
          userLongitude != null &&
          abtc.hasCoordinates;
      final distance = canCalculate
          ? Geolocator.distanceBetween(
              userLatitude,
              userLongitude,
              abtc.latitude!,
              abtc.longitude!,
            )
          : null;
      return ABTCWithDistance(abtc: abtc, distanceInMeters: distance);
    }).toList();

    results.sort((a, b) {
      final first = a.distanceInMeters;
      final second = b.distanceInMeters;
      if (first == null && second == null) return a.abtc.name.compareTo(b.abtc.name);
      if (first == null) return 1;
      if (second == null) return -1;
      return first.compareTo(second);
    });
    return results;
  }
}
