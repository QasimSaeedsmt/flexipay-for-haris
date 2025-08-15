class ItemModel {
  String? itemName;
  String? itemDescription;
  double? actualPrice;
  double? totalPaid;
  double? installmentPerMonth;
  double? installmentTotalPrice;
  double? remainingAmount;
  DateTime? startDate;

  // ✅ New fields
  DateTime? startingMonth;
  DateTime? endingMonth;

  ItemModel({
    this.itemName,
    this.itemDescription,
    this.actualPrice,
    this.totalPaid,
    this.installmentPerMonth,
    this.installmentTotalPrice,
    this.remainingAmount,
    this.startDate,
    this.startingMonth,
    this.endingMonth,
  });

  // ✅ Converts an ItemModel object into a Map
  Map<String, dynamic> toMap() {
    return {
      'itemName': itemName,
      'itemDescription': itemDescription,
      'actualPrice': actualPrice,
      'totalPaid': totalPaid,
      'installmentPerMonth': installmentPerMonth,
      'installmentTotalPrice': installmentTotalPrice,
      'remainingAmount': remainingAmount,
      'startDate': startDate?.toIso8601String(),
      'startingMonth': startingMonth?.toIso8601String(),
      'endingMonth': endingMonth?.toIso8601String(),
    };
  }

  // ✅ Creates an ItemModel object from a Map
  factory ItemModel.fromMap(Map<String, dynamic> map) {
    return ItemModel(
      itemName: map['itemName'],
      itemDescription: map['itemDescription'],
      actualPrice: (map['actualPrice'] ?? 0).toDouble(),
      totalPaid: (map['totalPaid'] ?? 0).toDouble(),
      installmentPerMonth: (map['installmentPerMonth'] ?? 0).toDouble(),
      installmentTotalPrice: (map['installmentTotalPrice'] ?? 0).toDouble(),
      remainingAmount: (map['remainingAmount'] ?? 0).toDouble(),
      startDate: map['startDate'] != null
          ? DateTime.tryParse(map['startDate'])
          : null,
      startingMonth: map['startingMonth'] != null
          ? DateTime.tryParse(map['startingMonth'])
          : null,
      endingMonth: map['endingMonth'] != null
          ? DateTime.tryParse(map['endingMonth'])
          : null,
    );
  }
}
