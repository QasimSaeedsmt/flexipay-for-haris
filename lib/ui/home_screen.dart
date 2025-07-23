import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flexipay/services/customer_services.dart';
import 'package:flexipay/ui/customer_list_screen.dart';
import 'package:flexipay/ui/transaction_history_screen.dart';
import 'package:flexipay/data/models/transaction_model.dart';
import 'package:fl_chart/fl_chart.dart';

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

    for (var c in customers) {
      final txns = await _svc.getTransactions(c.id!);
      for (var t in txns) {
        t.customerId = c.id;
        allTxns.add(t);
      }
    }

    allTxns.sort((a, b) => b.timestamp!.compareTo(a.timestamp!));

    setState(() {
      _customerNameMap = nameMap;
      _recentTxns = allTxns.take(10).toList();
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

  Widget _buildBarChart() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blueGrey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: BarChart(
        BarChartData(
          barGroups: _monthlyData.asMap().entries.map((e) {
            final i = e.key;
            final m = e.value;
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(toY: (m['amount'] as double) / 1000, color: Colors.indigo, width: 16),
              ],
            );
          }).toList(),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, interval: 5, reservedSize: 40),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, _) {
                  final idx = value.toInt();
                  if (idx >= 0 && idx < _monthlyData.length) {
                    return Text(_monthlyData[idx]['month']);
                  }
                  return const Text('');
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(show: false),
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
        )),
      ],
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
              _buildBarChart(),
              const SizedBox(height: 24),
              _buildRecentTxns(),

            ],
          ),
        ),
      ),
    );
  }
}
