import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  String? customerId;           // ✅ Newly added
  String? itemName;
  String? transactionType;
  String? transactionMonth;     // format: YYYY-MM
  String? entryTime;            // Human-readable timestamp
  double? transactionAmount;
  DateTime? timestamp;

  TransactionModel({
    this.customerId,            // ✅ Include in constructor
    this.itemName,
    this.transactionType,
    this.transactionMonth,
    this.entryTime,
    this.transactionAmount,
    this.timestamp,
  });

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      customerId: map['customerId'] as String?,         // ✅ fromMap
      itemName: map['itemName'] as String?,
      transactionType: map['transactionType'] as String?,
      transactionMonth: map['transactionMonth'] as String?,
      entryTime: map['entryTime'] as String?,
      transactionAmount: (map['transactionAmount'] as num?)?.toDouble(),
      timestamp: (map['timestamp'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,           // ✅ toMap
      'itemName': itemName,
      'transactionType': transactionType,
      'transactionMonth': transactionMonth,
      'entryTime': entryTime,
      'transactionAmount': transactionAmount,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }
}
