import '../../../data/models/manager_model.dart';
import '../../../data/models/player_analysis_model.dart';
import '../../../data/models/tactical_insight_model.dart';
import '../../../data/models/activity_model.dart';

// ---------------------------------------------------------------------------
// Alert Model
// ---------------------------------------------------------------------------

enum AlertLevel { critical, warning, info }

class AdminAlertModel {
  final String id;
  final String title;
  final String description;
  final AlertLevel level;
  final DateTime timestamp;
  final bool isRead;

  const AdminAlertModel({
    required this.id,
    required this.title,
    required this.description,
    required this.level,
    required this.timestamp,
    required this.isRead,
  });
}

// ---------------------------------------------------------------------------
// Manager Performance Record
// ---------------------------------------------------------------------------

class ManagerPerformanceRecord {
  final String managerId;
  final List<double> weeklyRatings; // last 8 weeks
  final int uploadsThisWeek;
  final int uploadsThisMonth;
  final double avgAnalysisScore;
  final int reportsGenerated;
  final List<String> recentActions;

  const ManagerPerformanceRecord({
    required this.managerId,
    required this.weeklyRatings,
    required this.uploadsThisWeek,
    required this.uploadsThisMonth,
    required this.avgAnalysisScore,
    required this.reportsGenerated,
    required this.recentActions,
  });
}

// ---------------------------------------------------------------------------
// Club Performance Trend
// ---------------------------------------------------------------------------

class ClubPerformanceTrend {
  final String label; // e.g. "Week 1"
  final double possession;
  final double pressureIndex;
  final double xg;
  final double teamRating;

  const ClubPerformanceTrend({
    required this.label,
    required this.possession,
    required this.pressureIndex,
    required this.xg,
    required this.teamRating,
  });
}

// ---------------------------------------------------------------------------
// Admin Mock Data
// ---------------------------------------------------------------------------

class AdminMockData {
  // ── Managers ──────────────────────────────────────────────────────────────

  static final List<ManagerModel> managers = [
    ManagerModel(
      id: 'm1',
      name: 'Jurgen Klopp',
      email: 'jurgen@liverpool.com',
      imageUrl: 'https://i.pravatar.cc/150?u=jurgen',
      uploadCount: 142,
      lastActive: DateTime.now().subtract(const Duration(hours: 2)),
      isActive: true,
      matchesAnalyzed: 89,
      tacticalRating: 9.2,
    ),
    ManagerModel(
      id: 'm2',
      name: 'Pep Guardiola',
      email: 'pep@mancity.com',
      imageUrl: 'https://i.pravatar.cc/150?u=pep',
      uploadCount: 210,
      lastActive: DateTime.now().subtract(const Duration(minutes: 15)),
      isActive: true,
      matchesAnalyzed: 156,
      tacticalRating: 9.5,
    ),
    ManagerModel(
      id: 'm3',
      name: 'Mikel Arteta',
      email: 'mikel@arsenal.com',
      imageUrl: 'https://i.pravatar.cc/150?u=mikel',
      uploadCount: 87,
      lastActive: DateTime.now().subtract(const Duration(days: 1)),
      isActive: false,
      matchesAnalyzed: 45,
      tacticalRating: 8.7,
    ),
    ManagerModel(
      id: 'm4',
      name: 'Carlo Ancelotti',
      email: 'carlo@realmadrid.com',
      imageUrl: 'https://i.pravatar.cc/150?u=carlo',
      uploadCount: 98,
      lastActive: DateTime.now().subtract(const Duration(hours: 6)),
      isActive: true,
      matchesAnalyzed: 62,
      tacticalRating: 8.9,
    ),
    ManagerModel(
      id: 'm5',
      name: 'Thomas Tuchel',
      email: 'thomas@england.com',
      imageUrl: 'https://i.pravatar.cc/150?u=thomas',
      uploadCount: 54,
      lastActive: DateTime.now().subtract(const Duration(hours: 20)),
      isActive: true,
      matchesAnalyzed: 38,
      tacticalRating: 8.4,
    ),
    ManagerModel(
      id: 'm6',
      name: 'Xabi Alonso',
      email: 'xabi@bayer.com',
      imageUrl: 'https://i.pravatar.cc/150?u=xabi',
      uploadCount: 31,
      lastActive: DateTime.now().subtract(const Duration(days: 3)),
      isActive: false,
      matchesAnalyzed: 22,
      tacticalRating: 8.1,
    ),
  ];

