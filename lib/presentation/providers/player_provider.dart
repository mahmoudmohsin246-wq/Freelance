import 'package:flutter/material.dart';
import '../../domain/entities/player.dart';
import '../../domain/repositories/player_repository.dart';

class PlayerProvider extends ChangeNotifier {
  final PlayerRepository _playerRepo;

  List<PlayerEntity> _players = [];
  String _searchQuery = '';
  bool _isLoading = false;
  String? _error;

  PlayerProvider({required PlayerRepository playerRepo}) : _playerRepo = playerRepo;

  List<PlayerEntity> get players {
    if (_searchQuery.isEmpty) return _players;
    return _players.where((p) {
      final nameMatches = p.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final phoneMatches = p.phone.contains(_searchQuery);
      final sportMatches = p.sport.toLowerCase().contains(_searchQuery.toLowerCase());
      return nameMatches || phoneMatches || sportMatches;
    }).toList();
  }

  int get playerCount => _players.length;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> fetchPlayers(String academyId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _players = await _playerRepo.getPlayersForAcademy(academyId);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addPlayer({
    required String academyId,
    required String branchId,
    required String name,
    required int age,
    required String phone,
    required String sport,
    required String notes,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final newPlayer = PlayerEntity(
        id: 'player-${DateTime.now().millisecondsSinceEpoch}',
        academyId: academyId,
        branchId: branchId,
        name: name,
        age: age,
        phone: phone,
        sport: sport,
        status: 'Active',
        joinedDate: DateTime.now(),
        notes: notes,
      );

      final added = await _playerRepo.addPlayer(newPlayer);
      _players.add(added);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deletePlayer(String id) async {
    try {
      await _playerRepo.deletePlayer(id);
      _players.removeWhere((p) => p.id == id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}