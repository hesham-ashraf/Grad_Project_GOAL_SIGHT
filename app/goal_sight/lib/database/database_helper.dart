import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/match.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (kIsWeb) {
      throw UnsupportedError('SQLite is not supported on web. Use SharedPreferences instead.');
    }
    if (_database != null) return _database!;
    _database = await _initDB('matches.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    if (kIsWeb) {
      throw UnsupportedError('SQLite is not supported on web.');
    }
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE matches (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        teamA TEXT NOT NULL,
        teamB TEXT NOT NULL,
        scoreA INTEGER NOT NULL,
        scoreB INTEGER NOT NULL,
        matchDate TEXT NOT NULL,
        notes TEXT,
        possessionA INTEGER,
        possessionB INTEGER,
        shotsA INTEGER,
        shotsB INTEGER,
        shotsOnTargetA INTEGER,
        shotsOnTargetB INTEGER,
        passesA INTEGER,
        passesB INTEGER,
        passAccuracyA INTEGER,
        passAccuracyB INTEGER,
        foulsA INTEGER,
        foulsB INTEGER,
        cornersA INTEGER,
        cornersB INTEGER
      )
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add new analysis columns if they don't exist
      try {
        await db.execute('ALTER TABLE matches ADD COLUMN possessionA INTEGER');
        await db.execute('ALTER TABLE matches ADD COLUMN possessionB INTEGER');
        await db.execute('ALTER TABLE matches ADD COLUMN shotsA INTEGER');
        await db.execute('ALTER TABLE matches ADD COLUMN shotsB INTEGER');
        await db.execute('ALTER TABLE matches ADD COLUMN shotsOnTargetA INTEGER');
        await db.execute('ALTER TABLE matches ADD COLUMN shotsOnTargetB INTEGER');
        await db.execute('ALTER TABLE matches ADD COLUMN passesA INTEGER');
        await db.execute('ALTER TABLE matches ADD COLUMN passesB INTEGER');
        await db.execute('ALTER TABLE matches ADD COLUMN passAccuracyA INTEGER');
        await db.execute('ALTER TABLE matches ADD COLUMN passAccuracyB INTEGER');
        await db.execute('ALTER TABLE matches ADD COLUMN foulsA INTEGER');
        await db.execute('ALTER TABLE matches ADD COLUMN foulsB INTEGER');
        await db.execute('ALTER TABLE matches ADD COLUMN cornersA INTEGER');
        await db.execute('ALTER TABLE matches ADD COLUMN cornersB INTEGER');
      } catch (e) {
        // Columns might already exist, ignore error
      }
    }
  }

  Future<int> insertMatch(Match match) async {
    if (kIsWeb) {
      return await _insertMatchWeb(match);
    }
    final db = await database;
    return await db.insert('matches', match.toMap());
  }

  Future<List<Match>> getAllMatches() async {
    if (kIsWeb) {
      return await _getAllMatchesWeb();
    }
    final db = await database;
    final result = await db.query(
      'matches',
      orderBy: 'matchDate DESC',
    );
    return result.map((map) => Match.fromMap(map)).toList();
  }

  Future<Match?> getMatch(int id) async {
    if (kIsWeb) {
      return await _getMatchWeb(id);
    }
    final db = await database;
    final result = await db.query(
      'matches',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isNotEmpty) {
      return Match.fromMap(result.first);
    }
    return null;
  }

  Future<int> updateMatch(Match match) async {
    if (kIsWeb) {
      return await _updateMatchWeb(match);
    }
    final db = await database;
    return await db.update(
      'matches',
      match.toMap(),
      where: 'id = ?',
      whereArgs: [match.id],
    );
  }

  Future<int> deleteMatch(int id) async {
    if (kIsWeb) {
      return await _deleteMatchWeb(id);
    }
    final db = await database;
    return await db.delete(
      'matches',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Web implementation using SharedPreferences
  Future<int> _insertMatchWeb(Match match) async {
    final matches = await _getAllMatchesWeb();
    final newId = matches.isEmpty ? 1 : (matches.map((m) => m.id ?? 0).reduce((a, b) => a > b ? a : b) + 1);
    final matchWithId = match.copyWith(id: newId);
    matches.add(matchWithId);
    await _saveMatchesWeb(matches);
    return newId;
  }

  Future<List<Match>> _getAllMatchesWeb() async {
    final prefs = await SharedPreferences.getInstance();
    final matchesJson = prefs.getString('matches');
    if (matchesJson == null) return [];
    final List<dynamic> decoded = json.decode(matchesJson);
    return decoded.map((map) => Match.fromMap(Map<String, dynamic>.from(map))).toList()
      ..sort((a, b) => b.matchDate.compareTo(a.matchDate));
  }

  Future<Match?> _getMatchWeb(int id) async {
    final matches = await _getAllMatchesWeb();
    try {
      return matches.firstWhere((m) => m.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<int> _updateMatchWeb(Match match) async {
    final matches = await _getAllMatchesWeb();
    final index = matches.indexWhere((m) => m.id == match.id);
    if (index != -1) {
      matches[index] = match;
      await _saveMatchesWeb(matches);
      return 1;
    }
    return 0;
  }

  Future<int> _deleteMatchWeb(int id) async {
    final matches = await _getAllMatchesWeb();
    matches.removeWhere((m) => m.id == id);
    await _saveMatchesWeb(matches);
    return 1;
  }

  Future<void> _saveMatchesWeb(List<Match> matches) async {
    final prefs = await SharedPreferences.getInstance();
    final matchesJson = json.encode(matches.map((m) => m.toMap()).toList());
    await prefs.setString('matches', matchesJson);
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}

