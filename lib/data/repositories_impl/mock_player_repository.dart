import '../../domain/entities/player.dart';
import '../../domain/repositories/player_repository.dart';
import '../datasources/mock_database.dart';

class MockPlayerRepository implements PlayerRepository {
  final MockDatabase _db = MockDatabase.instance;

  @override
  Future<List<PlayerEntity>> getPlayersForAcademy(String academyId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _db.players.where((p) => p.academyId == academyId).toList();
  }

  @override
  Future<PlayerEntity> addPlayer(PlayerEntity player) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _db.players.add(player);
    return player;
  }

  @override
  Future<PlayerEntity> updatePlayer(PlayerEntity player) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _db.players.indexWhere((p) => p.id == player.id);
    if (index != -1) {
      _db.players[index] = player;
    }
    return player;
  }

  @override
  Future<void> deletePlayer(String id) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _db.players.removeWhere((p) => p.id == id);
  }
}