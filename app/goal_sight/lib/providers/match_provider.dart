import 'package:flutter/foundation.dart';
import '../models/match.dart';
import '../database/database_helper.dart';
import '../services/api_service.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

class MatchProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final ApiService _apiService = ApiService();

  List<Match> _matches = [];
  bool _isLoading = false;
  String? _error;

  List<Match> get matches => _matches;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadMatches() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _matches = await _dbHelper.getAllMatches();
      _error = null;
    } catch (e) {
      _error = 'Failed to load matches: $e';
      _matches = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addMatch(Match match) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Generate analysis data if not provided
      Match matchWithStats = match;
      if (match.possessionA == null) {
        matchWithStats = _generateMatchStatistics(match);
      }
      await _dbHelper.insertMatch(matchWithStats);
      await loadMatches();
      return true;
    } catch (e) {
      _error = 'Failed to add match: $e';
      notifyListeners();
      return false;
    }
  }

  Match _generateMatchStatistics(Match match) {
    final random = DateTime.now().millisecondsSinceEpoch % 100;
    final possessionA = 40 + (random % 20); // 40-60%
    final possessionB = 100 - possessionA;
    
    return match.copyWith(
      possessionA: possessionA,
      possessionB: possessionB,
      shotsA: 8 + (random % 8), // 8-15
      shotsB: 8 + ((random * 3) % 8),
      shotsOnTargetA: 3 + (random % 5), // 3-7
      shotsOnTargetB: 3 + ((random * 2) % 5),
      passesA: 300 + (random % 200), // 300-500
      passesB: 300 + ((random * 5) % 200),
      passAccuracyA: 70 + (random % 20), // 70-90%
      passAccuracyB: 70 + ((random * 7) % 20),
      foulsA: 8 + (random % 7), // 8-14
      foulsB: 8 + ((random * 3) % 7),
      cornersA: 3 + (random % 5), // 3-7
      cornersB: 3 + ((random * 2) % 5),
    );
  }

  Future<bool> updateMatch(Match match) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _dbHelper.updateMatch(match);
      await loadMatches();
      return true;
    } catch (e) {
      _error = 'Failed to update match: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteMatch(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _dbHelper.deleteMatch(id);
      await loadMatches();
      return true;
    } catch (e) {
      _error = 'Failed to delete match: $e';
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, dynamic>?> fetchMatchDataFromAPI() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _apiService.fetchMatchData();
      _error = null;
      return data;
    } catch (e) {
      _error = 'Failed to fetch data from API: $e';
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

