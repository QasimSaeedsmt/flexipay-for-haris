import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../data/models/customer_model.dart';
import '../data/models/item_model.dart';
import '../data/models/message_model.dart';
import '../services/customer_services.dart';
import '../services/message_log_service.dart';
import '../msg_utils.dart';

class MessageItemsScreen extends StatefulWidget {
  final String customerId;
  const MessageItemsScreen({super.key, required this.customerId});

  @override
  State<MessageItemsScreen> createState() => _MessageItemsScreenState();
}

class _MessageItemsScreenState extends State<MessageItemsScreen> {
  CustomerModel? _customer;
  bool _loading = true;

  final Map<String, bool> _messageSent = {};
  final Map<String, bool> _messageViaWhatsApp = {};
  final List<_MessageCardData> _messageCards = [];

  MessageLanguage _selectedLanguage = MessageLanguage.english;

  @override
  void initState() {
    super.initState();
    _loadCustomerAndLogs();
  }

  Future<void> _loadCustomerAndLogs() async {
    final customer = await CustomerService().getCustomerById(widget.customerId);
    _customer = customer;

    List<_MessageCardData> tempCards = [];
    Map<String, bool> tempSent = {};
    Map<String, bool> tempVia = {};

    for (var item in customer?.items ?? []) {
      final installments = await _generateUnpaidInstallments(item);

      for (var inst in installments) {
        final messageId = '${item.itemName}_${inst.month}';
        final hasSent = await MessageLogService.hasMessageBeenSent(
          customerId: widget.customerId,
          itemName: item.itemName ?? 'Unnamed Item',
          month: inst.month,
        );

        tempCards.add(_MessageCardData(
          itemName: item.itemName ?? 'Unnamed Item',
          month: inst.month,
          amount: inst.amount,
        ));
        tempSent[messageId] = hasSent;
        tempVia[messageId] = true;
      }
    }

    setState(() {
      _messageCards.clear();
      _messageCards.addAll(tempCards);
      _messageSent
        ..clear()
        ..addAll(tempSent);
      _messageViaWhatsApp
        ..clear()
        ..addAll(tempVia);
      _loading = false;
    });
  }

  Future<List<_Installment>> _generateUnpaidInstallments(ItemModel item) async {
    final start = item.startingMonth ?? item.startDate;
    final end = item.endingMonth;
    final perMonth = item.installmentPerMonth ?? 0.0;

    if (start == null || end == null || perMonth <= 0) return [];

    final totalMonths =
        (end.year - start.year) * 12 + (end.month - start.month) + 1;
    final current = DateTime.now();
    final currentMonth = DateTime(current.year, current.month);

    List<_Installment> installments = [];

    for (int i = 0; i < totalMonths; i++) {
      final monthDate = DateTime(start.year, start.month + i);
      if (monthDate.isAfter(currentMonth)) break;

      final monthKey = DateFormat('yyyy-MM').format(monthDate);

      final transactions = await CustomerService()
          .getTransactionsForMonth(widget.customerId, monthKey);

      double paidForThisMonth = transactions
          .where((txn) => txn.itemName == item.itemName)
          .fold(0.0, (sum, txn) => sum + (txn.transactionAmount ?? 0.0));

      double remaining = (perMonth - paidForThisMonth).clamp(0.0, perMonth);

      if (remaining > 0) {
        installments.add(_Installment(month: monthKey, amount: remaining));
      }
    }

    return installments;
  }

  Future<void> _sendMessage(_MessageCardData card, bool viaWhatsApp) async {
    final method = viaWhatsApp ? 'WhatsApp' : 'SMS';
    final customerName = _customer?.fullName ?? '';
    final phone = _customer?.phoneNumber ?? '';
    final messageId = '${card.itemName}_${card.month}';

    if (viaWhatsApp) {
      await MessageUtils.sendWhatsAppMessage(
        phoneNumber: phone,
        dueMonth: card.month,
        amount: card.amount,
        customerName: customerName,
        itemName: card.itemName,
        language: _selectedLanguage,
      );
    } else {
      await MessageUtils.sendSMS(
        phoneNumber: phone,
        dueMonth: card.month,
        amount: card.amount,
        customerName: customerName,
        itemName: card.itemName,
        language: _selectedLanguage,
      );
    }

    await MessageLogService.logMessage(MessageLogModel(
      customerId: widget.customerId,
      itemName: card.itemName,
      method: method,
      month: card.month,
      sentAt: DateTime.now(),
    ));

    setState(() {
      _messageSent[messageId] = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
        Text('$method message sent for "${card.itemName}" (${card.month})'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Send Payment Messages')),
      body: _messageCards.isEmpty
          ? const Center(child: Text("All dues are cleared  "))
          : Column(
        children: [
          Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Select Message Language:",
                  style: TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 16),
                ),
                DropdownButton<MessageLanguage>(
                  value: _selectedLanguage,
                  borderRadius: BorderRadius.circular(12),
                  onChanged: (newLang) {
                    if (newLang != null) {
                      setState(() => _selectedLanguage = newLang);
                    }
                  },
                  items: const [
                    DropdownMenuItem(
                        value: MessageLanguage.english,
                        child: Text('English')),
                    DropdownMenuItem(
                        value: MessageLanguage.romanUrdu,
                        child: Text('Roman Urdu')),
                    DropdownMenuItem(
                        value: MessageLanguage.urdu,
                        child: Text('Urdu')),
                  ],
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _messageCards.length,
              separatorBuilder: (_, __) =>
              const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final card = _messageCards[index];
                final messageId = '${card.itemName}_${card.month}';
                final isWhatsApp = _messageViaWhatsApp[messageId] ?? true;
                final isSent = _messageSent[messageId] ?? false;

                return Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 5,
                  color: isSent
                      ? Colors.green.shade50
                      : Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                '${card.itemName} (${card.month})',
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight:
                                    FontWeight.w600),
                              ),
                            ),
                            Chip(
                              backgroundColor:
                              Colors.blue.shade50,
                              label: Text(
                                'Due: Rs ${card.amount.toStringAsFixed(0)}',
                                style: const TextStyle(
                                    color: Colors.black87),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  isWhatsApp
                                      ? FontAwesomeIcons.whatsapp
                                      : Icons.sms,
                                  color: isWhatsApp
                                      ? Colors.green
                                      : Colors.blue,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(isWhatsApp
                                    ? 'WhatsApp'
                                    : 'SMS'),
                              ],
                            ),
                            Switch(
                              value: isWhatsApp,
                              onChanged: (val) {
                                setState(() {
                                  _messageViaWhatsApp[messageId] =
                                      val;
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            icon: Icon(isSent
                                ? Icons.refresh
                                : Icons.send),
                            onPressed: () =>
                                _sendMessage(
                                    card, isWhatsApp),
                            label: Text(isSent
                                ? 'Resend Message'
                                : 'Send Message'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isSent
                                  ? Colors.orangeAccent
                                  : Colors.blueAccent,
                              padding:
                              const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageCardData {
  final String itemName;
  final String month;
  final double amount;

  _MessageCardData({
    required this.itemName,
    required this.month,
    required this.amount,
  });
}

class _Installment {
  final String month;
  final double amount;

  _Installment({required this.month, required this.amount});
}
