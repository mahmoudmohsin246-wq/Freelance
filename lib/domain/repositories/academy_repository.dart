import '../entities/academy.dart';

abstract class AcademyRepository {
  Future<List<AcademyEntity>> getAcademiesForUser(List<String> authorizedAcademyIds);
  Future<AcademyEntity?> getAcademyById(String id);
  Future<AcademyEntity> createAcademy(AcademyEntity academy);
  Future<AcademyEntity> updateAcademy(AcademyEntity academy);
}