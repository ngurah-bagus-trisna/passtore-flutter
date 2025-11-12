import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:pass_manager/data/password_repository.dart';
import 'package:pass_manager/models/password_entry.dart';

class PasswordListNotifier extends ChangeNotifier {
  PasswordListNotifier(this._repository);

  final PasswordRepository _repository;

  List<PasswordEntry> _items = <PasswordEntry>[];
  bool _isLoading = false;
  String _query = '';
  String? _errorMessage;
  Timer? _searchDebounce;

  List<PasswordEntry> get items => _items;
  bool get isLoading => _isLoading;
  String get query => _query;
  String? get errorMessage => _errorMessage;
  bool get hasResults => _items.isNotEmpty;

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _items = await _repository.fetchAll(query: _query);
    } catch (error) {
      _errorMessage = 'Failed to load passwords';
      if (kDebugMode) {
        // ignore: avoid_print
        print('PasswordListNotifier.load error: $error');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateQuery(String value) {
    _query = value;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      load();
    });
    notifyListeners();
  }

  Future<void> deleteEntry(int id) async {
    try {
      await _repository.delete(id);
      await load();
    } catch (error) {
      _errorMessage = 'Failed to delete entry';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }
}

