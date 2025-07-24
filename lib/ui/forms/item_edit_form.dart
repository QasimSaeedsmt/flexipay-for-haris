import 'package:flutter/material.dart';
import 'package:flexipay/data/models/item_model.dart';
import 'package:flexipay/services/customer_services.dart';

class ItemEditForm extends StatefulWidget {
  final String customerId;
  final ItemModel item;
  final int index;

  const ItemEditForm({
    super.key,
    required this.customerId,
    required this.item,
    required this.index,
  });

  @override
  State<ItemEditForm> createState() => _ItemEditFormState();
}

class _ItemEditFormState extends State<ItemEditForm> {
  late TextEditingController itemNameController;
  late TextEditingController itemDescriptionController;
  late TextEditingController actualPriceController;
  late TextEditingController totalPriceController;
  late TextEditingController monthlyInstallmentController;
  late TextEditingController remainingAmountController;

  @override
  void initState() {
    super.initState();

    // Pre-fill controllers with existing item data
    itemNameController = TextEditingController(text: widget.item.itemName ?? '');
    itemDescriptionController = TextEditingController(text: widget.item.itemDescription ?? '');
    actualPriceController = TextEditingController(text: widget.item.actualPrice?.toString() ?? '');
    totalPriceController = TextEditingController(text: widget.item.installmentTotalPrice?.toString() ?? '');
    monthlyInstallmentController =
        TextEditingController(text: widget.item.installmentPerMonth?.toString() ?? '');
    remainingAmountController =
        TextEditingController(text: widget.item.remainingAmount?.toString() ?? '');
  }

  @override
  void dispose() {
    itemNameController.dispose();
    itemDescriptionController.dispose();
    actualPriceController.dispose();
    totalPriceController.dispose();
    monthlyInstallmentController.dispose();
    remainingAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Item")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildTextFormField("Item Name", itemNameController),
            _buildTextFormField("Item Description", itemDescriptionController),
            _buildTextFormField("Actual Price", actualPriceController),
            _buildTextFormField("Total Price", totalPriceController),
            _buildTextFormField("Monthly Installment", monthlyInstallmentController),
            _buildTextFormField("Remaining Amount", remainingAmountController),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                ItemModel updatedItem = ItemModel(
                  startDate: DateTime.now(),
                  itemName: itemNameController.text,
                  itemDescription: itemDescriptionController.text,
                  actualPrice: double.tryParse(actualPriceController.text),
                  installmentTotalPrice: double.tryParse(totalPriceController.text),
                  installmentPerMonth: double.tryParse(monthlyInstallmentController.text),
                  remainingAmount: double.tryParse(remainingAmountController.text),
                );

                await CustomerService().updateItemForCustomer(
                  widget.customerId,
                  widget.index,
                  updatedItem,
                );

                Navigator.pop(context); // Close the form
              },
              child: const Text("Save Changes"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextFormField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        keyboardType: label.contains("Price") || label.contains("Installment")
            ? TextInputType.number
            : TextInputType.text,
      ),
    );
  }
}
