import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/models/message_model.dart';

class MessageLogService {
  static final _firestore = FirebaseFirestore.instance;
  static final _collection = _firestore.collection('message_logs');

  static Future<void> logMessage(MessageLogModel log) async {
    await _collection.add(log.toMap());
  }

  static Future<bool> hasMessageBeenSent({
    required String customerId,
    required String itemName,
    required String month,
  }) async {
    final query = await _collection
        .where('customerId', isEqualTo: customerId)
        .where('itemName', isEqualTo: itemName)
        .where('month', isEqualTo: month)
        .get();

    return query.docs.isNotEmpty;
  }
}
