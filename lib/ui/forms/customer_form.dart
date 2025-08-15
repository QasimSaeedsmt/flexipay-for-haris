import 'package:flexipay/data/models/customer_model.dart';
import 'package:flexipay/services/customer_services.dart';
import 'package:flutter/material.dart';

class CustomerForm extends StatefulWidget {
  const CustomerForm({super.key});

  @override
  State<CustomerForm> createState() => _CustomerFormState();
}

class _CustomerFormState extends State<CustomerForm> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _fatherNameController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _totalBalanceController = TextEditingController();

  bool _isSubmitting = false;

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      CustomerModel customer = CustomerModel(
        fullName: _nameController.text.trim(),
        fatherName: _fatherNameController.text.trim(),
        fullAddress: _addressController.text.trim(),
        phoneNumber: _phoneNumberController.text.trim(),
        totalBalance: double.tryParse(_totalBalanceController.text.trim()),
        id: DateTime.now().millisecondsSinceEpoch.toString(), // Use timestamp as ID
      );

      await CustomerService().addCustomer(customer);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Customer added successfully')),
      );

      _formKey.currentState?.reset();
      _nameController.clear();
      _fatherNameController.clear();
      _phoneNumberController.clear();
      _addressController.clear();
      _totalBalanceController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add customer: $e')),
      );
    }

    setState(() => _isSubmitting = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _fatherNameController.dispose();
    _phoneNumberController.dispose();
    _addressController.dispose();
    _totalBalanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add New Customer')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 4,
          margin: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildField('Full Name', _nameController, validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Name is required';
                    }
                    return null;
                  }),
                  _buildField('Father Name', _fatherNameController, validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Father name is required';
                    }
                    return null;
                  }),
                  _buildField('Phone Number', _phoneNumberController,
                      keyboardType: TextInputType.phone,
                      validator: (val) {
                        if (val == null || val.trim().length < 10) {
                          return 'Enter a valid phone number';
                        }
                        return null;
                      }),
                  _buildField('Full Address', _addressController, validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Address is required';
                    }
                    return null;
                  }),
                  // _buildField('Initial Total Balance (Rs)', _totalBalanceController,
                  //     keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  //     validator: (val) {
                  //       if (val == null || double.tryParse(val.trim()) == null) {
                  //         return 'Enter a valid amount';
                  //       }
                  //       return null;
                  //     }),
                  const SizedBox(height: 24),
                  _isSubmitting
                      ? const CircularProgressIndicator()
                      : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text('Add Customer'),
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(
      String label,
      TextEditingController controller, {
        TextInputType keyboardType = TextInputType.text,
        String? Function(String?)? validator,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