  // ── Squad ─────────────────────────────────────────────────────────────────

  static final List<PlayerAnalysisModel> squad = [
    PlayerAnalysisModel(
      id: 'p1',
      name: 'Mo Salah',
      position: 'RW',
      imageUrl: 'https://i.pravatar.cc/150?u=salah',
      overallRating: 9.1,
      fatigueLevel: 65.0,
      injuryRisk: 15.0,
      workRate: 85.0,
      tacticalImpact: 92.0,
      keyStrengths: ['Pace', 'Finishing', 'Dribbling'],
      weaknesses: ['Defensive Contribution'],
      recentRatings: {'Match 1': 8.5, 'Match 2': 9.2, 'Match 3': 7.8, 'Match 4': 8.9, 'Match 5': 9.0},
    ),
    PlayerAnalysisModel(
      id: 'p2',
      name: 'Kevin De Bruyne',
      position: 'CM',
      imageUrl: 'https://i.pravatar.cc/150?u=kdb',
      overallRating: 9.3,
      fatigueLevel: 78.0,
      injuryRisk: 40.0,
      workRate: 80.0,
      tacticalImpact: 96.0,
      keyStrengths: ['Passing', 'Vision', 'Long Shots'],
      weaknesses: ['Pace'],
      recentRatings: {'Match 1': 9.0, 'Match 2': 8.8, 'Match 3': 9.5, 'Match 4': 7.2, 'Match 5': 9.1},
    ),
    PlayerAnalysisModel(
      id: 'p3',
      name: 'Virgil van Dijk',
      position: 'CB',
      imageUrl: 'https://i.pravatar.cc/150?u=vvd',
      overallRating: 8.9,
      fatigueLevel: 45.0,
      injuryRisk: 10.0,
      workRate: 75.0,
      tacticalImpact: 90.0,
      keyStrengths: ['Aerial Ability', 'Tackling', 'Leadership'],
      weaknesses: ['Acceleration'],
      recentRatings: {'Match 1': 8.0, 'Match 2': 8.5, 'Match 3': 8.2, 'Match 4': 9.0, 'Match 5': 8.7},
    ),
    PlayerAnalysisModel(
      id: 'p4',
      name: 'Bukayo Saka',
      position: 'RW',
      imageUrl: 'https://i.pravatar.cc/150?u=saka',
      overallRating: 8.7,
      fatigueLevel: 85.0,
      injuryRisk: 60.0,
      workRate: 95.0,
      tacticalImpact: 88.0,
      keyStrengths: ['Dribbling', 'Work Rate', 'Crossing'],
      weaknesses: ['Weak Foot'],
      recentRatings: {'Match 1': 8.2, 'Match 2': 7.5, 'Match 3': 8.9, 'Match 4': 6.8, 'Match 5': 7.9},
    ),
    PlayerAnalysisModel(
      id: 'p5',
      name: 'Phil Foden',
      position: 'CAM',
      imageUrl: 'https://i.pravatar.cc/150?u=foden',
      overallRating: 8.8,
      fatigueLevel: 55.0,
      injuryRisk: 20.0,
      workRate: 82.0,
      tacticalImpact: 91.0,
      keyStrengths: ['Creativity', 'Ball Control', 'Movement'],
      weaknesses: ['Aerial'],
      recentRatings: {'Match 1': 9.1, 'Match 2': 8.5, 'Match 3': 8.8, 'Match 4': 9.2, 'Match 5': 8.6},
    ),
    PlayerAnalysisModel(
      id: 'p6',
      name: 'Declan Rice',
      position: 'CDM',
      imageUrl: 'https://i.pravatar.cc/150?u=declan',
      overallRating: 8.5,
      fatigueLevel: 70.0,
      injuryRisk: 25.0,
      workRate: 92.0,
      tacticalImpact: 87.0,
      keyStrengths: ['Pressing', 'Interceptions', 'Stamina'],
      weaknesses: ['Long Range Shooting'],
      recentRatings: {'Match 1': 8.0, 'Match 2': 8.3, 'Match 3': 7.9, 'Match 4': 8.6, 'Match 5': 8.7},
    ),
    PlayerAnalysisModel(
      id: 'p7',
      name: 'Erling Haaland',
      position: 'ST',
      imageUrl: 'https://i.pravatar.cc/150?u=haaland',
      overallRating: 9.4,
      fatigueLevel: 90.0,
      injuryRisk: 72.0,
      workRate: 78.0,
      tacticalImpact: 94.0,
      keyStrengths: ['Finishing', 'Aerial', 'Pace'],
      weaknesses: ['Build-Up Play'],
      recentRatings: {'Match 1': 9.5, 'Match 2': 8.0, 'Match 3': 9.8, 'Match 4': 7.5, 'Match 5': 9.2},
    ),
    PlayerAnalysisModel(
      id: 'p8',
      name: 'Trent Alexander-Arnold',
      position: 'RB',
      imageUrl: 'https://i.pravatar.cc/150?u=trent',
      overallRating: 8.6,
      fatigueLevel: 62.0,
      injuryRisk: 30.0,
      workRate: 88.0,
      tacticalImpact: 89.0,
      keyStrengths: ['Crossing', 'Passing Range', 'Set Pieces'],
      weaknesses: ['Defensive Positioning'],
      recentRatings: {'Match 1': 8.4, 'Match 2': 8.7, 'Match 3': 9.0, 'Match 4': 8.1, 'Match 5': 8.8},
    ),
  ];

