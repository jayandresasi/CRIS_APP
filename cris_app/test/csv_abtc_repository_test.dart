import 'package:flutter_test/flutter_test.dart';

import 'package:cris_app/repositories/csv_abtc_repository.dart';

void main() {
  test('loads valid CSV locations and skips invalid coordinate rows', () async {
    final repository = CsvABTCRepository(
      loadString: (_) async =>
          '''Name,Tel_No,Email,Street,Municipality,Latitude,Longitude,Availability,Done
Center One,123,one@example.com,"Main, Street",Iloilo,10.7000,122.5000,Open,
Missing coordinates,456,two@example.com,Side Street,Iloilo,,122.6000,Open,
Invalid coordinates,789,three@example.com,Other Street,Iloilo,n/a,122.7000,Open,
''',
    );

    final locations = await repository.fetchABTCs();

    expect(locations, hasLength(1));
    expect(locations.single.name, 'Center One');
    expect(locations.single.streetAddress, 'Main, Street');
    expect(locations.single.telephone, '123');
    expect(locations.single.email, 'one@example.com');
    expect(locations.single.hasCoordinates, isTrue);
  });
}
