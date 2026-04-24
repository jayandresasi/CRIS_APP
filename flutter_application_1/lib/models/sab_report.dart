import 'package:hive/hive.dart';

/// Represents a submitted suspicious animal behavior report.
class SABReport {
  SABReport({
    required this.lastName,
    required this.firstName,
    required this.middleInitial,
    required this.suffix,
    required this.contactNumber,
    required this.address,
    required this.dateOfObservation,
    required this.timeOfObservation,
    required this.location,
    required this.behaviorObserved,
    required this.description,
    required this.photoPath,
    this.longitude,
    this.latitude,
    required this.reportedAt,
  });

  final String lastName;
  final String firstName;
  final String middleInitial;
  final String suffix;
  final String contactNumber;
  final String address;

  final String dateOfObservation;
  final String timeOfObservation;
  final String location;
  final String behaviorObserved;
  final String description;

  final String photoPath;
  final double? longitude;
  final double? latitude;

  /// When report was submitted (device time).
  final DateTime reportedAt;

  String get fullName {
    final parts = [
      lastName,
      firstName,
    ].where((part) => part.trim().isNotEmpty).toList();
    return parts.join(', ');
  }
}

class SABReportAdapter extends TypeAdapter<SABReport> {
  @override
  final int typeId = 1;

  @override
  SABReport read(BinaryReader reader) {
    return SABReport(
      lastName: reader.readString(),
      firstName: reader.readString(),
      middleInitial: reader.readString(),
      suffix: reader.readString(),
      contactNumber: reader.readString(),
      address: reader.readString(),
      dateOfObservation: reader.readString(),
      timeOfObservation: reader.readString(),
      location: reader.readString(),
      behaviorObserved: reader.readString(),
      description: reader.readString(),
      photoPath: reader.readString(),
      longitude: reader.readDouble(),
      latitude: reader.readDouble(),
      reportedAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
    );
  }

  @override
  void write(BinaryWriter writer, SABReport obj) {
    writer.writeString(obj.lastName);
    writer.writeString(obj.firstName);
    writer.writeString(obj.middleInitial);
    writer.writeString(obj.suffix);
    writer.writeString(obj.contactNumber);
    writer.writeString(obj.address);
    writer.writeString(obj.dateOfObservation);
    writer.writeString(obj.timeOfObservation);
    writer.writeString(obj.location);
    writer.writeString(obj.behaviorObserved);
    writer.writeString(obj.description);
    writer.writeString(obj.photoPath);
    writer.writeDouble(obj.longitude ?? 0.0);
    writer.writeDouble(obj.latitude ?? 0.0);
    writer.writeInt(obj.reportedAt.millisecondsSinceEpoch);
  }
}
