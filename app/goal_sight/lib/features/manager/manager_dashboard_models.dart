import 'package:flutter/material.dart';

class ManagerDashboardData {
  const ManagerDashboardData({
    required this.clubName,
    required this.subtitle,
    required this.keyStats,
    required this.lastMatch,
    required this.topPerformers,
    required this.insights,
  });

  final String clubName;
  final String subtitle;
  final List<ManagerKeyStat> keyStats;
  final ManagerLastMatch lastMatch;
  final List<ManagerPlayerPerformance> topPerformers;
  final List<ManagerInsight> insights;
}

class ManagerKeyStat {
  const ManagerKeyStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.tint,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color tint;
}

class ManagerLastMatch {
  const ManagerLastMatch({
    required this.homeTeam,
    required this.awayTeam,
    required this.homeScore,
    required this.awayScore,
    required this.aiSummary,
    required this.dominantTeam,
  });

  final String homeTeam;
  final String awayTeam;
  final int homeScore;
  final int awayScore;
  final String aiSummary;
  final String dominantTeam;
}

class ManagerPlayerPerformance {
  const ManagerPlayerPerformance({
    required this.name,
    required this.rating,
  });

  final String name;
  final double rating;
}

enum ManagerInsightSeverity { low, medium, high }

class ManagerInsight {
  const ManagerInsight({
    required this.title,
    required this.message,
    required this.severity,
  });

  final String title;
  final String message;
  final ManagerInsightSeverity severity;
}
