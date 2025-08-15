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

  final Map<String, bool> _messageViaWhatsApp = {};
  final Map<String, bool> _messageSent = {};

  MessageLanguage _selectedLanguage = MessageLanguage.english;

  @override
  void initState() {
    super.initState();
    _loadCustomerAndLogs();
  }

  Future<void> _loadCustomerAndLogs() async {
    final customer = await CustomerService().getCustomerById(widget.customerId);
    final nowMonth = DateFormat('yyyy-MM').format(DateTime.now());

    for (var item in customer?.items ?? []) {
      final hasSent = await MessageLogService.hasMessageBeenSent(
        customerId: widget.customerId,
        itemName: item.itemName!,
        month: nowMonth,
      );

      _messageViaWhatsApp[item.itemName!] = true;
      _messageSent[item.itemName!] = hasSent;
    }

    setState(() {
      _customer = customer;
      _loading = false;
    });
  }

  Future<void> _sendMessage(ItemModel item, bool viaWhatsApp) async {
    final method = viaWhatsApp ? 'WhatsApp' : 'SMS';
    final customerName = _customer!.fullName ?? '';
    final month = DateFormat('yyyy-MM').format(DateTime.now());
    final amount = item.installmentPerMonth ?? 0.0;
    final phone = _customer!.phoneNumber ?? '';
    final itemName = item.itemName ?? 'Unnamed Item';

    if (viaWhatsApp) {
      await MessageUtils.sendWhatsAppMessage(
        itemName: itemName,
        phoneNumber: phone,
        installmentMonth: month,
        installmentAmount: amount,
        customerName: customerName,
        language: _selectedLanguage,
      );
    } else {
      await MessageUtils.sendSMS(
        itemName: itemName,
        phoneNumber: phone,
        installmentMonth: month,
        installmentAmount: amount,
        customerName: customerName,
        language: _selectedLanguage,
      );
    }

    await MessageLogService.logMessage(MessageLogModel(
      customerId: widget.customerId,
      itemName: item.itemName!,
      method: method,
      month: month,
      sentAt: DateTime.now(),
    ));

    setState(() {
      _messageSent[item.itemName!] = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$method message sent for "${item.itemName}"')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final items = _customer?.items ?? [];

    final filteredItems = items.where((item) {
      final remaining = item.remainingAmount ?? 0.0;
      return remaining > 0;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Send Payment Messages')),
      body: filteredItems.isEmpty
          ? const Center(child: Text("All dues are cleared 🎉"))
          : Column(
          children: [
      Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Select Message Language:",
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          DropdownButton<MessageLanguage>(
            value: _selectedLanguage,
            borderRadius: BorderRadius.circular(12),
            onChanged: (MessageLanguage? newLang) {
              if (newLang != null) {
                setState(() {
                  _selectedLanguage = newLang;
                });
              }
            },
            items: [
              DropdownMenuItem(
                value: MessageLanguage.english,
                child: Text('English'),
              ),
              DropdownMenuItem(
                value: MessageLanguage.romanUrdu,
                child: Text('Roman Urdu'),
              ),
              DropdownMenuItem(
                value: MessageLanguage.urdu,
                child: Text('Urdu'),
              ),
            ],
          ),
        ],
      ),
    ),
    const Divider(),
    Expanded(
    child: ListView.separated(
    padding: const EdgeInsets.all(16),
    itemCount: filteredItems.length,
    separatorBuilder: (_, __) => const SizedBox(height: 12),
    itemBuilder: (context, index) {
    final item = filteredItems[index];
    final isWhatsApp = _messageViaWhatsApp[item.itemName!] ?? true;
    final isSent = _messageSent[item.itemName!] ?? false;

    final remaining = item.remainingAmount ?? 0.0;
    final monthly = item.installmentPerMonth ?? 0.0;

    return Card(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    elevation: 5,
    color: isSent ? Colors.green.shade50 : Colors.white,
    child: Padding(
    padding: const EdgeInsets.all(20),
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Flexible(
        child: Text(
          item.itemName ?? 'Unnamed Item',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      Chip(
        backgroundColor: Colors.blue.shade50,
        label: Text(
          'Due: Rs ${remaining.toStringAsFixed(0)}',
          style: const TextStyle(color: Colors.black87),
        ),
      ),
    ],
    ),

      const SizedBox(height: 12),

      Text('Monthly Installment: Rs ${monthly.toStringAsFixed(0)}'),

      const SizedBox(height: 16),

      // Toggle WhatsApp/SMS
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                isWhatsApp ? FontAwesomeIcons.whatsapp : Icons.sms,
                color: isWhatsApp ? Colors.green : Colors.blue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(isWhatsApp ? 'WhatsApp' : 'SMS'),
            ],
          ),
          Switch(
            value: isWhatsApp,
            onChanged: (val) {
              setState(() {
                _messageViaWhatsApp[item.itemName!] = val;
              });
            },
          ),
        ],
      ),

      const SizedBox(height: 12),

      Align(
        alignment: Alignment.centerRight,
        child: ElevatedButton.icon(
          icon: Icon(isSent ? Icons.refresh : Icons.send),
          onPressed: () => _sendMessage(item, isWhatsApp),
          label: Text(isSent ? 'Resend Message' : 'Send Message'),
          style: ElevatedButton.styleFrom(
            backgroundColor:
            isSent ? Colors.orangeAccent : Colors.blueAccent,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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

