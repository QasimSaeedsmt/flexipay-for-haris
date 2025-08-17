import 'package:intl/intl.dart';

class InstallmentDue {
  final String month; // Format: 'yyyy-MM'
  final double amount;

  InstallmentDue({required this.month, required this.amount});
}

class ItemModel {
  String? itemName;
  String? itemDescription;
  double? actualPrice;
  double? totalPaid;
  double? installmentPerMonth;
  double? installmentTotalPrice;
  double? remainingAmount;
  DateTime? startDate;

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

  factory ItemModel.fromMap(Map<String, dynamic> map) {
    return ItemModel(
      itemName: map['itemName'],
      itemDescription: map['itemDescription'],
      actualPrice: (map['actualPrice'] ?? 0).toDouble(),
      totalPaid: (map['totalPaid'] ?? 0).toDouble(),
      installmentPerMonth: (map['installmentPerMonth'] ?? 0).toDouble(),
      installmentTotalPrice: (map['installmentTotalPrice'] ?? 0).toDouble(),
      remainingAmount: (map['remainingAmount'] ?? 0).toDouble(),
      startDate: map['startDate'] != null ? DateTime.tryParse(map['startDate']) : null,
      startingMonth: map['startingMonth'] != null ? DateTime.tryParse(map['startingMonth']) : null,
      endingMonth: map['endingMonth'] != null ? DateTime.tryParse(map['endingMonth']) : null,
    );
  }

  /// Generates a list of unpaid installments based on startingMonth and endingMonth
  List<InstallmentDue> get unpaidInstallments {
    if (startingMonth == null || endingMonth == null || installmentPerMonth == null) {
      return [];
    }

    // Defensive check: ensure startingMonth <= endingMonth
    if (startingMonth!.isAfter(endingMonth!)) {
      print('Warning: startingMonth is after endingMonth. Returning empty installment list.');
      return [];
    }

    final List<InstallmentDue> unpaid = [];

    final months = _generateMonthList(startingMonth!, endingMonth!);
    final totalInstallments = months.length;
    final paidInstallments = ((totalPaid ?? 0) / installmentPerMonth!).floor();

    print('Starting month: $startingMonth');
    print('Ending month: $endingMonth');
    print('Total months: $totalInstallments');
    print('Paid installments: $paidInstallments');

    for (int i = paidInstallments; i < totalInstallments; i++) {
      final month = months[i];
      final formattedMonth = DateFormat('yyyy-MM').format(month);

      unpaid.add(InstallmentDue(
        month: formattedMonth,
        amount: installmentPerMonth!,
      ));

      print('Adding unpaid installment: $formattedMonth, amount: ${installmentPerMonth!}');
    }

    return unpaid;
  }

  /// Generates a list of first-day-of-month Dates between start and end (inclusive)
  List<DateTime> _generateMonthList(DateTime start, DateTime end) {
    final List<DateTime> months = [];

    DateTime current = DateTime(start.year, start.month);

    // Defensive: return empty if start is after end
    if (current.isAfter(end)) {
      return months;
    }

    while (!current.isAfter(end)) {
      months.add(current);

      // Safe month increment with year overflow
      int nextMonth = current.month + 1;
      int nextYear = current.year;

      if (nextMonth > 12) {
        nextMonth = 1;
        nextYear += 1;
      }

      current = DateTime(nextYear, nextMonth);
    }

    return months;
  }
}
