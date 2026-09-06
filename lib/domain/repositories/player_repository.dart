import '../entities/player.dart';

abstract class PlayerRepository {
  Future<List<PlayerEntity>> getPlayersForAcademy(String academyId);
  Future<PlayerEntity> addPlayer(PlayerEntity player);
  Future<PlayerEntity> updatePlayer(PlayerEntity player);
  Future<void> deletePlayer(String id);
}