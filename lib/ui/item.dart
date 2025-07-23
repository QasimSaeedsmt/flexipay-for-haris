import 'package:flexipay/services/customer_services.dart';
import 'package:flexipay/ui/forms/item_edit_form.dart';
import 'package:flutter/material.dart';

import '../data/models/customer_model.dart';
import 'forms/item_form.dart';

class ItemsDialog extends StatelessWidget {
  final CustomerModel customer;
  final String customerId;

  const ItemsDialog({super.key, required this.customer, required this.customerId});

  @override
  Widget build(BuildContext context) {
    final items = customer.items ?? [];

    return AlertDialog(
      title: Text("${customer.fullName}'s Items"),
      content: SizedBox(
        width: double.maxFinite,
        child: items.isEmpty
            ? const Text("No items yet.")
            : ListView.separated(
          shrinkWrap: true,
          itemCount: items.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (context, index) {
            final item = items[index];
            return ListTile(
              title: Text(item.itemName ?? "Unnamed"),
              subtitle:                  Text("Paid: \$${item.totalPaid?.toStringAsFixed(2) ?? "0"}"),

              trailing: PopupMenuButton(

                itemBuilder: (context) {
                return [

                  PopupMenuItem(

                    child: IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () {
                      Navigator.pop(context);
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          content: ItemEditForm(customerId: customerId, item: item, index: index)
                        ),
                      );
                    },
                  ),),
                 PopupMenuItem(child:                   IconButton(
                   icon: const Icon(Icons.delete, color: Colors.red),
                   onPressed: () => _confirmDelete(context, customerId, index),
                 ),
                 )
                 
                  
                  
                ];
              },),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                content: ItemForm(customerId: customerId),
              ),
            );
          },
          child: const Text("Add New Item"),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Close"),
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context, String customerId, int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Item"),
        content: const Text("Are you sure you want to delete this item?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close confirm dialog
              await CustomerService().deleteItemFromCustomer(customerId, index);
              Navigator.pop(context); // Close items dialog
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }
}
