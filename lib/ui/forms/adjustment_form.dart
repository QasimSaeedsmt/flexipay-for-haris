import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:flexipay/data/models/item_model.dart';
import 'package:flexipay/data/models/customer_model.dart';
import 'package:flexipay/services/customer_services.dart';

class AdjustmentForm extends StatefulWidget {
  final String customerId;
  const AdjustmentForm({super.key, required this.customerId});

  @override
  State<AdjustmentForm> createState() => _AdjustmentFormState();
}

class _AdjustmentFormState extends State<AdjustmentForm> {
  CustomerModel? _customer;
  ItemModel? _selectedItem;
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = true;
  bool _generateReceipt = true;

  @override
  void initState() {
    super.initState();
    _loadCustomer();
  }

  Future<void> _loadCustomer() async {
    final customer = await CustomerService().getCustomerById(widget.customerId);
    setState(() {
      _customer = customer;
      _loading = false;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedItem == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all required fields')),
      );
      return;
    }

    final amount = double.parse(_amountController.text);

    // Add adjustment transaction - assuming you have a separate method for adjustments
    await CustomerService().addTransaction(
      transactionType:"Adjustment",
      monthKey: "N/A",
      customerId: widget.customerId,
      itemName: _selectedItem!.itemName!,
      amount: amount,
      notes: _notesController.text.trim(),
    );

    // Update item's remaining amount by subtracting the adjustment amount
    // (Positive adjustment reduces remaining amount, negative increases it)
    final updatedRemainingItemAmount =
        (_selectedItem!.remainingAmount ?? 0.0) - amount;
    _selectedItem!.remainingAmount = updatedRemainingItemAmount;

    // Update customer's total balance
    final updatedCustomerBalance = (_customer!.totalBalance ?? 0.0) - amount;
    _customer!.totalBalance = updatedCustomerBalance;

    // Update customer and item in DB
    await CustomerService().updateCustomerItemAndBalance(
      widget.customerId,
      _selectedItem!,
      _customer!.totalBalance!,
    );

    // Optional: generate receipt
    if (_generateReceipt) {
      final pdf = _buildReceiptPdf(amount);
      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'FlexiPay_Adjustment_Receipt.pdf',
      );
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Adjustment recorded')));

    setState(() {
      _amountController.clear();
      _notesController.clear();
      _selectedItem = null;
    });
  }

  pw.Document _buildReceiptPdf(double amount) {
    final pdf = pw.Document();
    final now = DateFormat('MMM d, y - h:mm a').format(DateTime.now());

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.all(24),
        build: (ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  'FlexiPay Adjustment Receipt',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blueGrey900,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              _pdfRow('Customer Name:', _customer?.fullName ?? 'N/A'),
              _pdfRow('Item:', _selectedItem!.itemName ?? ''),
              _pdfRow('Adjustment Amount:', 'Rs ${amount.toStringAsFixed(2)}'),
              _pdfRow(
                'Notes:',
                _notesController.text.trim().isEmpty
                    ? 'Adjustment entry'
                    : _notesController.text.trim(),
              ),
              _pdfRow('Date:', now),
              _pdfRow(
                'Balance:',
                'Rs ${_customer?.totalBalance?.toStringAsFixed(2) ?? '0.00'}',
              ),
              pw.Spacer(),
              pw.SizedBox(height: 24),
              pw.Divider(),
              pw.SizedBox(height: 12),
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'Thank you for choosing FlexiPay.',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontStyle: pw.FontStyle.italic,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      'Hafiz Haris Hussain',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.black,
                      ),
                    ),
                    pw.Text(
                      'Par Hoti Mardan',
                      style: pw.TextStyle(
                        fontSize: 11,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
    return pdf;
  }

  pw.Widget _pdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text(value),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final items = _customer?.items ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('Record Adjustment')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<ItemModel>(
                value: _selectedItem,
                decoration: const InputDecoration(
                  labelText: 'Select Item',
                  border: OutlineInputBorder(),
                ),
                items: items.map((i) {
                  return DropdownMenuItem(
                    value: i,
                    child: Text(i.itemName ?? ''),
                  );
                }).toList(),
                validator: (val) => val == null ? 'Select item' : null,
                onChanged: (i) => setState(() => _selectedItem = i),
              ),
              const SizedBox(height: 16),
              if (_selectedItem != null)
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Remaining Amount:',
                          style: TextStyle(fontSize: 16),
                        ),
                        Text(
                          'Rs ${_selectedItem!.remainingAmount?.toStringAsFixed(2) ?? '0.00'}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.numberWithOptions(
                  signed: true,  // ✅ Allows "-" sign
                  decimal: true,
                ),
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Adjustment Amount (positive or negative)',
                  border: OutlineInputBorder(),
                  prefixText: 'Rs ',
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d{0,2}')),
                ],
                validator: (val) {
                  if (val == null || val.isEmpty || double.tryParse(val) == null) {
                    return 'Enter valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Generate receipt?'),
                value: _generateReceipt,
                onChanged: (v) => setState(() => _generateReceipt = v),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _submit,
                child: const Text('Submit Adjustment'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
