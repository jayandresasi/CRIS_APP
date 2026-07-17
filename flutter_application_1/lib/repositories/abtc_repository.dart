import '../models/abtc_model.dart';

abstract class ABTCRepository {
  /// Retrieves the current ABTC records once. Callers retain the result locally.
  Future<List<ABTCModel>> fetchABTCs();
}
