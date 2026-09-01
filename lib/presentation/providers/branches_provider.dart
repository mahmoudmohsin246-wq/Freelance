import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SimpleBranch {
  final String id;
  final String name;
  final String address;

  SimpleBranch({required this.id, required this.name, this.address = ''});

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'address': address,
      };

  factory SimpleBranch.fromJson(Map<String, dynamic> json) => SimpleBranch(
        id: json['id'],
        name: json['name'],
        address: json['address'] ?? '',
      );
}

class BranchesProvider extends ChangeNotifier {
  static const _storageKey = 'app_branches';

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
      final prefs = await SharedPreferences.getInstance();
      final encoded = prefs.getString(_storageKey);
      if (encoded != null) {
        final decoded = json.decode(encoded) as List<dynamic>;
        _branches = decoded.map((e) => SimpleBranch.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint('Error loading branches: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = json.encode(_branches.map((b) => b.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  Future<void> addBranch(String name, {String address = ''}) async {
    final branch = SimpleBranch(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      address: address,
    );
    _branches.insert(0, branch);
    notifyListeners();
    await _save();
  }

  Future<void> deleteBranch(String id) async {
    _branches.removeWhere((b) => b.id == id);
    notifyListeners();
    await _save();
  }
}
