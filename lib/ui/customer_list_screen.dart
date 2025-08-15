import 'package:flexipay/data/models/customer_model.dart';
import 'package:flexipay/msg_utils.dart';
import 'package:flexipay/services/customer_services.dart';
import 'package:flexipay/ui/send_msg_dialog.dart';
import 'package:flutter/material.dart';
import 'forms/adjustment_form.dart';
import 'forms/customer_form.dart';
import 'forms/transaction_form.dart';
import 'edit_customer_screen.dart';
import 'item.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({Key? key}) : super(key: key);

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  final _svc = CustomerService();
  final TextEditingController _searchController = TextEditingController();

  List<CustomerModel> _customers = [];
  List<CustomerModel> _filteredCustomers = [];

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    _searchController.addListener(() {
      _filterCustomers(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final list = await _svc.getAllCustomers();
    setState(() {
      _customers = list;
      _filteredCustomers = list;
      _loading = false;
    });
  }

  void _filterCustomers(String query) {
    final lowerQuery = query.toLowerCase();
    setState(() {
      _filteredCustomers =
          _customers.where((c) {
            return (c.fullName ?? '').toLowerCase().contains(lowerQuery) ||
                (c.fatherName ?? '').toLowerCase().contains(lowerQuery) ||
                (c.phoneNumber ?? '').toLowerCase().contains(lowerQuery) ||
                (c.fullAddress ?? '').toLowerCase().contains(lowerQuery);
          }).toList();
    });
  }

  double _calculateBalance(CustomerModel c) {
    return c.items?.fold(0.0, (sum, it) => sum! + (it.remainingAmount ?? 0)) ??
        0;
  }

  void _showDetails(CustomerModel customer) {
    final balance = _calculateBalance(customer);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (_) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              top: 16,
              left: 16,
              right: 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Text(
                  customer.fullName ?? '–',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 8),
                _detailRow('Father’s Name', customer.fatherName),
                _detailRow('Phone', customer.phoneNumber),
                _detailRow('Address', customer.fullAddress),
                _detailRow('Balance', 'PKR ${balance.toStringAsFixed(0)}'),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () {

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (
                                context,
                                ) => MessageItemsScreen(
                              customerId:
                              customer
                                  .id!,
                            ),
                          ),
                        );
                      },

                      child: Text("Send Message"),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.list),
                      label: const Text('View Items'),
                      onPressed: () {
                        Navigator.pop(context);
                        showDialog(
                          context: context,
                          builder:
                              (_) => ItemsDialog(
                                customer: customer,
                                customerId: customer.id!,
                              ),
                        );
                      },
                    ),
                  ],
                ),
                const Divider(),
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.payments_outlined),
                          label: const Text('Receive Installment'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                            textStyle: const TextStyle(fontSize: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => TransactionForm(
                                      customerId: customer.id!,
                                    ),
                              ),
                            );
                          },
                        ),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.edit_note_outlined),
                          label: const Text('Edit'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                            textStyle: const TextStyle(fontSize: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) =>
                                        EditCustomerScreen(customer: customer),
                              ),
                            );
                          },
                        ),
                      ],
                    ),

                    SizedBox(height: MediaQuery.of(context).size.height * 0.03),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.tune_outlined),
                          label: const Text('Adjustments'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                            textStyle: const TextStyle(fontSize: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => AdjustmentForm(
                                      customerId: customer.id!,
                                    ),
                              ),
                            );
                          },
                        ),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Delete'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                            textStyle: const TextStyle(fontSize: 16),
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            _deleteCustomer(customer);
                          },
                        ),
                      ],
                    ),

                    SizedBox(height: MediaQuery.of(context).size.height * 0.08),
                  ],
                ),
              ],
            ),
          ),
    );
  }

  Widget _detailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Expanded(
            child: Text(
              value ?? '–',
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w400),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCustomer(CustomerModel c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Delete Customer'),
            content: Text('Delete ${c.fullName}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
    if (ok == true) {
      await _svc.deleteCustomer(c);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isSmall = width < 360;

    return Scaffold(
      appBar: AppBar(title: const Text('Customer List')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search customers...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon:
                    _searchController.text.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _filterCustomers('');
                          },
                        )
                        : null,
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child:
                _loading
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _filteredCustomers.length,
                        itemBuilder: (ctx, i) {
                          final c = _filteredCustomers[i];
                          final bal = _calculateBalance(c);
                          return Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            margin: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              onTap: () => _showDetails(c),
                              title: Text(
                                c.fullName ?? 'Unnamed',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Text(
                                c.fullAddress ?? '-',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                              ),
                              trailing: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width * 0.45,
                                ), // adjust this width based on your layout

                                child: FutureBuilder<Map<String, double>>(
                                  future: CustomerService()
                                      .calculateBalanceAndDue(c.id!),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const SizedBox(
                                        width: 50,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      );
                                    } else if (snapshot.hasError) {
                                      return const Text('Error');
                                    } else {
                                      final data =
                                          snapshot.data ??
                                          {'balance': 0.0, 'dueAmount': 0.0};
                                      final balance = data['balance']!;
                                      final due = data['dueAmount']!;
                                      final roundedDue = double.parse(
                                        due.toStringAsFixed(2),
                                      );

                                      late final String dueLabel;
                                      late final Color dueColor;

                                      if (roundedDue > 0) {
                                        dueLabel = 'Due';
                                        dueColor = Colors.redAccent;
                                      } else if (roundedDue < 0) {
                                        dueLabel = 'Advance';
                                        dueColor = Colors.green;
                                      } else {
                                        dueLabel = 'Clear';
                                        dueColor = Colors.grey;
                                      }

                                      return LayoutBuilder(
                                        builder: (context, constraints) {
                                          return Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.end,
                                                children: [
                                                  Flexible(
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 4,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: dueColor
                                                            .withOpacity(0.1),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              6,
                                                            ),
                                                      ),
                                                      child: Text(
                                                        '$dueLabel: PKR ${roundedDue.abs().toStringAsFixed(0)}',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: dueColor,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Flexible(
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 4,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color:
                                                            Colors.blueGrey[50],
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              6,
                                                            ),
                                                      ),
                                                      child: Text(
                                                        'Balance: PKR ${balance.toStringAsFixed(0)}',
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          color: Colors.black87,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              PopupMenuButton(
                                                itemBuilder: (context) {
                                                  return [
                                                    PopupMenuItem(
                                                      onTap: () {
                                                        final customer =
                                                            _filteredCustomers[i];
                                                        // Navigator.pop(context);
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder:
                                                                (
                                                                  _,
                                                                ) => TransactionForm(
                                                                  customerId:
                                                                      customer
                                                                          .id!,
                                                                ),
                                                          ),
                                                        );
                                                      },
                                                      child: SizedBox(
                                                        width:
                                                            MediaQuery.of(
                                                              context,
                                                            ).size.width *
                                                            0.5,
                                                        child: Row(
                                                          children: [
                                                            Icon(
                                                              Icons.payments,
                                                            ),
                                                            SizedBox(width: 8),
                                                            Text(
                                                              "Receive Installment",
                                                            ),
                                                          ],
                                                        ),
                                                      ),

                                                      ///////////
                                                    ),
                                                    ////////////
                                                    PopupMenuItem(
                                                      onTap: () {
                                                        final customer =
                                                            _filteredCustomers[i];
                                                        // Navigator.pop(context);
                                                        showDialog(
                                                          context: context,
                                                          builder:
                                                              (
                                                                _,
                                                              ) => ItemsDialog(
                                                                customer:
                                                                    customer,
                                                                customerId:
                                                                    customer
                                                                        .id!,
                                                              ),
                                                        );
                                                      },

                                                      child: SizedBox(
                                                        width:
                                                            MediaQuery.of(
                                                              context,
                                                            ).size.width *
                                                            0.5,
                                                        child: Row(
                                                          children: [
                                                            Icon(
                                                              Icons
                                                                  .view_agenda_outlined,
                                                            ),
                                                            SizedBox(width: 8),
                                                            Text("View Items"),
                                                          ],
                                                        ),
                                                      ),

                                                      ///////////
                                                    ),
                                                    ////////////
                                                    PopupMenuItem(
                                                      onTap: () {
                                                        final customer =
                                                            _filteredCustomers[i];
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder:
                                                                (
                                                                  context,
                                                                ) => MessageItemsScreen(
                                                                  customerId:
                                                                      customer
                                                                          .id!,
                                                                ),
                                                          ),
                                                        );
                                                      },
                                                      child: SizedBox(
                                                        width:
                                                            MediaQuery.of(
                                                              context,
                                                            ).size.width *
                                                            0.5,
                                                        child: Row(
                                                          children: [
                                                            Icon(
                                                              Icons
                                                                  .message_outlined,
                                                            ),
                                                            SizedBox(width: 8),
                                                            Text(
                                                              "Send Reminder Message",
                                                            ),
                                                          ],
                                                        ),
                                                      ),

                                                      ///////////
                                                    ),
                                                    ////////////
                                                    PopupMenuItem(
                                                      onTap: () {
                                                        final customer =
                                                            _filteredCustomers[i];
                                                        // Navigator.pop(context);
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder:
                                                                (
                                                                  _,
                                                                ) => AdjustmentForm(
                                                                  customerId:
                                                                      customer
                                                                          .id!,
                                                                ),
                                                          ),
                                                        );
                                                      },

                                                      child: SizedBox(
                                                        width:
                                                            MediaQuery.of(
                                                              context,
                                                            ).size.width *
                                                            0.5,
                                                        child: Row(
                                                          children: [
                                                            Icon(Icons.adjust),
                                                            SizedBox(width: 8),
                                                            Text("Adjustments"),
                                                          ],
                                                        ),
                                                      ),

                                                      ///////////
                                                    ),
                                                    ////////////
                                                    PopupMenuItem(
                                                      onTap: () {
                                                        final customer =
                                                            _filteredCustomers[i];
                                                        // Navigator.pop(context);
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder:
                                                                (
                                                                  _,
                                                                ) => EditCustomerScreen(
                                                                  customer:
                                                                      customer,
                                                                ),
                                                          ),
                                                        );
                                                      },
                                                      child: SizedBox(
                                                        width:
                                                            MediaQuery.of(
                                                              context,
                                                            ).size.width *
                                                            0.5,
                                                        child: Row(
                                                          children: [
                                                            Icon(Icons.edit),
                                                            SizedBox(width: 8),
                                                            Text(
                                                              "Edit Customer",
                                                            ),
                                                          ],
                                                        ),
                                                      ),

                                                      ///////////
                                                    ),
                                                    ////////////
                                                    PopupMenuItem(
                                                      onTap: () {
                                                        final customer =
                                                            _filteredCustomers[i];
                                                        // Navigator.pop(context);
                                                        _deleteCustomer(
                                                          customer,
                                                        );
                                                      },
                                                      child: SizedBox(
                                                        width:
                                                            MediaQuery.of(
                                                              context,
                                                            ).size.width *
                                                            0.5,
                                                        child: Row(
                                                          children: [
                                                            Icon(
                                                              Icons
                                                                  .delete_forever,
                                                            ),
                                                            SizedBox(width: 8),
                                                            Text(
                                                              "Delete Customer",
                                                            ),
                                                          ],
                                                        ),
                                                      ),

                                                      ///////////
                                                    ),

                                                    ////////////
                                                  ];
                                                },
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    }
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CustomerForm()),
          ).then((_) => _load());
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
