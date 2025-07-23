import 'item_model.dart';

class CustomerModel {
  String? id; // <-- Add this line if missing
  String? fullName;
  String? fatherName;
  String? fullAddress;
  String? phoneNumber;
  List<ItemModel>? items;
  double? totalBalance;

  CustomerModel({
    this.id,
    this.fullName,
    this.fatherName,
    this.fullAddress,
    this.phoneNumber,
    this.items,
    this.totalBalance,
  });

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'fatherName': fatherName,
      'fullAddress': fullAddress,
      'phoneNumber': phoneNumber,
      'totalBalance': totalBalance,
      'items': items?.map((e) => e.toMap()).toList() ?? [],
    };
  }

  factory CustomerModel.fromMap(Map<String, dynamic> map) {
    return CustomerModel(
      fullName: map['fullName'],
      fatherName: map['fatherName'],
      fullAddress: map['fullAddress'],
      phoneNumber: map['phoneNumber'],
      totalBalance: (map['totalBalance'] ?? 0).toDouble(),
      items: map['items'] != null
          ? List<ItemModel>.from(
          (map['items'] as List).map((x) => ItemModel.fromMap(x)))
          : [],
    );
  }
}
