import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SimpleBranch {
  final String id;
  final String name;
  final String address;

  SimpleBranch({required this.id, required this.name, this.address = ''});

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'address': address,
        'createdAt': FieldValue.serverTimestamp(),
      };

  factory SimpleBranch.fromFirestore(Map<String, dynamic> json, String id) => SimpleBranch(
        id: id,
        name: json['name'] as String? ?? '',
        address: json['address'] as String? ?? '',
      );
}

/// Branches are shared academy data (added by the manager, seen by every
/// employee/player), so this is backed by Firestore, not per-device storage.
class BranchesProvider extends ChangeNotifier {
  static const _collection = 'branches';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<SimpleBranch> _branches = [];
  bool _isLoading = false;

  List<SimpleBranch> get branches => _branches;
  bool get isLoading => _isLoading;

  BranchesProvider() {
    loadBranches();
  }

  Future<void> loadBranches() async {
    _isLoading = true;
    notifyListeners();

    try {
      final snap = await _firestore.collection(_collection).get();
      _branches = snap.docs.map((d) => SimpleBranch.fromFirestore(d.data(), d.id)).toList();
    } catch (e) {
      debugPrint('Error loading branches: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addBranch(String name, {String address = ''}) async {
    try {
      final docRef = _firestore.collection(_collection).doc();
      await docRef.set({
        'name': name,
        'address': address,
        'createdAt': FieldValue.serverTimestamp(),
      });
      _branches.insert(0, SimpleBranch(id: docRef.id, name: name, address: address));
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding branch: $e');
    }
  }

  Future<void> deleteBranch(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
    } catch (e) {
      debugPrint('Error deleting branch: $e');
    }
    _branches.removeWhere((b) => b.id == id);
    notifyListeners();
  }
}
