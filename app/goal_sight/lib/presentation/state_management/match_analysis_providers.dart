/// ---------------------------------------------------------------------------
/// GoalSight — AI Match Analysis Mock Data
///
/// Each [MatchAnalysisModel] here replicates the exact JSON shape the AI
/// backend returns. When Supabase is live, replace this provider with a real
/// [AsyncNotifierProvider] that fetches from the API — the UI stays unchanged.
/// ---------------------------------------------------------------------------

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/match_analysis_model.dart';

/// Provides the full list of analysed matches (list screen data).
final mockAnalysisMatchesProvider = Provider<List<MatchAnalysisModel>>((ref) {
  return _mockMatches;
});

/// Provides a single [MatchAnalysisModel] by ID (detail screen data).
final mockMatchAnalysisProvider =
    Provider.family<MatchAnalysisModel?, String>((ref, matchId) {
  try {
    return _mockMatches.firstWhere((m) => m.matchId == matchId);
  } catch (_) {
    return null;
  }
});

// ─── Mock Data ───────────────────────────────────────────────────────────────

const _mockMatches = [
  // ── Match 1: GoalSight FC vs Falcons United ──────────────────────────────
  MatchAnalysisModel(
    matchId: 'match_001',
    homeTeam: 'GoalSight FC',
    awayTeam: 'Falcons United',
    score: '3 - 1',
    date: 'May 2, 2026 · 20:00',
    status: 'FT',
    intensity: 91,
    highlightText: 'High intensity match',
    recommendations: [
      'Continue exploiting Falcons United\'s weak left-back who lost 1v1 duels 7 times.',
      'Rest Hassan Ali for at least 20 minutes in the next fixture — fatigue index critical at 87.',
      'Set-piece preparation: Falcons conceded 3 of their last 5 goals from corners.',
      'Introduce Tariq Ziad as a late substitute only — his positional discipline breaks down under fatigue.',
    ],
    summary: MatchSummaryModel(
      dominantTeam: 'GoalSight FC',
      homeAvgRating: 7.82,
      awayAvgRating: 6.14,
      motmPlayerId: 'p1',
      worstPlayerId: 'p6',
      keyMoments: [
        '12\' — Hassan Ali assist → Mostafa Samir opens scoring.',
        '38\' — Tariq Ziad loses ball, Falcons equalize from counter.',
        '67\' — Hassan Ali solo run, 2–1.',
        '88\' — Penalty won and converted, 3–1.',
      ],
      overallNarrative:
          'GoalSight FC delivered a commanding performance built on high-press intensity and rapid transitions. '
          'Their midfield trio dominated the central zones, completing 487 of 521 passes (93%). Falcons United '
          'showed brief flashes in the first half but were unable to sustain any meaningful possession '
          'sequences against GoalSight\'s aggressive 4-3-3 pressing block. The result was never seriously '
          'in doubt after the 67th-minute goal restored the lead.',
    ),
    homeAnalysis: TeamAnalysisModel(
      teamName: 'GoalSight FC',
      possession: 64,
      style: 'Possession-based',
      pressureStyle: 'High Press',
      compactness: 'Compact',
      attackingZones: ['Left Wing', 'Central Channel'],
      avgRating: 7.82,
      topPlayers: ['p1', 'p2'],
      worstPlayers: ['p4'],
    ),
    awayAnalysis: TeamAnalysisModel(
      teamName: 'Falcons United',
      possession: 36,
      style: 'Counter-attack',
      pressureStyle: 'Low Block',
      compactness: 'Deep',
      attackingZones: ['Right Wing'],
      avgRating: 6.14,
      topPlayers: ['p5'],
      worstPlayers: ['p6'],
    ),
    players: [
      PlayerModel(
        id: 'p1',
        name: 'Hassan Ali',
        position: 'CAM',
        rating: 9.1,
        fatigue: 87,
        performanceStatus: PerformanceStatus.excellent,
        insight: 'Controlled tempo with 11 key touches in the final third. 2 assists, 1 goal, 94% pass accuracy.',
        contribution: ContributionType.attack,
        impact: 'Game Changer',
        goals: 1,
        assists: 2,
        keyPasses: 7,
        isMOTM: true,
      ),
      PlayerModel(
        id: 'p2',
        name: 'Mostafa Samir',
        position: 'LW',
        rating: 8.4,
        fatigue: 72,
        performanceStatus: PerformanceStatus.excellent,
        insight: 'Scored the opener, created 3 chances. Won 6 of 7 dribble attempts on the left flank.',
        contribution: ContributionType.attack,
        impact: 'Decisive',
        goals: 1,
        assists: 1,
        keyPasses: 3,
      ),
      PlayerModel(
        id: 'p3',
        name: 'Ziad Hamdy',
        position: 'CB',
        rating: 7.8,
        fatigue: 55,
        performanceStatus: PerformanceStatus.good,
        insight: 'Commanding in the air — 8 duels won. Initiated 4 build-up sequences from deep.',
        contribution: ContributionType.defense,
        impact: 'Reliable',
        tackles: 5,
        keyPasses: 2,
      ),
      PlayerModel(
        id: 'p4',
        name: 'Tariq Ziad',
        position: 'DM',
        rating: 5.8,
        fatigue: 91,
        performanceStatus: PerformanceStatus.poor,
        insight: 'Lost possession 8 times in dangerous central areas. Poor positioning led to the equaliser.',
        contribution: ContributionType.balanced,
        impact: 'Liability',
        isWorst: true,
      ),
      PlayerModel(
        id: 'p5',
        name: 'Adel Mansour',
        position: 'CM',
        rating: 7.2,
        fatigue: 60,
        performanceStatus: PerformanceStatus.good,
        insight: 'Falcons United\'s most disciplined midfielder — 78% pass completion, 4 interceptions.',
        contribution: ContributionType.defense,
        impact: 'Steady',
        tackles: 4,
        keyPasses: 2,
      ),
      PlayerModel(
        id: 'p6',
        name: 'Karim Essam',
        position: 'LB',
        rating: 4.9,
        fatigue: 83,
        performanceStatus: PerformanceStatus.terrible,
        insight: 'Lost 7 of 9 defensive duels on the flank. Directly responsible for 2 GoalSight goals.',
        contribution: ContributionType.defense,
        impact: 'Liability',
        isWorst: true,
      ),
    ],
  ),

  // ── Match 2: Sharks FC vs Eagles Club ────────────────────────────────────
  MatchAnalysisModel(
    matchId: 'match_002',
    homeTeam: 'Sharks FC',
    awayTeam: 'Eagles Club',
    score: '0 - 0',
    date: 'May 1, 2026',
    status: 'FT',
    intensity: 62,
    recommendations: [
      'Eagles must improve final third entry — only 6 shots in 90 minutes is insufficient.',
      'Sharks should recruit a creative midfielder; 43% of attacks broke down in the middle third.',
      'Both sides can exploit set pieces more effectively — zero goals from 18 combined corners.',
    ],
    summary: MatchSummaryModel(
      dominantTeam: 'None',
      homeAvgRating: 6.48,
      awayAvgRating: 6.61,
      motmPlayerId: 'p7',
      worstPlayerId: 'p10',
      keyMoments: [
        '23\' — Sharks penalty appeal waved away.',
        '55\' — Eagles hit the crossbar from long range.',
        '78\' — Sharks goalkeeper world-class save to deny Eagles.',
      ],
      overallNarrative:
          'A deeply tactical and frustrating contest. Both teams prioritised defensive solidity over '
          'creativity, resulting in a match of rare genuine chances. Omar Fathy\'s composed goalkeeping '
          'was the highlight in an otherwise forgettable encounter. Mid-block versus mid-block produced '
          'a gridlock that neither manager could solve from the bench.',
    ),
    homeAnalysis: TeamAnalysisModel(
      teamName: 'Sharks FC',
      possession: 51,
      style: 'Balanced',
      pressureStyle: 'Mid Block',
      compactness: 'Compact',
      attackingZones: ['Central Channel'],
      avgRating: 6.48,
      topPlayers: ['p7'],
      worstPlayers: ['p8'],
    ),
    awayAnalysis: TeamAnalysisModel(
      teamName: 'Eagles Club',
      possession: 49,
      style: 'Balanced',
      pressureStyle: 'Mid Block',
      compactness: 'Deep',
      attackingZones: ['Right Wing'],
      avgRating: 6.61,
      topPlayers: ['p9'],
      worstPlayers: ['p10'],
    ),
    players: [
      PlayerModel(
        id: 'p7',
        name: 'Omar Fathy',
        position: 'GK',
        rating: 8.0,
        fatigue: 40,
        performanceStatus: PerformanceStatus.excellent,
        insight: '4 saves, including one world-class stop from point blank. Commanded his box with authority.',
        contribution: ContributionType.defense,
        impact: 'Wall',
        isMOTM: true,
      ),
      PlayerModel(
        id: 'p8',
        name: 'Bassem Nabil',
        position: 'RW',
        rating: 5.6,
        fatigue: 74,
        performanceStatus: PerformanceStatus.poor,
        insight: 'Completely isolated on the right wing. 0 successful dribbles, lost possession 9 times.',
        contribution: ContributionType.attack,
        impact: 'Ineffective',
        isWorst: true,
      ),
      PlayerModel(
        id: 'p9',
        name: 'Saad Magdy',
        position: 'ST',
        rating: 7.1,
        fatigue: 68,
        performanceStatus: PerformanceStatus.good,
        insight: '3 shots on target, physically dominant in aerial duels. Unlucky not to score.',
        contribution: ContributionType.attack,
        impact: 'Threat',
        goals: 0,
        keyPasses: 2,
      ),
      PlayerModel(
        id: 'p10',
        name: 'Fady Emam',
        position: 'AM',
        rating: 5.4,
        fatigue: 79,
        performanceStatus: PerformanceStatus.poor,
        insight: 'Failed to link midfield and attack. 41% pass accuracy in the final third — costly.',
        contribution: ContributionType.attack,
        impact: 'Negative',
        isWorst: true,
      ),
    ],
  ),

  // ── Match 3: Lions City vs GoalSight FC ──────────────────────────────────
  MatchAnalysisModel(
    matchId: 'match_003',
    homeTeam: 'Lions City',
    awayTeam: 'GoalSight FC',
    score: '1 - 2',
    date: 'Apr 28, 2026',
    status: 'FT',
    intensity: 88,
    highlightText: 'Last-minute winner',
    recommendations: [
      'GoalSight\'s late-game pressure format (4-2-4 shape) should be used from the 75\' mark consistently.',
      'Lions City must address their 82nd-minute concentration failures — this is the 3rd match conceding late.',
      'Hassan Ali\'s injury risk is elevated — fatigue at 91 after two consecutive high-intensity matches.',
    ],
    summary: MatchSummaryModel(
      dominantTeam: 'GoalSight FC',
      homeAvgRating: 6.71,
      awayAvgRating: 7.44,
      motmPlayerId: 'p1',
      worstPlayerId: 'p11',
      keyMoments: [
        '34\' — Lions City open scoring from a direct free kick.',
        '71\' — GoalSight equalise from a corner routine.',
        '90+2\' — Hassan Ali solo effort wins the match.',
      ],
      overallNarrative:
          'GoalSight FC showed remarkable resilience to come from behind in an away fixture of genuine '
          'quality. Lions City were disciplined for 70 minutes but conceded two late goals as GoalSight '
          'shifted to a more direct approach after the 65th minute. Hassan Ali\'s 92nd-minute finish '
          'combined technical brilliance with physical endurance — an extraordinary individual display.',
    ),
    homeAnalysis: TeamAnalysisModel(
      teamName: 'Lions City',
      possession: 44,
      style: 'Direct',
      pressureStyle: 'Low Block',
      compactness: 'Deep',
      attackingZones: ['Right Wing', 'Set Pieces'],
      avgRating: 6.71,
      topPlayers: ['p12'],
      worstPlayers: ['p11'],
    ),
    awayAnalysis: TeamAnalysisModel(
      teamName: 'GoalSight FC',
      possession: 56,
      style: 'Possession-based',
      pressureStyle: 'High Press',
      compactness: 'Compact',
      attackingZones: ['Central Channel', 'Left Wing'],
      avgRating: 7.44,
      topPlayers: ['p1', 'p13'],
      worstPlayers: ['p14'],
    ),
    players: [
      PlayerModel(
        id: 'p1',
        name: 'Hassan Ali',
        position: 'CAM',
        rating: 8.8,
        fatigue: 91,
        performanceStatus: PerformanceStatus.excellent,
        insight: 'Brilliant late-game performance. Scored the 90+2\' winner after a 60-metre run — fatigue index critical.',
        contribution: ContributionType.attack,
        impact: 'Legendary',
        goals: 1,
        assists: 1,
        keyPasses: 5,
        isMOTM: true,
      ),
      PlayerModel(
        id: 'p11',
        name: 'Walid Nour',
        position: 'CB',
        rating: 5.3,
        fatigue: 85,
        performanceStatus: PerformanceStatus.poor,
        insight: 'Beaten for pace on 4 occasions, directly responsible for the corner routine goal conceded.',
        contribution: ContributionType.defense,
        impact: 'Weak Link',
        isWorst: true,
      ),
      PlayerModel(
        id: 'p12',
        name: 'Tamer Said',
        position: 'ST',
        rating: 7.6,
        fatigue: 70,
        performanceStatus: PerformanceStatus.good,
        insight: 'Lions City\'s best player. Won the free kick that led to the opening goal. Linked play well.',
        contribution: ContributionType.attack,
        impact: 'Consistent',
        goals: 1,
        keyPasses: 3,
      ),
      PlayerModel(
        id: 'p13',
        name: 'Mostafa Samir',
        position: 'LW',
        rating: 7.9,
        fatigue: 65,
        performanceStatus: PerformanceStatus.good,
        insight: 'Constant menace on the left flank. Won the corner that led to the equaliser.',
        contribution: ContributionType.attack,
        impact: 'Disruptive',
        assists: 1,
        keyPasses: 4,
      ),
      PlayerModel(
        id: 'p14',
        name: 'Tariq Ziad',
        position: 'DM',
        rating: 6.1,
        fatigue: 77,
        performanceStatus: PerformanceStatus.average,
        insight: 'Improved from last match but still gave the ball away 5 times in midfield.',
        contribution: ContributionType.balanced,
        impact: 'Below Par',
        tackles: 3,
      ),
    ],
  ),
];
