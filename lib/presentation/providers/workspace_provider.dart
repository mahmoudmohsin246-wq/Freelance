import 'package:flutter/material.dart';
import '../../domain/entities/academy.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/academy_repository.dart';

class WorkspaceProvider extends ChangeNotifier {
  final AcademyRepository _academyRepo;

  List<AcademyEntity> _academies = [];
  AcademyEntity? _selectedAcademy;
  bool _isLoading = false;
  String? _error;

  WorkspaceProvider({required AcademyRepository academyRepo}) : _academyRepo = academyRepo;

  List<AcademyEntity> get academies => _academies;
  AcademyEntity? get selectedAcademy => _selectedAcademy;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadWorkspaces(UserEntity user) async {
    _isLoading = true;
    notifyListeners();

    try {
      _academies = await _academyRepo.getAcademiesForUser(user.authorizedAcademyIds);
      if (_academies.isNotEmpty) {
        _selectedAcademy ??= _academies.first;
      }
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void switchWorkspace(AcademyEntity academy) {
    _selectedAcademy = academy;
    notifyListeners();
  }

  Future<void> createAcademy({
    required String name,
    required String sport,
    required String logoUrl,
    required String phone,
    required String address,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final newAcademy = AcademyEntity(
        id: 'academy-${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        sport: sport,
        logoUrl: logoUrl.isNotEmpty
            ? logoUrl
            : 'https://images.unsplash.com/photo-1517649763962-0c623266010b?w=150',
        phone: phone,
        address: address,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final created = await _academyRepo.createAcademy(newAcademy);
      _academies.add(created);
      _selectedAcademy = created;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}