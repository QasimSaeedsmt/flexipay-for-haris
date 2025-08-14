import 'package:flexipay/data/models/item_model.dart';
import 'package:flexipay/services/customer_services.dart';
import 'package:flutter/material.dart';
import 'dart:math';

class ItemForm extends StatefulWidget {
  final String customerId;

  const ItemForm({super.key, required this.customerId});

  @override
  State<ItemForm> createState() => _ItemFormState();
}

class _ItemFormState extends State<ItemForm> {
  final TextEditingController itemNameController = TextEditingController();
  final TextEditingController itemDescriptionController =
      TextEditingController();
  final TextEditingController actualPriceController = TextEditingController();
  final TextEditingController totalPriceController = TextEditingController();
  final TextEditingController monthlyInstallmentController =
      TextEditingController();

  double remainingAmount = 0.0;
  int totalMonths = 0;
  double lastMonthAmount = 0.0;

  void _updateCalculations() {
    final total = double.tryParse(totalPriceController.text) ?? 0.0;
    final monthly = double.tryParse(monthlyInstallmentController.text) ?? 0.0;

    setState(() {
      remainingAmount = total;

      if (monthly > 0) {
        totalMonths = total ~/ monthly;
        lastMonthAmount = total % monthly;
        if (lastMonthAmount > 0) {
          totalMonths += 1;
        }
      } else {
        totalMonths = 0;
        lastMonthAmount = 0;
      }
    });
  }

  @override
  void dispose() {
    itemNameController.dispose();
    itemDescriptionController.dispose();
    actualPriceController.dispose();
    totalPriceController.dispose();
    monthlyInstallmentController.dispose();
    super.dispose();
  }

  Widget _buildTextFormField(
    String label,
    TextEditingController controller, {
    bool isNumber = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType:
            isNumber ? TextInputType.numberWithOptions(decimal: true) : null,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        onChanged: (_) => _updateCalculations(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Item for Customer')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildTextFormField("Item Name", itemNameController),
            _buildTextFormField("Item Description", itemDescriptionController),
            _buildTextFormField(
              "Actual Price",
              actualPriceController,
              isNumber: true,
            ),
            _buildTextFormField(
              "Total Price (PKR)",
              totalPriceController,
              isNumber: true,
            ),
            _buildTextFormField(
              "Monthly Installment (PKR)",
              monthlyInstallmentController,
              isNumber: true,
            ),

            const SizedBox(height: 20),

            // 💡 Summary Section
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.symmetric(vertical: 16),
              color: Colors.blueGrey[50],
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        "📋 Installment Plan Summary",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.blueGrey[800],
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        const Icon(Icons.attach_money, color: Colors.green),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            "Total Price:",
                            style: TextStyle(fontSize: 15),
                          ),
                        ),
                        Text(
                          "PKR ${remainingAmount.toStringAsFixed(0)}",
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Colors.orange),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            "Number of Months:",
                            style: TextStyle(fontSize: 15),
                          ),
                        ),
                        Text(
                          "$totalMonths",
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    if (totalMonths > 0 && lastMonthAmount > 0)
                      Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: Colors.redAccent,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              "Extra Last Month Amount:",
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 15),
                            ),
                          ),
                          Text(
                            "PKR ${lastMonthAmount.toStringAsFixed(0)}",
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.redAccent,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: () {
                final totalPrice = double.tryParse(totalPriceController.text);
                final monthly = double.tryParse(
                  monthlyInstallmentController.text,
                );
                final actual = double.tryParse(actualPriceController.text);

                if (totalPrice == null ||
                    monthly == null ||
                    actual == null ||
                    totalPrice <= 0 ||
                    monthly <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter valid prices')),
                  );
                  return;
                }

                final item = ItemModel(
                  startDate: DateTime.now(),
                  itemName: itemNameController.text.trim(),
                  itemDescription: itemDescriptionController.text.trim(),
                  actualPrice: actual,
                  installmentTotalPrice: totalPrice,
                  remainingAmount: totalPrice,
                  installmentPerMonth: monthly,
                  totalPaid: 0.0,
                );

                CustomerService().addItemToCustomer(widget.customerId, item);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Item added successfully')),
                );
                Navigator.pop(context);
              },
              child: const Text("Submit Item"),
            ),
          ],
        ),
      ),
    );
  }
}
