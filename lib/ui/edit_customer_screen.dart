import 'package:flutter/material.dart';
import 'package:flexipay/data/models/customer_model.dart';
import 'package:flexipay/services/customer_services.dart';

class EditCustomerScreen extends StatefulWidget {
  final CustomerModel customer;

  const EditCustomerScreen({super.key, required this.customer});

  @override
  State<EditCustomerScreen> createState() => _EditCustomerScreenState();
}

class _EditCustomerScreenState extends State<EditCustomerScreen> {
  late TextEditingController fullNameController;
  late TextEditingController fatherNameController;
  late TextEditingController addressController;
  late TextEditingController phoneController;
  late TextEditingController balanceController;

  @override
  void initState() {
    super.initState();

    fullNameController = TextEditingController(text: widget.customer.fullName ?? '');
    fatherNameController = TextEditingController(text: widget.customer.fatherName ?? '');
    addressController = TextEditingController(text: widget.customer.fullAddress ?? '');
    phoneController = TextEditingController(text: widget.customer.phoneNumber ?? '');
    balanceController = TextEditingController(text: widget.customer.totalBalance?.toString() ?? '');
  }

  @override
  void dispose() {
    fullNameController.dispose();
    fatherNameController.dispose();
    addressController.dispose();
    phoneController.dispose();
    balanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Customer")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildField("Full Name", fullNameController),
            _buildField("Father Name", fatherNameController),
            _buildField("Full Address", addressController),
            _buildField("Phone Number", phoneController, keyboardType: TextInputType.phone),
            _buildField("Total Balance", balanceController, keyboardType: TextInputType.number),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: const Text("Save Changes"),
              onPressed: () async {
                final updatedCustomer = CustomerModel(
                  fullName: fullNameController.text,
                  fatherName: fatherNameController.text,
                  fullAddress: addressController.text,
                  phoneNumber: phoneController.text,
                  totalBalance: double.tryParse(balanceController.text) ?? 0,
                  items: widget.customer.items, // Keep existing items
                );

                if (widget.customer.id != null) {
                  await CustomerService().updateCustomer(widget.customer.id!, updatedCustomer);
                  Navigator.pop(context); // Go back after saving
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Error: Missing customer ID")),
                  );
                }
              },
            )
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