  // ── Tactical Insights ──────────────────────────────────────────────────────

  static final List<TacticalInsightModel> tacticalInsights = [
    TacticalInsightModel(
      id: 'ti1',
      title: 'Vulnerability on Counter-Attacks',
      description:
          'High defensive line leaves large spaces behind. 40% of conceded goals came from quick transitions.',
      category: 'Weakness',
      impactScore: 8.5,
      generatedAt: DateTime.now().subtract(const Duration(hours: 5)),
      relatedMatchId: 'm1',
    ),
    TacticalInsightModel(
      id: 'ti2',
      title: 'Strong Left Flank Overloads',
      description:
          'Excellent combinations between LB and LW creating numerous crossing opportunities.',
      category: 'Strength',
      impactScore: 7.8,
      generatedAt: DateTime.now().subtract(const Duration(days: 1)),
      relatedMatchId: 'm2',
    ),
    TacticalInsightModel(
      id: 'ti3',
      title: 'Exploit Space Between CBs',
      description:
          'Opponent\'s center backs struggle with runners from deep midfield.',
      category: 'Opportunity',
      impactScore: 9.0,
      generatedAt: DateTime.now().subtract(const Duration(hours: 12)),
      relatedMatchId: 'm3',
    ),
    TacticalInsightModel(
      id: 'ti4',
      title: 'High Press Efficiency Declining',
      description:
          'Press success rate dropped from 68% to 52% over last 3 matches. Workload impact likely.',
      category: 'Warning',
      impactScore: 7.2,
      generatedAt: DateTime.now().subtract(const Duration(hours: 8)),
      relatedMatchId: 'm4',
    ),
    TacticalInsightModel(
      id: 'ti5',
      title: 'Set-Piece Dominance Opportunity',
      description:
          'Club ranks 2nd in aerial duels won. Opponent has poor aerial defensive record on corners.',
      category: 'Opportunity',
      impactScore: 8.1,
      generatedAt: DateTime.now().subtract(const Duration(hours: 18)),
      relatedMatchId: 'm5',
    ),
  ];

  // ── Recent Activity ────────────────────────────────────────────────────────

