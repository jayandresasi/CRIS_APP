class ABTCModel {
  const ABTCModel({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.province,
    required this.municipality,
    required this.barangay,
    required this.streetAddress,
    required this.schedule,
    required this.availability,
  });

  factory ABTCModel.fromFirestore(Map<String, dynamic> data, String documentId) {
    return ABTCModel(
      // The document ID is only used as a stable local key when abtcId is not set.
      id: _string(data['abtcId']).isNotEmpty ? _string(data['abtcId']) : documentId,
      name: _string(data['name'], fallback: 'Unnamed Animal Bite Treatment Center'),
      latitude: _double(data['latitude']),
      longitude: _double(data['longitude']),
      province: _string(data['province']),
      municipality: _string(data['municipality']),
      barangay: _string(data['barangay']),
      // Imported ABTC records use the CSV's real `Street` column, stored as
      // `street`. Keep the older field as a fallback for existing documents.
      streetAddress: _string(data['street'], fallback: _string(data['streetAddress'])),
      schedule: _string(data['schedule'], fallback: 'Schedule unavailable'),
      availability: _string(data['availability'], fallback: 'Availability unavailable'),
    );
  }

  final String id;
  final String name;
  final double? latitude;
  final double? longitude;
  final String province;
  final String municipality;
  final String barangay;
  final String streetAddress;
  final String schedule;
  final String availability;

  bool get hasCoordinates =>
      latitude != null &&
      longitude != null &&
      latitude! >= -90 &&
      latitude! <= 90 &&
      longitude! >= -180 &&
      longitude! <= 180;

  String get completeAddress {
    final parts = [streetAddress, barangay, municipality, province]
        .where((part) => part.trim().isNotEmpty)
        .toList();
    return parts.isEmpty ? 'Address unavailable' : parts.join(', ');
  }

  static String _string(Object? value, {String fallback = ''}) {
    if (value is String && value.trim().isNotEmpty) return value.trim();
    return fallback;
  }

  static double? _double(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim());
    return null;
  }
}
