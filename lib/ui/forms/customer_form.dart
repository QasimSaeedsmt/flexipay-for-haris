import 'package:flexipay/data/models/customer_model.dart';
import 'package:flexipay/services/customer_services.dart';
import 'package:flutter/material.dart';

class CustomerForm extends StatelessWidget {
  const CustomerForm({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTextFormField("Name", nameController),
          _buildTextFormField("Father Name", fatherNameController),
          _buildTextFormField("Full Address", addressController),
          _buildTextFormField("Phone Number", phoneNumberController),
          _buildTextFormField("Total Balance", totalBalanceController),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              CustomerModel customer = CustomerModel(
                fullName: nameController.text,
                fatherName: fatherNameController.text,
                fullAddress: addressController.text,
                id: "01",
                phoneNumber: phoneNumberController.text,
                totalBalance: double.parse(totalBalanceController.text),
              );
              CustomerService service = CustomerService();
              service.addCustomer(customer);
            },
            child: Text("Submit"),
          ),
        ],
      ),
    );
  }
}

TextEditingController nameController = TextEditingController();
TextEditingController fatherNameController = TextEditingController();
TextEditingController phoneNumberController = TextEditingController();
TextEditingController addressController = TextEditingController();
TextEditingController totalBalanceController = TextEditingController();

_buildTextFormField(String label, TextEditingController controller) {
  return Column(
    children: [
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: TextFormField(
          controller: controller,
          decoration: InputDecoration(labelText: label),
        ),
      ),
      SizedBox(height: 15),
    ],
  );
}
