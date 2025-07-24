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
    String? notes,
  }) async {
    final now = DateTime.now();
    final transaction = TransactionModel(
      customerId: customerId, // ✅ Important: this links the transaction to the customer!
      transactionType: transactionType,
      transactionMonth: monthKey,
      itemName: itemName,
      transactionAmount: amount,
      entryTime: now.toString(),
      timestamp: now,
      note: notes
    );

    await _db
        .collection('customers')
        .doc(customerId)
        .collection('transactions')
        .add(transaction.toMap());
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
    final doc = await _customerRef.doc(customerId).get();
    if (!doc.exists) return;

    final data = doc.data() as Map<String, dynamic>;
    List<dynamic> currentItems = data['items'] ?? [];

    // Construct the item map with controlled values
    final double price = item.installmentTotalPrice ?? 0.0;

    final newItemMap = {
      ...item.toMap(),
      'totalPaid': 0.0,
      'installmentTotalPrice': price,
      'remaining': price, // Since totalPaid = 0.0
    };

    currentItems.add(newItemMap);

    // Calculate totalBalance from all items
    double newTotalBalance = 0.0;
    for (var i in currentItems) {
      newTotalBalance += (i['totalPaid'] ?? 0).toDouble();
    }

    await _customerRef.doc(customerId).update({
      'items': currentItems,
      'totalBalance': newTotalBalance,
    });
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