  static final List<ActivityModel> recentActivity = [
    ActivityModel(
      id: 'a1',
      userId: 'm1',
      userName: 'Jurgen Klopp',
      userRole: 'Manager',
      action: 'Analyzed Match',
      description: 'Completed tactical analysis for Match vs Chelsea',
      timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
    ),
    ActivityModel(
      id: 'a2',
      userId: 'admin1',
      userName: 'System Admin',
      userRole: 'Admin',
      action: 'Updated Permissions',
      description: 'Granted upload rights to Assistant Manager',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    ActivityModel(
      id: 'a3',
      userId: 'm2',
      userName: 'Pep Guardiola',
      userRole: 'Manager',
      action: 'Downloaded Report',
      description: 'Downloaded weekly fitness report for squad review',
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    ActivityModel(
      id: 'a4',
      userId: 'm4',
      userName: 'Carlo Ancelotti',
      userRole: 'Manager',
      action: 'Uploaded Match',
      description: 'Uploaded Real Madrid vs Atletico match footage',
      timestamp: DateTime.now().subtract(const Duration(hours: 7)),
    ),
    ActivityModel(
      id: 'a5',
      userId: 'admin1',
      userName: 'System Admin',
      userRole: 'Admin',
      action: 'Added Manager',
      description: 'Onboarded Thomas Tuchel with standard permissions',
      timestamp: DateTime.now().subtract(const Duration(hours: 9)),
    ),
    ActivityModel(
      id: 'a6',
      userId: 'm1',
      userName: 'Jurgen Klopp',
      userRole: 'Manager',
      action: 'Reviewed Squad',
      description: 'Reviewed squad fatigue analysis before match day',
      timestamp: DateTime.now().subtract(const Duration(hours: 12)),
    ),
    ActivityModel(
      id: 'a7',
      userId: 'm5',
      userName: 'Thomas Tuchel',
      userRole: 'Manager',
      action: 'Generated Report',
      description: 'Generated pressing intensity report for coaching staff',
      timestamp: DateTime.now().subtract(const Duration(hours: 15)),
    ),
    ActivityModel(
      id: 'a8',
      userId: 'admin1',
      userName: 'System Admin',
      userRole: 'Admin',
      action: 'Suspended Account',
      description: 'Suspended Xabi Alonso account pending review',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  // ── Alerts ─────────────────────────────────────────────────────────────────

  static final List<AdminAlertModel> alerts = [
    AdminAlertModel(
      id: 'al1',
      title: 'High Fatigue Detected',
      description: 'Erling Haaland fatigue at 90% — rest recommended before next match.',
      level: AlertLevel.critical,
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      isRead: false,
    ),
    AdminAlertModel(
      id: 'al2',
      title: 'Analysis Upload Failed',
      description: 'Arteta\'s match vs Brentford upload failed. Video format unsupported.',
      level: AlertLevel.warning,
      timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      isRead: false,
    ),
    AdminAlertModel(
      id: 'al3',
      title: 'Injury Risk Threshold Exceeded',
      description: 'Bukayo Saka injury risk at 60% — exceeds 55% safety threshold.',
      level: AlertLevel.critical,
      timestamp: DateTime.now().subtract(const Duration(hours: 4)),
      isRead: true,
    ),
    AdminAlertModel(
      id: 'al4',
      title: 'New Manager Login',
      description: 'Thomas Tuchel logged in from new device. Activity flagged for review.',
      level: AlertLevel.info,
      timestamp: DateTime.now().subtract(const Duration(hours: 8)),
      isRead: true,
    ),
    AdminAlertModel(
      id: 'al5',
      title: 'Squad Condition Below Average',
      description: 'Overall squad fatigue at 68% — 14% above seasonal average.',
      level: AlertLevel.warning,
      timestamp: DateTime.now().subtract(const Duration(hours: 11)),
      isRead: true,
    ),
  ];

  // ── Manager Performance Records ────────────────────────────────────────────

  static final Map<String, ManagerPerformanceRecord> managerPerformance = {
    'm1': ManagerPerformanceRecord(
      managerId: 'm1',
      weeklyRatings: [8.1, 8.4, 9.0, 8.7, 9.2, 8.9, 9.1, 9.2],
      uploadsThisWeek: 4,
      uploadsThisMonth: 18,
      avgAnalysisScore: 9.2,
      reportsGenerated: 12,
      recentActions: [
        'Analyzed Liverpool vs Chelsea',
        'Reviewed pressing heatmap',
        'Updated formation to 4-3-3',
        'Generated fitness report',
      ],
    ),
    'm2': ManagerPerformanceRecord(
      managerId: 'm2',
      weeklyRatings: [9.0, 9.1, 9.3, 9.2, 9.5, 9.4, 9.5, 9.5],
      uploadsThisWeek: 6,
      uploadsThisMonth: 24,
      avgAnalysisScore: 9.5,
      reportsGenerated: 21,
      recentActions: [
        'Uploaded Man City vs Arsenal footage',
        'Reviewed positional data',
        'Generated pressing intensity report',
        'Analyzed opponent set pieces',
      ],
    ),
    'm3': ManagerPerformanceRecord(
      managerId: 'm3',
      weeklyRatings: [8.5, 8.6, 8.7, 8.4, 8.7, 8.5, 8.8, 8.7],
      uploadsThisWeek: 2,
      uploadsThisMonth: 9,
      avgAnalysisScore: 8.7,
      reportsGenerated: 7,
      recentActions: [
        'Uploaded Arsenal vs Liverpool',
        'Reviewed defensive shape',
      ],
    ),
    'm4': ManagerPerformanceRecord(
      managerId: 'm4',
      weeklyRatings: [8.3, 8.5, 8.9, 8.7, 9.0, 8.8, 8.9, 8.9],
      uploadsThisWeek: 3,
      uploadsThisMonth: 14,
      avgAnalysisScore: 8.9,
      reportsGenerated: 10,
      recentActions: [
        'Analyzed Real Madrid vs Atletico',
        'Generated set-piece report',
        'Reviewed fatigue metrics',
      ],
    ),
    'm5': ManagerPerformanceRecord(
      managerId: 'm5',
      weeklyRatings: [7.8, 8.0, 8.2, 8.1, 8.4, 8.3, 8.4, 8.4],
      uploadsThisWeek: 2,
      uploadsThisMonth: 8,
      avgAnalysisScore: 8.4,
      reportsGenerated: 5,
      recentActions: [
        'Uploaded England vs Germany',
        'Reviewed pressing report',
      ],
    ),
    'm6': ManagerPerformanceRecord(
      managerId: 'm6',
      weeklyRatings: [7.5, 7.8, 8.0, 7.9, 8.1, 8.0, 8.1, 8.1],
      uploadsThisWeek: 0,
      uploadsThisMonth: 4,
      avgAnalysisScore: 8.1,
      reportsGenerated: 3,
      recentActions: ['Uploaded Bayer vs Dortmund'],
    ),
  };

  // ── Club Performance Trends ────────────────────────────────────────────────

  static final List<ClubPerformanceTrend> performanceTrends = [
    ClubPerformanceTrend(label: 'W1', possession: 54, pressureIndex: 72, xg: 1.4, teamRating: 7.6),
    ClubPerformanceTrend(label: 'W2', possession: 58, pressureIndex: 75, xg: 1.8, teamRating: 7.9),
    ClubPerformanceTrend(label: 'W3', possession: 61, pressureIndex: 80, xg: 2.2, teamRating: 8.3),
    ClubPerformanceTrend(label: 'W4', possession: 59, pressureIndex: 78, xg: 1.9, teamRating: 8.0),
    ClubPerformanceTrend(label: 'W5', possession: 63, pressureIndex: 84, xg: 2.4, teamRating: 8.6),
    ClubPerformanceTrend(label: 'W6', possession: 62, pressureIndex: 82, xg: 2.1, teamRating: 8.4),
    ClubPerformanceTrend(label: 'W7', possession: 65, pressureIndex: 86, xg: 2.6, teamRating: 8.8),
    ClubPerformanceTrend(label: 'W8', possession: 66, pressureIndex: 88, xg: 2.8, teamRating: 9.0),
  ];
}
