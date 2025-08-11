import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../data/models/customer_model.dart';
import '../data/models/item_model.dart';
import '../data/models/transaction_model.dart';

class CustomerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference _customerRef = FirebaseFirestore.instance
      .collection('customers');
  Future<Map<String, double>> calculateBalanceAndDue(String customerId) async {
    final customerDoc = await _customerRef.doc(customerId).get();
    if (!customerDoc.exists) return {'balance': 0.0, 'dueAmount': 0.0};

    final data = customerDoc.data() as Map<String, dynamic>;
    final itemsData = data['items'] as List<dynamic>? ?? [];
    List<ItemModel> items = itemsData
        .map((map) => ItemModel.fromMap(map as Map<String, dynamic>))
        .toList();

    double totalBalance = 0.0;
    double totalDueAmount = 0.0;

    final now = DateTime.now();
    final allTxns = await getTransactions(customerId);

    // Build map: paymentsPerItemMonth[itemName][monthKey] = paidAmount
    final Map<String, Map<String, double>> paymentsPerItemMonth = {};
    for (var txn in allTxns) {
      final item = txn.itemName ?? '';
      final month = txn.transactionMonth ?? '';
      if (item.isEmpty || month.isEmpty) continue;
      paymentsPerItemMonth[item] ??= {};
      paymentsPerItemMonth[item]![month] =
          (paymentsPerItemMonth[item]![month] ?? 0.0) + (txn.transactionAmount ?? 0.0);
    }

    // Helper: months between start and now, inclusive of current month
    int monthsBetween(DateTime start, DateTime end) {
      return (end.year - start.year) * 12 + end.month - start.month + 1;
    }

    for (var item in items) {
      totalBalance += item.remainingAmount ?? 0.0;

      // Determine months elapsed since item was added
      final start = item.startDate ?? now;
      final monthsElapsed = monthsBetween(start, now);

      final installment = item.installmentPerMonth ?? 0.0;
      final totalDueTillNow = installment * monthsElapsed;

      final paid = paymentsPerItemMonth[item.itemName] != null
          ? paymentsPerItemMonth[item.itemName]!.values.fold(0.0, (a, b) => a + b)
          : 0.0;

      final netDue = totalDueTillNow - paid;
      totalDueAmount += netDue;
    }

    return {
      'balance': totalBalance,
      'dueAmount': totalDueAmount,
    };
  }


  // Add a new transaction
  Future<void> addTransaction({
    required String transactionType,
    required String customerId,
    required String itemName,
    required String monthKey,
    required double amount,
    required String? notes,
  }) async {
    final now = DateTime.now();
    final transaction = TransactionModel(
      customerId: customerId,
      transactionType: transactionType,
      transactionMonth: monthKey,
      itemName: itemName,
      transactionAmount: amount,
      entryTime: now.toString(),
      timestamp: now,
      note: notes,
    );

    // Add the transaction to Firestore
    await _db
        .collection('customers')
        .doc(customerId)
        .collection('transactions')
        .add(transaction.toMap());

    // Now update the item data with the new totalPaid and remainingAmount
    final customerDoc = await _customerRef.doc(customerId).get();
    if (!customerDoc.exists) {
      print("Customer document not found.");
      return;
    }

    final customerData = customerDoc.data() as Map<String, dynamic>;
    List<dynamic> currentItems = customerData['items'] ?? [];

    // Find the item related to this transaction
    final itemIndex = currentItems.indexWhere((item) => item['itemName'] == itemName);
    if (itemIndex == -1) {
      print("Item not found for this transaction: $itemName");
      return; // Item not found for this transaction
    }

    // Get the item data and calculate new values
    final item = currentItems[itemIndex];

    double totalPaid = item['totalPaid'] ?? 0.0;
    double remainingAmount = item['remainingAmount'] ?? 0.0;
    final double installmentTotalPrice = item['installmentTotalPrice'] ?? 0.0;
    final double installmentPerMonth = item['installmentPerMonth'] ?? 0.0;

    print("Before update:");
    print("Total Paid: $totalPaid");
    print("Remaining Amount: $remainingAmount");
    print("Transaction Type: $transactionType");
    print("Amount: $amount");

    // Update totalPaid and remainingAmount based on transaction type
    if (transactionType == 'payment') {
      totalPaid += amount; // Add the payment to the totalPaid
      print("Processing Payment: +$amount");
    } else if (transactionType == 'refund') {
      totalPaid -= amount; // Subtract from the totalPaid (if it's a refund)
      print("Processing Refund: -$amount");
    }

    // Ensure totalPaid doesn't go below 0
    if (totalPaid < 0) totalPaid = 0.0;

    // Debugging: Print the updated value of totalPaid
    print("Updated Total Paid: $totalPaid");

    // Recalculate remainingAmount
    remainingAmount = installmentTotalPrice - totalPaid;

    // Update the remaining months (rounded up)
    int remainingMonths = (remainingAmount / installmentPerMonth).ceil();
    if (remainingAmount <= 0) remainingMonths = 0; // No months left if remainingAmount is 0 or less

    print("After update:");
    print("Updated Remaining Amount: $remainingAmount");
    print("Updated Remaining Months: $remainingMonths");

    // Update the item data
    currentItems[itemIndex] = {
      ...item,
      'totalPaid': totalPaid,
      'remainingAmount': remainingAmount,
      'remainingMonths': remainingMonths,
    };

    // Recalculate totalBalance for the customer
    double newTotalBalance = 0.0;
    for (var i in currentItems) {
      newTotalBalance += (i['totalPaid'] ?? 0).toDouble();
    }

    // Update the customer data with new values
    await _customerRef.doc(customerId).update({
      'items': currentItems,
      'totalBalance': newTotalBalance,
    });

    print("Customer data updated successfully.");
    print("New Total Balance: $newTotalBalance");
  }


  Future<List<TransactionModel>> getTransactionsForMonth(String customerId, String monthKey) async {
    // Fetch all transactions for the customer
    final allTransactions = await getTransactions(customerId);

    // Filter transactions where transactionMonth matches monthKey (e.g. "2025-07")
    final filtered = allTransactions.where((txn) => txn.transactionMonth == monthKey).toList();

    return filtered;
  }

  // Get used months for a customer
  Future<List<String>> getUsedMonths(String customerId) async {
    final snapshot = await _db
        .collection('customers')
        .doc(customerId)
        .collection('transactions')
        .get();

    return snapshot.docs
        .map((doc) => (doc.data()['transactionMonth'] as String?) ?? '')
        .where((month) => month.isNotEmpty)
        .toList();
  }
  final _db = FirebaseFirestore.instance;

  // Fetch all transactions for a customer
  Future<List<TransactionModel>> getTransactions(String customerId) async {
    final snapshot = await _db
        .collection('customers')
        .doc(customerId)
        .collection('transactions')
        .orderBy('timestamp', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => TransactionModel.fromMap(doc.data()))
        .toList();
  }  // 1. Add New Customer
  Future<void> addCustomer(CustomerModel customer) async {
    await _customerRef.add(customer.toMap());
  }

  // 2. Get All Customers
  Future<List<CustomerModel>> getAllCustomers() async {
    final snapshot = await _customerRef.get();
    return snapshot.docs.map((doc) {
      final customer = CustomerModel.fromMap(
        doc.data() as Map<String, dynamic>,
      );
      customer.id = doc.id; // <-- This assigns Firestore doc ID
      return customer;
    }).toList();
  }
  Future<void> updateCustomerItemAndBalance(
      String customerId, ItemModel updatedItem, double newBalance) async {
    final docRef = _customerRef.doc(customerId);
    final doc = await docRef.get();

    if (!doc.exists) return;

    final data = doc.data() as Map<String, dynamic>;
    List<dynamic> currentItems = data['items'] ?? [];

    // Replace the matching item with updated one
    final updatedItems = currentItems.map((item) {
      if (item['itemName'] == updatedItem.itemName) {
        return updatedItem.toMap();
      }
      return item;
    }).toList();

    await docRef.update({
      'items': updatedItems,
      'totalBalance': newBalance,
    });
  }

  // 3. Get Customer by ID
  Future<CustomerModel?> getCustomerById(String id) async {
    final doc = await _customerRef.doc(id).get();
    if (doc.exists) {
      return CustomerModel.fromMap(doc.data() as Map<String, dynamic>);
    }
    return null;
  }
  /// Fetches all recorded months (as "YYYY-MM") for a given customer

  // 4. Add Item to Customer
  Future<void> addItemToCustomer(String customerId, ItemModel item) async {
    // Fetch customer document from Firestore
    final doc = await _customerRef.doc(customerId).get();
    if (!doc.exists) {
      print("Error: Customer document does not exist for customerId: $customerId");
      return;
    }

    // Get the data of the customer
    final data = doc.data() as Map<String, dynamic>;
    List<dynamic> currentItems = data['items'] ?? [];

    // Debug: Print the current items before adding the new one
    print("Current items before adding new item: ${currentItems}");

    // Calculate the price for the item
    final double price = item.installmentTotalPrice ?? 0.0;

    // Debug: Print the price being used for the new item
    print("Price being used for new item: $price");

    // Create the new item map with the initial values
    final newItemMap = {
      ...item.toMap(),
      'totalPaid': 0.0, // Initially, no payment has been made
      'installmentTotalPrice': price, // Set total price for installments
      'remainingAmount': price, // Set remaining amount same as the price initially
    };
    print("Installment Total Price to save: ${newItemMap['installmentTotalPrice']}");

    // Debug: Print the new item map that will be added
    print("New item map to be added: $newItemMap");

    // Add the new item to the current items list
    currentItems.add(newItemMap);

    // Debug: Print the items after adding the new one
    print("Current items after adding new item: $currentItems");

    // Calculate totalBalance from all items
    double newTotalBalance = 0.0;
    for (var item in currentItems) {
      newTotalBalance += (item['totalPaid'] ?? 0).toDouble();
    }

    // Debug: Print the new total balance
    print("New total balance after adding item: $newTotalBalance");
    print("this is total price: $price");


    // Update the customer document with the new items and total balance
    try {
      await _customerRef.doc(customerId).update({
        'items': currentItems,
        'totalBalance': newTotalBalance,
      });
      print("Customer document updated successfully for customerId: $customerId");
    } catch (e) {
      print("Error updating customer document: $e");
    }

    // Trigger the UI update by notifying listeners or updating the state.
    // If you're using a provider or setState, ensure it triggers a refresh.
  }
  Future<void> createInitialTransactionIfNoneExists(String customerId) async {
    final transactionsRef = FirebaseFirestore.instance
        .collection('customers')
        .doc(customerId)
        .collection('transactions');

    final snapshot = await transactionsRef.limit(1).get();

    if (snapshot.docs.isEmpty) {
      // No transactions yet, create an initial dummy transaction
      await transactionsRef.add({
        'itemName': 'Initial Entry',
        'monthKey': DateFormat('yyyy-MM').format(DateTime.now()),
        'amount': 0.0,
        'notes': 'Initial dummy transaction to enable subcollection access',
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  // 5. Update Customer
  // Future<void> updateCustomer(String customerId, CustomerModel customer) async {
  //   await _customerRef.doc(customerId).update(customer.toMap());
  // }

  // 6. Delete Customer
  Future<void> deleteCustomer(CustomerModel customer) async {

    if (customer.id == null) {
      throw Exception("Customer ID is null. Cannot delete.");
    }
    print("deleting");
    await _customerRef.doc(customer.id).delete();

    print("deleted");
    await getAllCustomers(); // <-- Refreshes the list
    print("Fetched customers again: ");


  }


  Future<void> deleteItemFromCustomer(
      String customerId,
      int index,
      ) async {
    final doc = await _customerRef.doc(customerId).get();
    if (!doc.exists) return;

    final data = doc.data() as Map<String, dynamic>;
    List<dynamic> currentItems = data['items'] ?? [];

    if (index >= 0 && index < currentItems.length) {
      currentItems.removeAt(index);
      await _customerRef.doc(customerId).update({'items': currentItems});
    }
  }

  Future<void> updateItemForCustomer(
      String customerId,
      int index,
      ItemModel updatedItem,
      ) async {
    final doc = await _customerRef.doc(customerId).get();
    if (!doc.exists) return;

    final data = doc.data() as Map<String, dynamic>;
    List<dynamic> currentItems = data['items'] ?? [];

    if (index >= 0 && index < currentItems.length) {
      currentItems[index] = updatedItem.toMap();
      await _customerRef.doc(customerId).update({'items': currentItems});
    }
  }
  Future<void> updateCustomer(String customerId, CustomerModel updatedCustomer) async {
    await _customerRef.doc(customerId).update(updatedCustomer.toMap());
  }


  Future<List<CustomerModel>> searchCustomersByPhone(String phone) async {
    final snapshot =
        await _customerRef.where('phoneNumber', isEqualTo: phone).get();

    return snapshot.docs
        .map((doc) => CustomerModel.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  Future<List<CustomerModel>> getCustomersWithOutstandingBalance() async {
    final snapshot =
        await _customerRef.where('totalBalance', isGreaterThan: 0).get();

    return snapshot.docs
        .map((doc) => CustomerModel.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  Stream<List<CustomerModel>> listenToCustomers() {
    return _customerRef.snapshots().map((snapshot) {
      return snapshot.docs
          .map(
            (doc) => CustomerModel.fromMap(doc.data() as Map<String, dynamic>),
          )
          .toList();
    });
  }
}
