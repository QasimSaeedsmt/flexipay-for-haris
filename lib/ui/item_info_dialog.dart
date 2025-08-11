import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/models/item_model.dart';

class ItemInfoDialog extends StatelessWidget {
  final ItemModel item;

  const ItemInfoDialog({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final totalPrice = item.installmentTotalPrice ?? 0;
    final remaining = item.remainingAmount ?? 0;
    final monthly = item.installmentPerMonth ?? 1; // prevent divide-by-zero
    final remainingMonths = monthly > 0 ? (remaining / monthly).ceil() : 0;

    // Debugging prints to check the item values
    print("Item Name: ${item.itemName}");
    print("Installment Total Price: ${item.installmentTotalPrice}");
    print("Remaining Amount: ${item.remainingAmount}");
    print("Actual Price: ${item.actualPrice}");
    print("Monthly Installment: ${item.installmentPerMonth}");

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.all(24),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: Colors.teal),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.itemName ?? "Unnamed Item",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (item.itemDescription != null && item.itemDescription!.isNotEmpty)
                Text(
                  item.itemDescription!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),

              const Divider(height: 30),

              _buildInfoRow("Actual Price", "PKR ${item.actualPrice?.toStringAsFixed(0) ?? '0'}"),
              _buildInfoRow("Total Price", "PKR ${totalPrice.toStringAsFixed(0) ?? '0'}"),
              _buildInfoRow("Total Paid", "PKR ${item.totalPaid?.toStringAsFixed(0)}"),
              _buildInfoRow("Remaining", "PKR ${remaining.toStringAsFixed(0)}"),
              _buildInfoRow("Monthly Installment", "PKR ${monthly.toStringAsFixed(0)}"),
              _buildInfoRow("Remaining Months", "$remainingMonths month(s)"),

              if (item.startDate != null)
                _buildInfoRow(
                  "Start Date",
                  DateFormat.yMMMMd().format(item.startDate!),
                ),

              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  label: const Text("Close"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              "$label:",
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.blueGrey,
            ),
          ),
        ],
      ),
    );
  }
}
