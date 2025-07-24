class ItemModel {
  String? itemName;
  String? itemDescription;
  double? actualPrice;
  double? totalPaid;             // <-- Newly added totalPrice
  double? installmentPerMonth;
  double? installmentTotalPrice;
  double? remainingAmount;
  DateTime? startDate; // ✅ New field added

  ItemModel({
    this.itemName,
    this.itemDescription,
    this.actualPrice,
    this.totalPaid,               // <-- include in constructor
    this.installmentPerMonth,
    this.installmentTotalPrice,
    this.remainingAmount,
    this.startDate,
  });

  // ✅ Converts an ItemModel object into a Map
  Map<String, dynamic> toMap() {
    return {
      'itemName': itemName,
      'itemDescription': itemDescription,
      'actualPrice': actualPrice,
      'totalPrice': totalPaid,                     // <-- added here
      'installmentPerMonth': installmentPerMonth,
      'totalPaid': installmentTotalPrice,
      'remainingAmount': remainingAmount,
      'startDate': startDate?.toIso8601String(), // ✅ Store as ISO string
    };
  }

  // ✅ Creates an ItemModel object from a Map
  factory ItemModel.fromMap(Map<String, dynamic> map) {
    return ItemModel(
      itemName: map['itemName'],
      itemDescription: map['itemDescription'],
      actualPrice: (map['actualPrice'] ?? 0).toDouble(),
      totalPaid: (map['totalPrice'] ?? 0).toDouble(),         // <-- added here
      installmentPerMonth: (map['installmentPerMonth'] ?? 0).toDouble(),
      installmentTotalPrice: (map['totalPaid'] ?? 0).toDouble(),
      remainingAmount: (map['remainingAmount'] ?? 0).toDouble(),
      startDate: map['startDate'] != null
          ? DateTime.tryParse(map['startDate'])
          : null,
    );
  }
}
