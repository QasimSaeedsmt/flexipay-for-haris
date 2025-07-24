import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  String? customerId;
  String? itemName;
  String? transactionType;
  String? transactionMonth;
  String? entryTime;
  double? transactionAmount;
  DateTime? timestamp;
  String? note; // ✅ Added note field

  TransactionModel({
    this.customerId,
    this.itemName,
    this.transactionType,
    this.transactionMonth,
    this.entryTime,
    this.transactionAmount,
    this.timestamp,
    this.note, // ✅ Include in constructor
  });

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      customerId: map['customerId'] as String?,
      itemName: map['itemName'] as String?,
      transactionType: map['transactionType'] as String?,
      transactionMonth: map['transactionMonth'] as String?,
      entryTime: map['entryTime'] as String?,
      transactionAmount: (map['transactionAmount'] as num?)?.toDouble(),
      timestamp: (map['timestamp'] as Timestamp?)?.toDate(),
      note: map['note'] as String?, // ✅ fromMap
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'itemName': itemName,
      'transactionType': transactionType,
      'transactionMonth': transactionMonth,
      'entryTime': entryTime,
      'transactionAmount': transactionAmount,
      'timestamp': FieldValue.serverTimestamp(),
      'note': note, // ✅ toMap
    };
  }
}
