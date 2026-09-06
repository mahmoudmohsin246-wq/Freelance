import '../../domain/entities/academy.dart';
import '../../domain/repositories/academy_repository.dart';
import '../datasources/mock_database.dart';

class MockAcademyRepository implements AcademyRepository {
  final MockDatabase _db = MockDatabase.instance;

  @override
  Future<List<AcademyEntity>> getAcademiesForUser(List<String> authorizedAcademyIds) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _db.academies
        .where((a) => authorizedAcademyIds.contains(a.id))
        .toList();
  }

  @override
  Future<AcademyEntity?> getAcademyById(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      return _db.academies.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<AcademyEntity> createAcademy(AcademyEntity academy) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _db.academies.add(academy);
    return academy;
  }

  @override
  Future<AcademyEntity> updateAcademy(AcademyEntity academy) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _db.academies.indexWhere((a) => a.id == academy.id);
    if (index != -1) {
      _db.academies[index] = academy;
    }
    return academy;
  }
}