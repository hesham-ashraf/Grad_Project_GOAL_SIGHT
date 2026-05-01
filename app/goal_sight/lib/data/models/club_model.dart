import 'package:flutter/material.dart';

class ClubPlayer {
  const ClubPlayer({
    required this.id,
    required this.name,
    required this.position,
    required this.rating,
    this.nationality = '',
    this.age = 0,
    this.appearances = 0,
    this.goals = 0,
    this.assists = 0,
  });

  final String id;
  final String name;
  final String position;
  final double rating;
  final String nationality;
  final int age;
  final int appearances;
  final int goals;
  final int assists;
}

class ClubStats {
  const ClubStats({
    required this.matchesPlayed,
    required this.wins,
    required this.draws,
    required this.losses,
    required this.goalsScored,
    required this.goalsConceded,
    required this.ranking,
    required this.points,
  });

  final int matchesPlayed;
  final int wins;
  final int draws;
  final int losses;
  final int goalsScored;
  final int goalsConceded;
  final int ranking;
  final int points;

  int get goalDifference => goalsScored - goalsConceded;
}

class ClubModel {
  const ClubModel({
    required this.id,
    required this.name,
    required this.stadium,
    required this.league,
    required this.primaryColor,
    required this.players,
    required this.stats,
    this.foundedYear = 0,
    this.country = '',
    this.isFavorite = false,
    this.coach = '',
  });

  final String id;
  final String name;
  final String stadium;
  final String league;
  final Color primaryColor;
  final List<ClubPlayer> players;
  final ClubStats stats;
  final int foundedYear;
  final String country;
  final bool isFavorite;
  final String coach;

  // Abbreviation for the logo placeholder
  String get abbreviation =>
      name.split(' ').map((e) => e[0]).take(2).join('').toUpperCase();
}
