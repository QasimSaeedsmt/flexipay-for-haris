import 'package:flutter/material.dart';

import '../data/models/customer_model.dart';
import '../data/models/item_model.dart';
import '../services/customer_services.dart';
import 'forms/item_edit_form.dart';
import 'forms/item_form.dart';
import 'item_info_dialog.dart';

class ItemsDialog extends StatefulWidget {
  final CustomerModel customer;
  final String customerId;

  const ItemsDialog({
    super.key,
    required this.customer,
    required this.customerId,
  });

  @override
  State<ItemsDialog> createState() => _ItemsDialogState();
}

class _ItemsDialogState extends State<ItemsDialog> {
  late List<ItemModel> items;

  @override
  void initState() {
    super.initState();
    items = widget.customer.items ?? [];

  }

  void _addItem(ItemModel newItem) {
    setState(() {
      items.add(newItem);
    });
  }

  void _updateItem(ItemModel updatedItem, int index) {
    setState(() {
      items[index] = updatedItem;
    });
  }

  void _deleteItem(int index) {
    setState(() {
      items.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("${widget.customer.fullName}'s Items"),
      content: SizedBox(
        width: double.maxFinite,
        child: items.isEmpty
            ? const Text("No items yet.")
            : ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final item = items[index];

            return Card(
              margin:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                title: TextButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) =>
                          ItemInfoDialog(item: item),
                    );
                  },
                  child: Text(
                    item.itemName ?? "Unnamed Item",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.itemDescription != null &&
                        item.itemDescription!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          item.itemDescription!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    const SizedBox(height: 6),
                    Text(
                      "Remaining: PKR ${item.remainingAmount?.toStringAsFixed(0) ?? '0'}",
                      style: TextStyle(
                        fontSize: 13,
                        color: item.remainingAmount != null &&
                            item.remainingAmount! > 0
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'edit') {
                      final updatedItem = await showDialog<ItemModel>(
                        context: context,
                        builder: (_) => AlertDialog(
                          content: ItemEditForm(
                            customerId: widget.customerId,
                            item: item,
                            index: index,
                          ),
                        ),
                      );

                      if (updatedItem != null) {
                        _updateItem(updatedItem, index);
                      }
                    } else if (value == 'delete') {
                      _confirmDelete(context, widget.customerId, index);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, color: Colors.blue, size: 20),
                          SizedBox(width: 8),
                          Text("Edit"),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red, size: 20),
                          SizedBox(width: 8),
                          Text("Delete"),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
        onPressed: () async {
      final newItem = await showModalBottomSheet<ItemModel>(
        context: context,
        isScrollControlled: true, // allows full-height bottom sheet
        builder: (_) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: ItemForm(customerId: widget.customerId),
        ),
      );
      if (newItem != null) {
        _addItem(newItem);
      }
    }
,          child: const Text("Add New Item"),
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
              await CustomerService().deleteItemFromCustomer(
                customerId,
                index,
              );
              _deleteItem(index);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }
}
