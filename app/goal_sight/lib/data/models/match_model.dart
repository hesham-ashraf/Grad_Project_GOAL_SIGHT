import 'package:flutter/material.dart';

class MatchPlayer {
  const MatchPlayer({
    required this.id,
    required this.name,
    required this.rating,
    required this.insight,
    this.isBest = false,
    this.isWorst = false,
  });

  final String id;
  final String name;
  final double rating;
  final String insight;
  final bool isBest;
  final bool isWorst;
}

class TacticalAnalysis {
  const TacticalAnalysis({
    required this.homePossession,
    required this.homeStyle,
    required this.homePressure,
    required this.awayPossession,
    required this.awayStyle,
    required this.awayPressure,
  });

  final int homePossession;
  final String homeStyle;
  final String homePressure;
  final int awayPossession;
  final String awayStyle;
  final String awayPressure;
}

class MatchModel {
  const MatchModel({
    required this.id,
    required this.homeTeam,
    required this.awayTeam,
    required this.status,
    required this.score,
    this.date = 'TBD',
    this.intensity = 0,
    this.homeColor = Colors.grey,
    this.awayColor = Colors.blueGrey,
    this.highlightText,
    this.isTopMatch = false,
    this.summary = '',
    this.dominantTeam = '',
    this.tactics,
    this.players = const [],
    this.recommendations = const [],
  });

  final String id;
  final String homeTeam;
  final String awayTeam;
  final String status;
  final String score;
  final String date;
  
  // UI Helpers (could be extracted but useful for mock mapping)
  final int intensity;
  final Color homeColor;
  final Color awayColor;
  final String? highlightText;
  final bool isTopMatch;

  // AI & Analysis Data
  final String summary;
  final String dominantTeam;
  final TacticalAnalysis? tactics;
  final List<MatchPlayer> players;
  final List<String> recommendations;

  // Placeholder fromJson to not break existing code
  factory MatchModel.fromJson(Map<String, dynamic> json) {
    final home = (json['homeTeam'] ?? 'Home').toString();
    final away = (json['awayTeam'] ?? 'Away').toString();
    final homeScore = (json['homeScore'] ?? 0).toString();
    final awayScore = (json['awayScore'] ?? 0).toString();

    return MatchModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      homeTeam: home,
      awayTeam: away,
      status: (json['status'] ?? 'scheduled').toString(),
      score: '$homeScore - $awayScore',
      date: 'TBD',
    );
  }
}
