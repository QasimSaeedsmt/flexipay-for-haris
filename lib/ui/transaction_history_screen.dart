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
      footer: (context) => pw.Container(
        alignment: pw.Alignment.centerRight,
        margin: const pw.EdgeInsets.only(top: 20),
        child: pw.Text(
          'Page ${context.pageNumber} of ${context.pagesCount}',
          style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
        ),
      ),
      build: (context) => [
        pw.Header(
          level: 0,
          child: pw.Text(
            single != null ? 'Transaction Detail' : 'Transaction Report',
            style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          'Generated on: ${DateFormat.yMMMMd().add_jm().format(DateTime.now())}',
          style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
        ),
        if (_selectedCustomer != null && single == null) ...[
          pw.SizedBox(height: 10),
          pw.Text(
            'Customer: ${_selectedCustomer!.fullName}',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
        ],
        if (_filterMonth != null && single == null)
          pw.Text('Month: ${DateFormat.yMMMM().format(_filterMonth!)}',
              style: pw.TextStyle(fontSize: 12)),
        if (_filterRange != null && single == null)
          pw.Text(
            'Date Range: ${DateFormat.yMMMd().format(_filterRange!.start)} - ${DateFormat.yMMMd().format(_filterRange!.end)}',
            style: pw.TextStyle(fontSize: 12),
          ),
        pw.SizedBox(height: 20),

        if (single != null)
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _pdfDetailRow('Customer Name', _selectedCustomer?.fullName ?? "Unknown"),
              _pdfDetailRow('Transaction Type', single.transactionType),
              _pdfDetailRow('Item', single.itemName),
              _pdfDetailRow('Amount', 'PKR ${single.transactionAmount?.toStringAsFixed(0) ?? "0.00"}'),
              _pdfDetailRow('Date', DateFormat.yMMMMd().add_jm().format(single.timestamp!)),
              if (single.transactionMonth != null)
                _pdfDetailRow('Transaction Month', single.transactionMonth),
              if (single.note != null)
                _pdfDetailRow('Note', single.note),
              if (single.entryTime != null)
                _pdfDetailRow('Entry Time', single.entryTime),
            ],
          )
        else
          pw.Table.fromTextArray(
            border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey400),
            headerDecoration: pw.BoxDecoration(color: PdfColors.blue300),
            headerHeight: 25,
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.center,
              3: pw.Alignment.center,
              4: pw.Alignment.centerLeft,
              5: pw.Alignment.centerLeft,
              6: pw.Alignment.centerRight,
            },
            headers: [
              'Customer',
              'Transaction Type',
              'Item',
              'Month',
              'Date',
              'Note',
              'Amount (PKR)',
            ],
            data: txns.map((t) {
              final customerName = _customers.firstWhere(
                    (c) => c.id == t.customerId,
                orElse: () => CustomerModel(fullName: 'Unknown'),
              ).fullName;

              return [
                customerName ?? 'Unknown',
                t.transactionType ?? '-',
                t.itemName ?? '-',
                t.transactionMonth ?? '-',
                t.timestamp != null
                    ? DateFormat('MMM d, yyyy\nh:mm a').format(t.timestamp!)
                    : '-',
                (t.note != null && t.note!.isNotEmpty)
                    ? (t.note!.length > 30 ? '${t.note!.substring(0, 30)}...' : t.note!)
                    : '-',
                pw.Text(
                  t.transactionAmount?.toStringAsFixed(0) ?? '0.00',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: (t.transactionAmount ?? 0) < 0
                        ? PdfColors.red
                        : PdfColors.green,
                  ),
                ),
              ];
            }).toList(),
          ),

        pw.SizedBox(height: 20),

        if (single == null)
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Text(
                'Total Transactions: ${txns.length}',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(width: 20),
              pw.Text(
                'Total Amount: PKR ${txns.fold(0.0, (sum, t) => sum + (t.transactionAmount ?? 0)).toStringAsFixed(2)}',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ],
          ),
      ],
    ));

    final filename = single != null ? 'transaction_detail.pdf' : 'transaction_report.pdf';
    await Printing.sharePdf(bytes: await pdf.save(), filename: filename);
  }

  pw.Widget _pdfDetailRow(String label, String? value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text("$label: ",
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(width: 8),
          pw.Expanded(
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
            _detailRow('Type:', "Installment"),
            _detailRow('Item:', txn.itemName),
            _detailRow('Amount:', 'Rs ${txn.transactionAmount?.toStringAsFixed(0) ?? "0.00"}'),
            _detailRow('Date:', DateFormat.yMMMMd().add_jm().format(txn.timestamp!)),
            if (txn.transactionMonth != null)
              _detailRow('Txn Month', txn.transactionMonth),
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
      footer: (context) => pw.Container(
        alignment: pw.Alignment.centerRight,
        margin: const pw.EdgeInsets.only(top: 20),
        child: pw.Text(
          'Page ${context.pageNumber} of ${context.pagesCount}',
          style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
        ),
      ),
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
        pw.Table.fromTextArray(
          border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey400),
          headerDecoration: pw.BoxDecoration(color: PdfColors.blue300),
          headerHeight: 25,
          // Removed cellHeight so it flows naturally
          cellAlignments: {
            0: pw.Alignment.centerLeft,
            1: pw.Alignment.centerLeft,
            2: pw.Alignment.center,
            3: pw.Alignment.centerRight,
            4: pw.Alignment.center,
          },
          headers: [
            'Transaction Type',
            'Item Name',
            'Installment Month',
            'Transaction Time',
            "Note",
            'Amount (PKR)',
          ],
          data: customerTxns.map((t) => [
            t.transactionType,
            t.itemName ?? '-',
            t.transactionMonth ?? '-',
            t.timestamp != null
                ? DateFormat('MMM d, yyyy \n h:mm a').format(t.timestamp!)
                : '-',
            (t.note != null && t.note!.isNotEmpty)
                ? (t.note!.length > 30 ? '${t.note!.substring(0, 30)}...' : t.note!)
                : '-',
            pw.Text(
              t.transactionAmount?.toStringAsFixed(0) ?? '0.00',
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: (t.transactionAmount ?? 0) < 0
                    ? PdfColors.red
                    : PdfColors.green,
              ),
            ),
          ]).toList(),
        )
        ,
        pw.SizedBox(height: 20),
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
