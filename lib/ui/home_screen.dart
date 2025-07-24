import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flexipay/services/customer_services.dart';
import 'package:flexipay/ui/customer_list_screen.dart';
import 'package:flexipay/ui/transaction_history_screen.dart';
import 'package:flexipay/data/models/transaction_model.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;         // 👈 This is the important line
import 'package:printing/printing.dart';
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final CustomerService _svc = CustomerService();
  Future<Map<String, String>> _buildCustomerNameMap() async {
    final customers = await _svc.getAllCustomers();
    return { for (var c in customers) c.id!: c.fullName??"" };
  }
  Map<String, String> _customerNameMap = {};


  double _totalBalance = 0.0;
  double _totalDue = 0.0;
  double _totalAdvance = 0.0;
  double _totalReceivedThisMonth = 0.0;
  List<TransactionModel> _recentTxns = [];
  List<Map<String, dynamic>> _monthlyData = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSummaries();
  }

  Future<void> _loadSummaries() async {
    setState(() => _loading = true);

    final nameMap = await _buildCustomerNameMap();
    final now = DateTime.now();
    final monthKey = DateFormat('yyyy-MM').format(now);

    final customers = await _svc.getAllCustomers();
    List<TransactionModel> allTxns = [];

    double bal = 0, due = 0, adv = 0, recv = 0;

    for (var c in customers) {
      final balanceData = await _svc.calculateBalanceAndDue(c.id!);
      final txns = await _svc.getTransactions(c.id!);
      final monthTxns = await _svc.getTransactionsForMonth(c.id!, monthKey);

      // Update summary values
      final balance = balanceData['balance'] ?? 0.0;
      final dueAmt = balanceData['dueAmount'] ?? 0.0;

      bal += balance;
      if (dueAmt > 0) {
        due += dueAmt;
      } else {
        adv += -dueAmt;
      }

      for (var t in monthTxns) {
        recv += t.transactionAmount ?? 0;
      }

      // Collect all transactions and assign customerId for later lookup
      for (var t in txns) {
        t.customerId = c.id;
        allTxns.add(t);
      }
    }

    allTxns.sort((a, b) => b.timestamp!.compareTo(a.timestamp!));

    setState(() {
      _customerNameMap = nameMap;
      _recentTxns = allTxns.take(10).toList();
      _totalBalance = bal;
      _totalDue = due;
      _totalAdvance = adv;
      _totalReceivedThisMonth = recv;
      _loading = false;
    });
  }

  Widget _infoBox(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 14, color: color)),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }


  Widget _buildRecentTxns() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Recent Transactions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        ..._recentTxns.map((t) => ListTile(
          leading: const Icon(Icons.attach_money, color: Colors.green),
          title: Text(_customerNameMap[t.customerId] ?? 'Unknown Customer'),
          subtitle: Text(DateFormat.yMMMd().add_jm().format(t.timestamp!)),
          trailing: Text("PKR ${t.transactionAmount?.toStringAsFixed(0) ?? '0'}"),
          onTap: () => _showTransactionDetails(t),
        )),
      ],
    );
  }
  void _showTransactionDetails(TransactionModel txn) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Transaction Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow('Customer', _customerNameMap[txn.customerId] ?? 'Unknown'),
            _detailRow('Type', txn.transactionType),
            _detailRow('Item', txn.itemName),
            _detailRow('Amount', 'PKR ${txn.transactionAmount?.toStringAsFixed(2) ?? "0.00"}'),
            _detailRow('Txn Month', txn.transactionMonth),
            _detailRow('Date', DateFormat.yMMMMd().add_jm().format(txn.timestamp!)),
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
              _generateSingleTransactionPdf(txn);
            },
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Export PDF'),
          ),
        ],
      ),
    );
  }
  Future<void> _generateSingleTransactionPdf(TransactionModel txn) async {
    final pdf = pw.Document();

    final customerName = _customerNameMap[txn.customerId] ?? 'Unknown';

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Container(
          padding: const pw.EdgeInsets.all(24),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Transaction Receipt',
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              pw.Text('Customer: $customerName', style: pw.TextStyle(fontSize: 16)),
              pw.Divider(),
              _pdfRow('Transaction Type', txn.transactionType),
              _pdfRow('Item Name', txn.itemName),
              _pdfRow('Transaction Month', txn.transactionMonth),
              _pdfRow('Amount', 'Rs ${txn.transactionAmount?.toStringAsFixed(0) ?? "0.00"}'),
              // _pdfRow('Entry Time', txn.entryTime),
              _pdfRow('Date & Time', DateFormat.yMMMMd().add_jm().format(txn.timestamp!)),
              pw.SizedBox(height: 24),
              pw.Text('Thank you for the trust!',
                  style: pw.TextStyle(fontStyle: pw.FontStyle.italic)),
            ],
          ),
        ),
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'transaction_${txn.transactionMonth}.pdf',
    );
  }

  pw.Widget _pdfRow(String label, String? value) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      margin: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            "$label: ",
            style: pw.TextStyle(
              fontSize: 11,
              color: PdfColors.grey800,
              fontWeight: pw.FontWeight.normal,
            ),
          ),
          pw.SizedBox(width: 6),
          pw.Expanded(
            child: pw.Text(
              value ?? '-',
              style: pw.TextStyle(
                fontSize: 11,
                color: PdfColors.blueGrey900,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value ?? "-", softWrap: true)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Home"),
        centerTitle: true,
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TransactionHistoryScreen()),
            ),
            icon: const Icon(Icons.history, color: Colors.black),
            label: const Text("History", style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadSummaries,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  _infoBox("Total Balance", "PKR ${_totalBalance.toStringAsFixed(0)}", Colors.blueAccent),
                  _infoBox("Total Due", "PKR ${_totalDue.toStringAsFixed(0)}", Colors.redAccent),
                ],
              ),
              Row(
                children: [
                  _infoBox("Total Advance", "PKR ${_totalAdvance.toStringAsFixed(0)}", Colors.green),
                  _infoBox("Received This Month", "PKR ${_totalReceivedThisMonth.toStringAsFixed(0)}", Colors.orange),
                ],
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CustomerListScreen()),
                    ).then((_) => _loadSummaries()),
                    icon: const Icon(Icons.group),
                    label: const Text("Customers"),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TransactionHistoryScreen()),
                    ),
                    icon: const Icon(Icons.receipt_long),
                    label: const Text("Transactions"),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const SizedBox(height: 24),
              _buildRecentTxns(),

            ],
          ),
        ),
      ),
    );
  }
}
