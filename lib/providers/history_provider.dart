import 'package:flutter/material.dart';
import '../data/models/question_package_model.dart';
import '../data/datasources/local_db.dart';

class HistoryProvider extends ChangeNotifier {
  final LocalDatabase _localDb;

  List<QuestionPackageModel> _packages = [];
  bool _isLoading = false;
  String _searchQuery = '';

  HistoryProvider({LocalDatabase? localDb})
      : _localDb = localDb ?? LocalDatabase.instance {
    loadPackages();
  }

  List<QuestionPackageModel> get packages => _packages;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;

  Future<void> loadPackages() async {
    _isLoading = true;
    notifyListeners();

    if (_searchQuery.trim().isEmpty) {
      _packages = await _localDb.getAllPackages();
    } else {
      _packages = await _localDb.searchPackages(_searchQuery.trim());
    }

    _isLoading = false;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    loadPackages();
  }

  Future<bool> deletePackage(String id) async {
    final count = await _localDb.deletePackage(id);
    if (count > 0) {
      _packages.removeWhere((p) => p.id == id);
      notifyListeners();
      return true;
    }
    return false;
  }
}
