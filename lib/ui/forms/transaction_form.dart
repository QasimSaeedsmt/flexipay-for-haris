import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:flexipay/data/models/item_model.dart';
import 'package:flexipay/data/models/customer_model.dart';
import 'package:flexipay/data/models/transaction_model.dart';
import 'package:flexipay/services/customer_services.dart';

class TransactionForm extends StatefulWidget {
  final String customerId;
  const TransactionForm({super.key, required this.customerId});

  @override
  State<TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends State<TransactionForm> {
  CustomerModel? _customer;
  ItemModel? _selectedItem;
  DateTime? _selectedMonth;
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final List<String> _usedMonths = [];
  bool _loading = true;
  bool _generateReceipt = true;

  double _alreadyPaidForSelectedMonth = 0.0;

  @override
  void initState() {
    super.initState();
    _loadCustomer();
  }

  Future<void> _loadCustomer() async {
    final customer = await CustomerService().getCustomerById(widget.customerId);
    final used = await CustomerService().getUsedMonths(widget.customerId);
    setState(() {
      _customer = customer;
      _usedMonths.addAll(used);
      _loading = false;
    });
  }

  Future<void> _updateAlreadyPaid() async {
    if (_selectedItem == null || _selectedMonth == null) {
      setState(() {
        _alreadyPaidForSelectedMonth = 0.0;
        _amountController.text = '';
      });
      return;
    }
    final monthKey = DateFormat('yyyy-MM').format(_selectedMonth!);
    final transactions = await CustomerService().getTransactionsForMonth(
      widget.customerId,
      monthKey,
    );

    double totalPaid = 0.0;
    for (var txn in transactions) {
      if (txn.itemName == _selectedItem!.itemName) {
        totalPaid += txn.transactionAmount ?? 0.0;
      }
    }

    final due = _selectedItem!.installmentPerMonth ?? 0.0;
    final remaining = (due - totalPaid).clamp(0.0, due);

    setState(() {
      _alreadyPaidForSelectedMonth = totalPaid;
      _amountController.text = remaining.toStringAsFixed(2);
    });
  }

  void _pickMonth() async {
    final picked = await showMonthPicker(
      context: context,
      initialDate: _selectedMonth ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      final key = DateFormat('yyyy-MM').format(picked);

      final due = _selectedItem?.installmentPerMonth ?? 0.0;

      // Fetch already paid for this month & item
      final transactions = await CustomerService().getTransactionsForMonth(
        widget.customerId,
        key,
      );

      double totalPaid = 0.0;
      for (var txn in transactions) {
        if (txn.itemName == _selectedItem!.itemName) {
          totalPaid += txn.transactionAmount ?? 0.0;
        }
      }

      // Only block selection if full amount is already paid
      if (totalPaid >= due) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Full installment for $key already recorded')),
        );
        return;
      }

      setState(() => _selectedMonth = picked);

      await _updateAlreadyPaid();
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() ||
        _selectedItem == null ||
        _selectedMonth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all required fields')),
      );
      return;
    }

    final amount = double.parse(_amountController.text);
    final due = _selectedItem!.installmentPerMonth ?? 0.0;
    final remaining = (due - _alreadyPaidForSelectedMonth).clamp(0.0, due);

    if (amount > remaining) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Max allowed amount to pay: Rs ${remaining.toStringAsFixed(0)}',
          ),
        ),
      );
      return;
    }

    final monthKey = DateFormat('yyyy-MM').format(_selectedMonth!);

    // ✅ Add transaction
    await CustomerService().addTransaction(
      transactionType: "Monthly Installment",
      customerId: widget.customerId,
      itemName: _selectedItem!.itemName!,
      monthKey: monthKey,
      amount: amount,
      notes: _notesController.text.trim(),
    );

    // ✅ Update item's remaining amount
    final updatedRemainingItemAmount =
        (_selectedItem!.remainingAmount ?? 0.0) - amount;
    _selectedItem!.remainingAmount = updatedRemainingItemAmount;

    // ✅ Update customer's total balance
    final updatedCustomerBalance = (_customer!.totalBalance ?? 0.0) - amount;
    _customer!.totalBalance = updatedCustomerBalance;

    // ✅ Push both item and customer updates to Firestore
    await CustomerService().updateCustomerItemAndBalance(
      widget.customerId,
      _selectedItem!,
      _customer!.totalBalance!,
    );

    // ✅ Optional: generate receipt
    if (_generateReceipt) {
      final pdf = _buildReceiptPdf(amount, due, monthKey);
      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'FlexiPay_Receipt.pdf',
      );
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Installment recorded')));

    setState(() {
      _alreadyPaidForSelectedMonth += amount;

      if (_alreadyPaidForSelectedMonth >= due) {
        _usedMonths.add(monthKey);
      }

      _selectedMonth = null;
      _notesController.clear();

      final remaining = (due - _alreadyPaidForSelectedMonth).clamp(0.0, due);
      _amountController.text = remaining.toStringAsFixed(0);

      if (_alreadyPaidForSelectedMonth >= due) {
        _alreadyPaidForSelectedMonth = 0.0;
      }
    });
  }

  pw.Document _buildReceiptPdf(double amount, double due, String monthKey) {
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
                  'SHAZ Receipt',
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
              _pdfRow('Installment Month:', monthKey),
              _pdfRow('Amount Paid:', 'Rs ${amount.toStringAsFixed(0)}'),
              _pdfRow('Monthly Due:', 'Rs ${due.toStringAsFixed(0)}'),
              // _pdfRow(
              //   'Remaining Balance:',
              //   'Rs ${(due - (amount + _alreadyPaidForSelectedMonth)).clamp(0, due).toStringAsFixed(0)}',
              // ),
              _pdfRow(
                'Notes:',
                _notesController.text.trim().isEmpty
                    ? 'Monthly Installment'
                    : _notesController.text.trim(),
              ),
              _pdfRow('Date:', now),
              _pdfRow(
                'Balance:',
                'Rs ${_selectedItem?.remainingAmount?.toStringAsFixed(0) ?? '0'}',
              ),


              pw.Spacer(),
              pw.SizedBox(height: 24),
              pw.Divider(),
              pw.SizedBox(height: 12),
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'Thank you for trusting SHAZ.',
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

  Future<void> _viewHistory() async {
    final txns = await CustomerService().getTransactions(widget.customerId);
    final pdf = pw.Document();

    txns.sort((a, b) => b.timestamp!.compareTo(a.timestamp!));

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build:
            (ctx) => [
              pw.Center(
                child: pw.Text(
                  'Transaction History',
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 16),
              ...txns.map((t) {
                return pw.Column(
                  children: [
                    pw.Divider(),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(t.transactionMonth ?? 'N/A'),
                        pw.Text(
                          'Rs ${t.transactionAmount?.toStringAsFixed(0) ?? '0.00'}',
                        ),
                      ],
                    ),
                    pw.Text(
                      'Notes: ${t.entryTime ?? '—'}',
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.SizedBox(height: 6),
                  ],
                );
              }),
            ],
      ),
    );

    await Printing.layoutPdf(onLayout: (f) => pdf.save());
  }
  bool _isItemFullyPaid(ItemModel item) {
    final remaining = item.remainingAmount ?? 0.0;
    return remaining <= 0.0;
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
      appBar: AppBar(title: const Text('Record Transaction')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<ItemModel>(
                value: _selectedItem != null && !_isItemFullyPaid(_selectedItem!)
                    ? _selectedItem
                    : null,
                decoration: const InputDecoration(
                  labelText: 'Select Item',
                  border: OutlineInputBorder(),
                ),
                items: items.map((i) {
                  final isPaid = _isItemFullyPaid(i);
                  return DropdownMenuItem(
                    value: isPaid ? null : i,
                    enabled: !isPaid,
                    child: Text(
                      '${i.itemName!}${isPaid ? ' (Paid)' : ''}',
                      style: TextStyle(
                        color: isPaid ? Colors.grey : Colors.black,
                        fontStyle: isPaid ? FontStyle.italic : FontStyle.normal,
                      ),
                    ),
                  );
                }).toList(),
                validator: (val) => val == null ? 'Select item' : null,
                onChanged: (i) async {
                  if (i != null && !_isItemFullyPaid(i)) {
                    setState(() => _selectedItem = i);
                    await _updateAlreadyPaid();
                  }
                },
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
                          'Monthly Due:',
                          style: TextStyle(fontSize: 16),
                        ),
                        Text(
                          'Rs ${_selectedItem!.installmentPerMonth?.toStringAsFixed(0)}',
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
              ListTile(
                title: const Text('Installment Month'),
                trailing: TextButton(
                  onPressed: _selectedItem == null ? null : _pickMonth,
                  child: Text(
                    _selectedMonth != null
                        ? DateFormat.yMMM().format(_selectedMonth!)
                        : 'Select Month',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Amount Paid',
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || double.tryParse(val) == null) {
                    return 'Enter valid amount';
                  }
                  final num = double.parse(val);
                  final due = _selectedItem?.installmentPerMonth ?? 0;
                  final remaining = (due - _alreadyPaidForSelectedMonth).clamp(
                    0,
                    due,
                  );
                  if (num > remaining) {
                    return 'Max allowed:Rs ${remaining.toStringAsFixed(0)}';
                  }
                  return null;
                },
              ),
              if (_selectedItem != null && _selectedMonth != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Remaining balance for selected month: Rs ${((_selectedItem!.installmentPerMonth ?? 0) - _alreadyPaidForSelectedMonth).clamp(0, _selectedItem!.installmentPerMonth ?? 0).toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.grey),
                  ),
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
                child: const Text('Submit Transaction'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _viewHistory,
                child: const Text('View & Print History'),
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
