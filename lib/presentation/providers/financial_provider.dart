import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Transaction {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final bool isIncome;
  final String category;

  Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.isIncome,
    required this.category,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'amount': amount,
        'date': date.toIso8601String(),
        'isIncome': isIncome,
        'category': category,
      };

  Map<String, dynamic> toFirestore() => {
        'title': title,
        'amount': amount,
        'date': Timestamp.fromDate(date),
        'isIncome': isIncome,
        'category': category,
        'createdAt': FieldValue.serverTimestamp(),
      };

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
        id: json['id'],
        title: json['title'],
        amount: (json['amount'] as num).toDouble(),
        date: DateTime.parse(json['date']),
        isIncome: json['isIncome'],
        category: json['category'],
      );

  factory Transaction.fromFirestore(Map<String, dynamic> json, String id) {
    final rawDate = json['date'];
    final date = rawDate is Timestamp ? rawDate.toDate() : DateTime.now();
    return Transaction(
      id: id,
      title: json['title'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      date: date,
      isIncome: json['isIncome'] as bool? ?? false,
      category: json['category'] as String? ?? '',
    );
  }
}

class FinancialProvider extends ChangeNotifier {
  static const String _collection = 'transactions';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Transaction> _transactions = [];
  bool _isLoading = false;

  List<Transaction> get transactions => _transactions;
  bool get isLoading => _isLoading;

  FinancialProvider() {
    loadFinancialData();
  }

  double get totalIncome {
    return _transactions
        .where((t) => t.isIncome)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double get totalExpenses {
    return _transactions
        .where((t) => !t.isIncome)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double get netBalance => totalIncome - totalExpenses;

  Future<void> addTransaction({
    required String title,
    required double amount,
    required bool isIncome,
    required String category,
  }) async {
    final docRef = _firestore.collection(_collection).doc();
    final newTransaction = Transaction(
      id: docRef.id,
      title: title,
      amount: amount,
      date: DateTime.now(),
      isIncome: isIncome,
      category: category,
    );

    try {
      await docRef.set(newTransaction.toFirestore());
      _transactions.insert(0, newTransaction);
      notifyListeners();
      await _saveToStorage();
    } catch (e) {
      debugPrint('Error adding transaction to Firestore: $e');
    }
  }

  Future<void> deleteTransaction(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
    } catch (e) {
      debugPrint('Error deleting transaction from Firestore: $e');
    }
    _transactions.removeWhere((t) => t.id == id);
    notifyListeners();
    await _saveToStorage();
  }

  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData = json.encode(
      _transactions.map((t) => t.toJson()).toList(),
    );
    await prefs.setString('financial_transactions', encodedData);
  }




  Future<void> loadFinancialData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final snap = await _firestore.collection(_collection).get();
      final list = snap.docs.map((doc) => Transaction.fromFirestore(doc.data(), doc.id)).toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      _transactions = list;
    } catch (e) {
      debugPrint('Error loading financial data from Firestore: $e');


      try {
        final prefs = await SharedPreferences.getInstance();
        final String? encodedData = prefs.getString('financial_transactions');
        if (encodedData != null) {
          final List<dynamic> decodedData = json.decode(encodedData);
          _transactions = decodedData.map((item) => Transaction.fromJson(item)).toList();
        }
      } catch (_) {}
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}