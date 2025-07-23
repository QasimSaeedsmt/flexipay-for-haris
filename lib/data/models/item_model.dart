class ItemModel {
  String? itemName;
  String? itemDescription;
  double? actualPrice;
  double? installmentPerMonth;
  double? totalPaid;
  double? remainingAmount;
  DateTime? startDate; // ✅ New field added

  ItemModel({
    this.itemName,
    this.itemDescription,
    this.installmentPerMonth,
    this.actualPrice,
    this.remainingAmount,
    this.totalPaid,
    this.startDate,
  });

  // ✅ Converts an ItemModel object into a Map
  Map<String, dynamic> toMap() {
    return {
      'itemName': itemName,
      'itemDescription': itemDescription,
      'actualPrice': actualPrice,
      'installmentPerMonth': installmentPerMonth,
      'totalPaid': totalPaid,
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
      installmentPerMonth: (map['installmentPerMonth'] ?? 0).toDouble(),
      totalPaid: (map['totalPaid'] ?? 0).toDouble(),
      remainingAmount: (map['remainingAmount'] ?? 0).toDouble(),
      startDate: map['startDate'] != null
          ? DateTime.tryParse(map['startDate'])
          : null,
    );
  }
}
