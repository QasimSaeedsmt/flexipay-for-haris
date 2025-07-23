import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flexipay/services/customer_services.dart';
import 'package:flexipay/data/models/transaction_model.dart';
import 'package:flexipay/data/models/customer_model.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({Key? key}) : super(key: key);

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final CustomerService _svc = CustomerService();
  List<TransactionModel> _allTxns = [];
  List<CustomerModel> _customers = [];
  bool _loading = true;

  CustomerModel? _selectedCustomer;
  DateTime? _filterMonth;
  DateTimeRange? _filterRange;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final customers = await _svc.getAllCustomers();
    List<TransactionModel> txns = [];
    for (var c in customers) {
      final t = await _svc.getTransactions(c.id!);
      txns.addAll(t);
    }
    setState(() {
      _customers = customers;
      _allTxns = txns;
      _loading = false;
    });
  }

  List<TransactionModel> get _filtered {
    return _allTxns.where((t) {
      if (_selectedCustomer != null && t.customerId != _selectedCustomer!.id) {
        return false;
      }
      if (_filterMonth != null) {
        final mKey = DateFormat('yyyy-MM').format(_filterMonth!);
        if (t.transactionMonth != mKey) return false;
      }
      if (_filterRange != null && t.timestamp != null) {
        final ts = t.timestamp!;
        if (ts.isBefore(_filterRange!.start) || ts.isAfter(_filterRange!.end)) {
          return false;
        }
      }
      return true;
    }).toList()
      ..sort((a, b) => b.timestamp!.compareTo(a.timestamp!));
  }

  Future<void> _generatePdf([TransactionModel? single]) async {
    final pdf = pw.Document();

    final List<TransactionModel> txns = single != null ? [single] : _filtered;

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build: (context) => [
        pw.Text(
          single != null ? 'Transaction Details' : 'Transaction Report',
          style: pw.TextStyle(fontSize: 26, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 12),

        // Show customer info or all customers
        pw.Text(
          single != null
              ? 'Customer: ${_selectedCustomer?.fullName ?? 'Unknown'}'
              : _selectedCustomer != null
              ? 'Customer: ${_selectedCustomer!.fullName}'
              : 'All Customers',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700),
        ),

        if (_filterMonth != null && single == null)
          pw.Text('Month: ${DateFormat.yMMMM().format(_filterMonth!)}', style: pw.TextStyle(fontSize: 14)),
        if (_filterRange != null && single == null)
          pw.Text(
            'Date Range: ${DateFormat.yMMMd().format(_filterRange!.start)} - ${DateFormat.yMMMd().format(_filterRange!.end)}',
            style: pw.TextStyle(fontSize: 14),
          ),

        pw.SizedBox(height: 20),

        // Single transaction detailed view
        if (single != null)
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _pdfDetailRow('Transaction Type', single.transactionType),
              _pdfDetailRow('Item', single.itemName),
              _pdfDetailRow('Amount', 'PKR ${single.transactionAmount?.toStringAsFixed(2) ?? "0.00"}'),
              _pdfDetailRow('Date', DateFormat.yMMMMd().add_jm().format(single.timestamp!)),
              if (single.transactionMonth != null)
                _pdfDetailRow('Transaction Month', single.transactionMonth),
              if (single.entryTime != null)
                _pdfDetailRow('Entry Time', single.entryTime),
            ],
          )
        else
        // Multiple transactions as a table
          pw.Table.fromTextArray(
            headers: [
              'Type',
              'Item',
              'Amount (PKR)',
              'Date',
              'Transaction Month',
            ],
            data: txns.map((t) => [
              t.transactionType ?? '-',
              t.itemName ?? '-',
              (t.transactionAmount ?? 0).toStringAsFixed(2),
              t.timestamp != null ? DateFormat.yMMMd().add_jm().format(t.timestamp!) : '-',
              t.transactionMonth ?? '-',
            ]).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12, color: PdfColors.white),
            headerDecoration: pw.BoxDecoration(color: PdfColors.blue800),
            cellStyle: pw.TextStyle(fontSize: 10, color: PdfColors.grey900),
            cellAlignment: pw.Alignment.centerLeft,
            border: pw.TableBorder.all(color: PdfColors.grey300),
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(3),
              2: const pw.FlexColumnWidth(2),
              3: const pw.FlexColumnWidth(3),
              4: const pw.FlexColumnWidth(2),
            },
          ),

        if (single == null) pw.Divider(),

        // Total amount footer for multiple transactions
        if (single == null)
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'Total Amount: PKR ${txns.fold(0.0, (sum, t) => sum + (t.transactionAmount ?? 0)).toStringAsFixed(2)}',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
          ),
      ],
    ));

    final filename = single != null ? 'transaction_detail.pdf' : 'transaction_report.pdf';
    await Printing.sharePdf(bytes: await pdf.save(), filename: filename);
  }

  pw.Widget _pdfDetailRow(String label, String? value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            flex: 2,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
            ),
          ),
          pw.Expanded(
            flex: 3,
            child: pw.Text(value ?? '-', style: pw.TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  void _showTransactionDetails(TransactionModel txn) {
    final customer = _customers.firstWhere((c) => c.id == txn.customerId, orElse: () => CustomerModel(fullName: 'Unknown'));

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(customer.fullName ?? 'Transaction Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow('Type', txn.transactionType),
            _detailRow('Item', txn.itemName),
            _detailRow('Amount', 'PKR ${txn.transactionAmount?.toStringAsFixed(2) ?? "0.00"}'),
            _detailRow('Date', DateFormat.yMMMMd().add_jm().format(txn.timestamp!)),
            if (txn.transactionMonth != null)
              _detailRow('Txn Month', txn.transactionMonth),
            if (txn.entryTime != null)
              _detailRow('Entry Time', txn.entryTime),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _generatePdf(txn);
            },
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Export This Txn'),
          ),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _generateCustomerPdf(txn.customerId!);
            },
            icon: const Icon(Icons.folder_copy),
            label: const Text('Export All of Customer'),
          ),
        ],
      ),
    );
  }
  Future<void> _generateCustomerPdf(String customerId) async {
    final customer = _customers.firstWhere(
          (c) => c.id == customerId,
      orElse: () => CustomerModel(fullName: 'Unknown'),
    );

    final customerTxns = _allTxns
        .where((t) => t.customerId == customerId)
        .toList()
      ..sort((a, b) => b.timestamp!.compareTo(a.timestamp!));

    final pdf = pw.Document();

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build: (context) => [
        pw.Header(
          level: 0,
          child: pw.Text(
            'Transaction Report for ${customer.fullName}',
            style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          'Generated on: ${DateFormat.yMMMMd().add_jm().format(DateTime.now())}',
          style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
        ),
        pw.SizedBox(height: 20),

        // Table headers and rows
        pw.Table.fromTextArray(
          border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey400),
          headerDecoration: pw.BoxDecoration(color: PdfColors.blue300),
          headerHeight: 25,
          cellHeight: 40,
          cellAlignments: {
            0: pw.Alignment.centerLeft,
            1: pw.Alignment.centerLeft,
            2: pw.Alignment.center,
            3: pw.Alignment.centerRight,
            4: pw.Alignment.center,
            5: pw.Alignment.center,
          },
          headers: [
            'Transaction Type',
            'Item Name',
            'Installment Month',
            'Amount (PKR)',
            'Transaction Date',
            'Entry Time',
          ],
          data: customerTxns.map((t) => [
            t.transactionType ?? '-',
            t.itemName ?? '-',
            t.transactionMonth ?? '-',
            t.transactionAmount?.toStringAsFixed(2) ?? '0.00',
            t.timestamp != null ? DateFormat.yMMMd().format(t.timestamp!) : '-',
            t.entryTime ?? '-',
          ]).toList(),
        ),

        pw.SizedBox(height: 20),

        // Summary
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.end,
          children: [
            pw.Text(
              'Total Transactions: ${customerTxns.length}',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(width: 20),
            pw.Text(
              'Total Amount: PKR ${customerTxns.fold(0.0, (sum, t) => sum + (t.transactionAmount ?? 0)).toStringAsFixed(2)}',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),
      ],
    ));

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'transaction_report_${customer.fullName?.replaceAll(" ", "_") ?? "customer"}.pdf',
    );
  }

  Widget _detailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          Flexible(child: Text(value ?? '-', textAlign: TextAlign.end)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _generatePdf,
            tooltip: 'Export All as PDF',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                DropdownButton<CustomerModel?>(
                  value: _selectedCustomer,
                  hint: const Text('All Customers'),
                  items: [null, ..._customers].map((c) {
                    return DropdownMenuItem(
                      value: c,
                      child: Text(c?.fullName ?? 'All Customers'),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => _selectedCustomer = v),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final m = await showMonthPicker(
                      context: context,
                      initialDate: _filterMonth ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (m != null) setState(() => _filterMonth = m);
                  },
                  child: Text(_filterMonth != null
                      ? DateFormat.yMMM().format(_filterMonth!)
                      : 'Filter by Month'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final r = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (r != null) setState(() => _filterRange = r);
                  },
                  child: Text(_filterRange != null
                      ? '${DateFormat.yMd().format(_filterRange!.start)} – ${DateFormat.yMd().format(_filterRange!.end)}'
                      : 'Filter by Range'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedCustomer = null;
                      _filterMonth = null;
                      _filterRange = null;
                    });
                  },
                  child: const Text('Clear Filters'),
                ),
              ],
            ),
            const Divider(height: 32),
            Expanded(
              child: _filtered.isEmpty
                  ? const Center(child: Text('No transactions found.'))
                  : ListView.builder(
                itemCount: _filtered.length,
                itemBuilder: (_, i) {
                  final t = _filtered[i];
                  return Card(
                    child: ListTile(
                      onTap: () => _showTransactionDetails(t),
                      title: Text(t.transactionType ?? '-'),
                      subtitle: Text(
                        '${DateFormat.yMMMd().add_jm().format(t.timestamp!)}'
                            '\nMonth: ${t.transactionMonth ?? '-'}',
                      ),
                      isThreeLine: true,
                      trailing: Text(
                        'PKR ${t.transactionAmount?.toStringAsFixed(0) ?? "0"}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
