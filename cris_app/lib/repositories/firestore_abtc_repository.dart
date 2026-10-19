import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/abtc_model.dart';
import 'abtc_repository.dart';

class FirestoreABTCRepository implements ABTCRepository {
  FirestoreABTCRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<List<ABTCModel>> fetchABTCs() async {
    // A missing Firestore collection is returned as an empty query snapshot.
    final snapshot = await _firestore.collection('abtcs').get();
    return snapshot.docs
        .map((document) => ABTCModel.fromFirestore(document.data(), document.id))
        .toList(growable: false);
  }
}
