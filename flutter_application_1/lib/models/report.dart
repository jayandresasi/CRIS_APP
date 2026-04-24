import 'package:hive/hive.dart';

/// Represents a submitted bite incident report.
class Report {
  Report({
    required this.lastName,
    required this.firstName,
    required this.middleInitial,
    required this.suffix,
    required this.age,
    required this.gender,
    required this.contactNumber,
    required this.address,
    required this.dateOfIncident,
    required this.timeOfIncident,
    required this.locationOfIncident,
    required this.exposureType,
    required this.animalSpecies,
    required this.animalOwnership,
    required this.animalVaccinationStatus,
    required this.incidentDescription,
    required this.firstAidGiven,
    required this.patientVaccinationStatus,
    required this.reportedAt,
  });

  final String lastName;
  final String firstName;
  final String middleInitial;
  final String suffix;
  final String age;
  final String gender;
  final String contactNumber;
  final String address;

  final String dateOfIncident;
  final String timeOfIncident;
  final String locationOfIncident;
  final String exposureType;
  final String animalSpecies;
  final String animalOwnership;
  final String animalVaccinationStatus;
  final String incidentDescription;

  final String firstAidGiven;
  final String patientVaccinationStatus;

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

class ReportAdapter extends TypeAdapter<Report> {
  @override
  final int typeId = 0;

  @override
  Report read(BinaryReader reader) {
    return Report(
      lastName: reader.readString(),
      firstName: reader.readString(),
      middleInitial: reader.readString(),
      suffix: reader.readString(),
      age: reader.readString(),
      gender: reader.readString(),
      contactNumber: reader.readString(),
      address: reader.readString(),
      dateOfIncident: reader.readString(),
      timeOfIncident: reader.readString(),
      locationOfIncident: reader.readString(),
      exposureType: reader.readString(),
      animalSpecies: reader.readString(),
      animalOwnership: reader.readString(),
      animalVaccinationStatus: reader.readString(),
      incidentDescription: reader.readString(),
      firstAidGiven: reader.readString(),
      patientVaccinationStatus: reader.readString(),
      reportedAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
    );
  }

  @override
  void write(BinaryWriter writer, Report obj) {
    writer.writeString(obj.lastName);
    writer.writeString(obj.firstName);
    writer.writeString(obj.middleInitial);
    writer.writeString(obj.suffix);
    writer.writeString(obj.age);
    writer.writeString(obj.gender);
    writer.writeString(obj.contactNumber);
    writer.writeString(obj.address);
    writer.writeString(obj.dateOfIncident);
    writer.writeString(obj.timeOfIncident);
    writer.writeString(obj.locationOfIncident);
    writer.writeString(obj.exposureType);
    writer.writeString(obj.animalSpecies);
    writer.writeString(obj.animalOwnership);
    writer.writeString(obj.animalVaccinationStatus);
    writer.writeString(obj.incidentDescription);
    writer.writeString(obj.firstAidGiven);
    writer.writeString(obj.patientVaccinationStatus);
    writer.writeInt(obj.reportedAt.millisecondsSinceEpoch);
  }
}
