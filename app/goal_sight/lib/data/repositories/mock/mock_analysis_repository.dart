// ---------------------------------------------------------------------------
// GoalSight — Mock Analysis Repository
//
// Realistic mock implementation of IAnalysisRepository.
// 8 rich match analyses spanning all 5 clubs with full team + player data.
// Replace with SupabaseAnalysisRepository when backend is ready.
// ---------------------------------------------------------------------------

import '../../models/match_analysis_model.dart';
import '../interfaces/i_analysis_repository.dart';
import 'mock_club_repository.dart';

final class MockAnalysisRepository implements IAnalysisRepository {
  const MockAnalysisRepository();

  static const _delay = Duration(milliseconds: 560);

  // ── Static analysis dataset ───────────────────────────────────────────────

  static final List<MatchAnalysisModel> _analyses = [
    // ma_001 — GoalSight FC 3-1 City Panthers (PL, GW38)
    MatchAnalysisModel(
      matchId: 'ma_001',
      homeTeam: 'GoalSight FC',
      awayTeam: 'City Panthers',
      score: '3 - 1',
      date: '18 May 2026',
      status: 'FT',
      intensity: 88,
      highlightText: 'Title decider thriller',
      players: [
        const PlayerModel(
          id: 'gs_p7', name: 'Erling Haaland', position: 'ST',
          rating: 9.4, fatigue: 58, performanceStatus: PerformanceStatus.excellent,
          insight: 'Hat-trick hero — clinical in all three chances',
          contribution: ContributionType.attack, impact: 'Game Changer',
          goals: 3, assists: 0, tackles: 1, keyPasses: 2, isMOTM: true,
        ),
        const PlayerModel(
          id: 'gs_p2', name: 'Kevin De Bruyne', position: 'CM',
          rating: 9.3, fatigue: 40, performanceStatus: PerformanceStatus.excellent,
          insight: 'Orchestrated every attack — 3 key assists',
          contribution: ContributionType.balanced, impact: 'Architect',
          goals: 1, assists: 3, tackles: 6, keyPasses: 9,
        ),
        const PlayerModel(
          id: 'gs_p1', name: 'Mo Salah', position: 'RW',
          rating: 9.1, fatigue: 44, performanceStatus: PerformanceStatus.excellent,
          insight: 'Relentless pressing and pace destabilised defence',
          contribution: ContributionType.attack, impact: 'Disruptor',
          goals: 2, assists: 1, tackles: 4, keyPasses: 5,
        ),
        const PlayerModel(
          id: 'gs_p3', name: 'Virgil van Dijk', position: 'CB',
          rating: 8.9, fatigue: 42, performanceStatus: PerformanceStatus.excellent,
          insight: 'Aerial dominance neutralised Panthers attack',
          contribution: ContributionType.defense, impact: 'Wall',
          goals: 0, assists: 1, tackles: 9, keyPasses: 2,
        ),
        const PlayerModel(
          id: 'cp_p2', name: 'Jamal Wright', position: 'LW',
          rating: 8.9, fatigue: 52, performanceStatus: PerformanceStatus.excellent,
          insight: 'Brilliant goal — beat 2 defenders before finish',
          contribution: ContributionType.attack, impact: 'Threat',
          goals: 1, assists: 1, tackles: 3, keyPasses: 4,
        ),
        const PlayerModel(
          id: 'cp_p1', name: 'Rodri Manzano', position: 'CDM',
          rating: 7.8, fatigue: 55, performanceStatus: PerformanceStatus.good,
          insight: 'Couldn\'t stem the tide despite high interception count',
          contribution: ContributionType.defense, impact: 'Reliable',
          goals: 0, assists: 0, tackles: 12, keyPasses: 3, isWorst: true,
        ),
      ],
      homeAnalysis: const TeamAnalysisModel(
        teamName: 'GoalSight FC',
        possession: 58,
        style: 'High-Press',
        pressureStyle: 'Gegenpressing',
        compactness: 'Aggressive',
        attackingZones: ['Right Wing', 'Central'],
        avgRating: 9.0,
        topPlayers: ['gs_p7', 'gs_p2', 'gs_p1'],
        worstPlayers: [],
      ),
      awayAnalysis: const TeamAnalysisModel(
        teamName: 'City Panthers',
        possession: 42,
        style: 'Positional Play',
        pressureStyle: 'Mid Block',
        compactness: 'Compact',
        attackingZones: ['Left Wing'],
        avgRating: 7.8,
        topPlayers: ['cp_p2'],
        worstPlayers: ['cp_p1'],
      ),
      summary: const MatchSummaryModel(
        dominantTeam: 'GoalSight FC',
        homeAvgRating: 9.0,
        awayAvgRating: 7.8,
        motmPlayerId: 'gs_p7',
        worstPlayerId: 'cp_p1',
        keyMoments: [
          '12\' Haaland breaks offside trap — 1-0',
          '34\' De Bruyne free-kick — 2-0',
          '51\' Wright wonder goal — 2-1',
          '78\' Haaland penalty — 3-1',
          '88\' Haaland completes hat-trick',
        ],
        overallNarrative:
            'GoalSight FC secured the title with a commanding 3-1 victory over City Panthers. Haaland was unstoppable, claiming a hat-trick while De Bruyne pulled every string from deep. The Panthers showed resilience through Wright, but lacked the collective intensity to contain the home side\'s pressing game.',
      ),
      recommendations: [
        'Haaland\'s movement patterns should be replicated in next season\'s training models',
        'De Bruyne\'s set-piece delivery generated 1.2 xG — exploit this more consistently',
        'City Panthers midfield failed to press — tactical shape adjustment needed',
        'High press triggered 9 turnovers in the final third — maintain this approach',
      ],
    ),

    // ma_002 — Falcons United 1-2 GoalSight FC
    MatchAnalysisModel(
      matchId: 'ma_002',
      homeTeam: 'Falcons United',
      awayTeam: 'GoalSight FC',
      score: '1 - 2',
      date: '11 May 2026',
      status: 'FT',
      intensity: 72,
      highlightText: 'Away win seals momentum',
      players: [
        const PlayerModel(
          id: 'gs_p7', name: 'Erling Haaland', position: 'ST',
          rating: 9.0, fatigue: 48, performanceStatus: PerformanceStatus.excellent,
          insight: 'Two goals from three shots — ruthless',
          contribution: ContributionType.attack, impact: 'Game Changer',
          goals: 2, assists: 1, tackles: 2, keyPasses: 1, isMOTM: true,
        ),
        const PlayerModel(
          id: 'f_p2', name: 'Jake Morrison', position: 'ST',
          rating: 8.1, fatigue: 62, performanceStatus: PerformanceStatus.good,
          insight: 'Lone goal from brilliant first touch',
          contribution: ContributionType.attack, impact: 'Reliable',
          goals: 2, assists: 0, tackles: 2, keyPasses: 3,
        ),
        const PlayerModel(
          id: 'f_p3', name: 'Carlos Diaz', position: 'CM',
          rating: 7.8, fatigue: 55, performanceStatus: PerformanceStatus.good,
          insight: 'Energetic performance but lacking end-product',
          contribution: ContributionType.balanced, impact: 'Solid',
          goals: 0, assists: 1, tackles: 8, keyPasses: 5,
        ),
        const PlayerModel(
          id: 'gs_p2', name: 'Kevin De Bruyne', position: 'CM',
          rating: 9.0, fatigue: 36, performanceStatus: PerformanceStatus.excellent,
          insight: 'Pinpoint assists — controlled tempo throughout',
          contribution: ContributionType.balanced, impact: 'Maestro',
          goals: 0, assists: 2, tackles: 7, keyPasses: 10,
        ),
        const PlayerModel(
          id: 'f_p1', name: 'Marcus Webb', position: 'GK',
          rating: 6.8, fatigue: 48, performanceStatus: PerformanceStatus.poor,
          insight: 'Positioning error led to first goal',
          contribution: ContributionType.defense, impact: 'Liability',
          goals: 0, assists: 0, tackles: 0, keyPasses: 0, isWorst: true,
        ),
      ],
      homeAnalysis: const TeamAnalysisModel(
        teamName: 'Falcons United',
        possession: 46,
        style: 'Counter-Attack',
        pressureStyle: 'Low Block',
        compactness: 'Compact',
        attackingZones: ['Central'],
        avgRating: 7.2,
        topPlayers: ['f_p2'],
        worstPlayers: ['f_p1'],
      ),
      awayAnalysis: const TeamAnalysisModel(
        teamName: 'GoalSight FC',
        possession: 54,
        style: 'High-Press',
        pressureStyle: 'High Press',
        compactness: 'Aggressive',
        attackingZones: ['Central', 'Left Wing'],
        avgRating: 8.8,
        topPlayers: ['gs_p7', 'gs_p2'],
        worstPlayers: [],
      ),
      summary: const MatchSummaryModel(
        dominantTeam: 'GoalSight FC',
        homeAvgRating: 7.2,
        awayAvgRating: 8.8,
        motmPlayerId: 'gs_p7',
        worstPlayerId: 'f_p1',
        keyMoments: [
          '8\' Haaland heads in De Bruyne corner — 0-1',
          '56\' Morrison equalises from counter — 1-1',
          '71\' Haaland slots second after brilliant press — 1-2',
        ],
        overallNarrative:
            'GoalSight FC ground out a vital away win at Falcon Park. After Morrison\'s equaliser threatened an upset, Haaland\'s clinical second goal proved decisive. Falcons showed resilience but lacked the technical quality to contain De Bruyne\'s creative influence.',
      ),
      recommendations: [
        'Falcons should increase midfield press to reduce De Bruyne time on ball',
        'Webb\'s distribution errors need immediate correction',
        'GoalSight transitions from wide areas generating high-quality chances',
        'Haaland\'s off-ball movement creates space — analyse for pattern exploitation',
      ],
    ),

    // ma_003 — GoalSight FC 2-0 Red Lions FC
    MatchAnalysisModel(
      matchId: 'ma_003',
      homeTeam: 'GoalSight FC',
      awayTeam: 'Red Lions FC',
      score: '2 - 0',
      date: '4 May 2026',
      status: 'FT',
      intensity: 65,
      players: [
        const PlayerModel(
          id: 'gs_p7', name: 'Erling Haaland', position: 'ST',
          rating: 9.3, fatigue: 50, performanceStatus: PerformanceStatus.excellent,
          insight: 'Brace from two clinical finishes',
          contribution: ContributionType.attack, impact: 'Game Changer',
          goals: 3, assists: 0, tackles: 1, keyPasses: 2, isMOTM: true,
        ),
        const PlayerModel(
          id: 'gs_p3', name: 'Virgil van Dijk', position: 'CB',
          rating: 8.8, fatigue: 40, performanceStatus: PerformanceStatus.excellent,
          insight: 'Shut out Red Lions physical threat completely',
          contribution: ContributionType.defense, impact: 'Wall',
          goals: 0, assists: 0, tackles: 12, keyPasses: 2,
        ),
        const PlayerModel(
          id: 'rl_p1', name: 'Diego Santos', position: 'ST',
          rating: 8.0, fatigue: 70, performanceStatus: PerformanceStatus.good,
          insight: 'Won headers but no clear chances created',
          contribution: ContributionType.attack, impact: 'Isolated',
          goals: 1, assists: 0, tackles: 2, keyPasses: 3,
        ),
        const PlayerModel(
          id: 'rl_p3', name: 'Ahmed Hassan', position: 'RW',
          rating: 7.9, fatigue: 60, performanceStatus: PerformanceStatus.good,
          insight: 'Dangerous runs but final ball quality lacking',
          contribution: ContributionType.attack, impact: 'Threat',
          goals: 1, assists: 0, tackles: 5, keyPasses: 4,
        ),
      ],
      homeAnalysis: const TeamAnalysisModel(
        teamName: 'GoalSight FC',
        possession: 62,
        style: 'High-Press',
        pressureStyle: 'Gegenpressing',
        compactness: 'Aggressive',
        attackingZones: ['Central', 'Right Wing'],
        avgRating: 8.9,
        topPlayers: ['gs_p7', 'gs_p3'],
        worstPlayers: [],
      ),
      awayAnalysis: const TeamAnalysisModel(
        teamName: 'Red Lions FC',
        possession: 38,
        style: 'Direct Play',
        pressureStyle: 'Low Block',
        compactness: 'Deep',
        attackingZones: ['Right Wing'],
        avgRating: 7.5,
        topPlayers: ['rl_p1'],
        worstPlayers: [],
      ),
      summary: const MatchSummaryModel(
        dominantTeam: 'GoalSight FC',
        homeAvgRating: 8.9,
        awayAvgRating: 7.5,
        motmPlayerId: 'gs_p7',
        worstPlayerId: '',
        keyMoments: [
          '22\' Haaland penalty — 1-0',
          '67\' Haaland tap-in from De Bruyne cross — 2-0',
        ],
        overallNarrative:
            'A professional GoalSight FC performance. Red Lions\' direct approach rarely troubled van Dijk and the organised defensive shape. Haaland continued his scoring run with a brace, making it 36 league goals for the season.',
      ),
      recommendations: [
        'Red Lions need a more creative midfield option to break high press',
        'Santos\'s physical threat must be complemented with service to feet',
        'GoalSight continued clean sheet run — defensive structure exemplary',
        'Hassan\'s crossing accuracy (22%) must improve to create clear chances',
      ],
    ),

    // ma_004 — City Panthers 4-2 Thunder Athletic
    MatchAnalysisModel(
      matchId: 'ma_004',
      homeTeam: 'City Panthers',
      awayTeam: 'Thunder Athletic',
      score: '4 - 2',
      date: '10 May 2026',
      status: 'FT',
      intensity: 82,
      highlightText: 'Panthers on fire',
      players: [
        const PlayerModel(
          id: 'cp_p1', name: 'Rodri Manzano', position: 'CDM',
          rating: 9.3, fatigue: 32, performanceStatus: PerformanceStatus.excellent,
          insight: 'Controlled the game from deep — 2G 1A',
          contribution: ContributionType.balanced, impact: 'Architect',
          goals: 2, assists: 1, tackles: 16, keyPasses: 10, isMOTM: true,
        ),
        const PlayerModel(
          id: 'cp_p2', name: 'Jamal Wright', position: 'LW',
          rating: 9.0, fatigue: 50, performanceStatus: PerformanceStatus.excellent,
          insight: 'Explosive pace won 3 direct duels',
          contribution: ContributionType.attack, impact: 'Destroyer',
          goals: 3, assists: 1, tackles: 2, keyPasses: 4,
        ),
        const PlayerModel(
          id: 'th_p1', name: 'Luca Romano', position: 'CAM',
          rating: 8.3, fatigue: 48, performanceStatus: PerformanceStatus.good,
          insight: '2 assists in a losing effort — showed class',
          contribution: ContributionType.attack, impact: 'Bright Spot',
          goals: 1, assists: 2, tackles: 3, keyPasses: 8,
        ),
        const PlayerModel(
          id: 'th_p3', name: 'Omar Ndiaye', position: 'ST',
          rating: 8.4, fatigue: 54, performanceStatus: PerformanceStatus.good,
          insight: 'Brace but team couldn\'t contain Panthers',
          contribution: ContributionType.attack, impact: 'Fighter',
          goals: 2, assists: 0, tackles: 2, keyPasses: 2,
        ),
      ],
      homeAnalysis: const TeamAnalysisModel(
        teamName: 'City Panthers',
        possession: 68,
        style: 'Positional Play',
        pressureStyle: 'High Press',
        compactness: 'Wide',
        attackingZones: ['Left Wing', 'Central', 'Right Wing'],
        avgRating: 9.0,
        topPlayers: ['cp_p1', 'cp_p2'],
        worstPlayers: [],
      ),
      awayAnalysis: const TeamAnalysisModel(
        teamName: 'Thunder Athletic',
        possession: 32,
        style: 'High Line',
        pressureStyle: 'High Press',
        compactness: 'Aggressive',
        attackingZones: ['Central'],
        avgRating: 8.0,
        topPlayers: ['th_p3', 'th_p1'],
        worstPlayers: [],
      ),
      summary: const MatchSummaryModel(
        dominantTeam: 'City Panthers',
        homeAvgRating: 9.0,
        awayAvgRating: 8.0,
        motmPlayerId: 'cp_p1',
        worstPlayerId: '',
        keyMoments: [
          '5\' Wright opens with header — 1-0',
          '19\' Rodri long range — 2-0',
          '38\' Ndiaye pulls one back — 2-1',
          '44\' Wright second — 3-1',
          '68\' Romano free-kick — 3-2',
          '83\' Rodri seals win — 4-2',
        ],
        overallNarrative:
            'City Panthers put on a dominant display of possession football, with Rodri and Wright driving a scintillating 4-2 win. Thunder Athletic showed spirit with two goals but were ultimately overwhelmed by the Panthers\' quality. Ndiaye and Romano were bright in defeat.',
      ),
      recommendations: [
        'Panthers\' high press creates early scoring opportunities — opponent teams struggle',
        'Thunder Athletic high line was exposed repeatedly on transitions',
        'Romano and Ndiaye chemistry is strong — build around this combination',
        'Panthers\' wide triangle (Wright + CB overlaps) needs defending study',
      ],
    ),

    // ma_005 — Red Lions FC 1-3 City Panthers
    MatchAnalysisModel(
      matchId: 'ma_005',
      homeTeam: 'Red Lions FC',
      awayTeam: 'City Panthers',
      score: '1 - 3',
      date: '3 May 2026',
      status: 'FT',
      intensity: 74,
      players: [
        const PlayerModel(
          id: 'cp_p4', name: 'Bernardo Costa', position: 'CAM',
          rating: 8.8, fatigue: 38, performanceStatus: PerformanceStatus.excellent,
          insight: 'Brilliant creative display — 2 assists and a goal',
          contribution: ContributionType.attack, impact: 'Game Changer',
          goals: 1, assists: 2, tackles: 4, keyPasses: 8, isMOTM: true,
        ),
        const PlayerModel(
          id: 'cp_p1', name: 'Rodri Manzano', position: 'CDM',
          rating: 9.1, fatigue: 36, performanceStatus: PerformanceStatus.excellent,
          insight: 'Dominant midfield display — won every duel',
          contribution: ContributionType.balanced, impact: 'Anchor',
          goals: 0, assists: 3, tackles: 12, keyPasses: 9,
        ),
        const PlayerModel(
          id: 'rl_p1', name: 'Diego Santos', position: 'ST',
          rating: 7.8, fatigue: 72, performanceStatus: PerformanceStatus.good,
          insight: 'Lone goal but starved of service throughout',
          contribution: ContributionType.attack, impact: 'Isolated',
          goals: 2, assists: 0, tackles: 1, keyPasses: 2,
        ),
        const PlayerModel(
          id: 'rl_p2', name: 'Sam Clarke', position: 'CM',
          rating: 6.8, fatigue: 65, performanceStatus: PerformanceStatus.poor,
          insight: 'Overrun in midfield — couldn\'t match Panthers intensity',
          contribution: ContributionType.defense, impact: 'Overloaded',
          goals: 0, assists: 0, tackles: 8, keyPasses: 2, isWorst: true,
        ),
      ],
      homeAnalysis: const TeamAnalysisModel(
        teamName: 'Red Lions FC',
        possession: 34,
        style: 'Direct Play',
        pressureStyle: 'Low Block',
        compactness: 'Deep',
        attackingZones: ['Central'],
        avgRating: 7.0,
        topPlayers: ['rl_p1'],
        worstPlayers: ['rl_p2'],
      ),
      awayAnalysis: const TeamAnalysisModel(
        teamName: 'City Panthers',
        possession: 66,
        style: 'Positional Play',
        pressureStyle: 'High Press',
        compactness: 'Wide',
        attackingZones: ['Left Wing', 'Central'],
        avgRating: 8.9,
        topPlayers: ['cp_p4', 'cp_p1'],
        worstPlayers: [],
      ),
      summary: const MatchSummaryModel(
        dominantTeam: 'City Panthers',
        homeAvgRating: 7.0,
        awayAvgRating: 8.9,
        motmPlayerId: 'cp_p4',
        worstPlayerId: 'rl_p2',
        keyMoments: [
          '14\' Costa penalty — 0-1',
          '29\' Wright taps in — 0-2',
          '58\' Santos header — 1-2',
          '77\' Rodri caps win — 1-3',
        ],
        overallNarrative:
            'City Panthers eased to a 3-1 win at Lion Fortress, with Bernardo Costa pulling every string in the final third. Red Lions fought hard but were technically outclassed in midfield, where Clarke struggled to impose himself against the Champions\' pressing machine.',
      ),
      recommendations: [
        'Red Lions Clarke needs a midfield partner with technical ability',
        'Panthers away performances show no drop from home form',
        'Santos service must improve — 2 successful line-breaking passes only',
        'Panthers\' Costa-Wright combination creates dangerous overloads',
      ],
    ),

    // ma_006 — Red Lions FC 2-2 Thunder Athletic
    MatchAnalysisModel(
      matchId: 'ma_006',
      homeTeam: 'Red Lions FC',
      awayTeam: 'Thunder Athletic',
      score: '2 - 2',
      date: '26 Apr 2026',
      status: 'FT',
      intensity: 79,
      highlightText: 'Last minute equaliser',
      players: [
        const PlayerModel(
          id: 'th_p3', name: 'Omar Ndiaye', position: 'ST',
          rating: 8.3, fatigue: 56, performanceStatus: PerformanceStatus.excellent,
          insight: 'Both goals — including stunning 90+2 equaliser',
          contribution: ContributionType.attack, impact: 'Hero',
          goals: 2, assists: 1, tackles: 2, keyPasses: 2, isMOTM: true,
        ),
        const PlayerModel(
          id: 'rl_p1', name: 'Diego Santos', position: 'ST',
          rating: 8.1, fatigue: 65, performanceStatus: PerformanceStatus.good,
          insight: 'Double helped Red Lions race into two-goal lead',
          contribution: ContributionType.attack, impact: 'Fighter',
          goals: 2, assists: 1, tackles: 2, keyPasses: 3,
        ),
        const PlayerModel(
          id: 'th_p1', name: 'Luca Romano', position: 'CAM',
          rating: 8.2, fatigue: 52, performanceStatus: PerformanceStatus.good,
          insight: 'Two assists in crucial comeback effort',
          contribution: ContributionType.attack, impact: 'Provider',
          goals: 2, assists: 1, tackles: 4, keyPasses: 7,
        ),
        const PlayerModel(
          id: 'rl_p2', name: 'Sam Clarke', position: 'CM',
          rating: 7.4, fatigue: 60, performanceStatus: PerformanceStatus.average,
          insight: 'Steady but lacking in transitional moments',
          contribution: ContributionType.balanced, impact: 'Functional',
          goals: 0, assists: 1, tackles: 9, keyPasses: 3,
        ),
      ],
      homeAnalysis: const TeamAnalysisModel(
        teamName: 'Red Lions FC',
        possession: 48,
        style: 'Direct Play',
        pressureStyle: 'Mid Block',
        compactness: 'Compact',
        attackingZones: ['Central', 'Right Wing'],
        avgRating: 7.8,
        topPlayers: ['rl_p1'],
        worstPlayers: [],
      ),
      awayAnalysis: const TeamAnalysisModel(
        teamName: 'Thunder Athletic',
        possession: 52,
        style: 'High Line',
        pressureStyle: 'High Press',
        compactness: 'Wide',
        attackingZones: ['Central', 'Left Wing'],
        avgRating: 8.1,
        topPlayers: ['th_p3', 'th_p1'],
        worstPlayers: [],
      ),
      summary: const MatchSummaryModel(
        dominantTeam: 'Thunder Athletic',
        homeAvgRating: 7.8,
        awayAvgRating: 8.1,
        motmPlayerId: 'th_p3',
        worstPlayerId: '',
        keyMoments: [
          '18\' Santos header — 1-0',
          '36\' Santos penalty — 2-0',
          '65\' Ndiaye pulls one back — 2-1',
          '90+2\' Ndiaye rocket into top corner — 2-2',
        ],
        overallNarrative:
            'A stunning last-gasp equaliser from Ndiaye denied Red Lions all three points in an eventful encounter. Red Lions dominated the first half through Santos\'s physicality, but Thunder Athletic grew stronger as the match wore on, with Romano and Ndiaye combining beautifully in the comeback.',
      ),
      recommendations: [
        'Ndiaye\'s late-game output is exceptional — ensure he is fresh for final 30 minutes',
        'Red Lions conceded momentum after 65 minutes — fitness conditioning needed',
        'Romano\'s through-ball range should be studied for offensive pattern development',
        'Thunder Athletic\'s high line vulnerable on fast transitions — exploit this',
      ],
    ),

    // ma_007 — Thunder Athletic 3-1 Falcons United
    MatchAnalysisModel(
      matchId: 'ma_007',
      homeTeam: 'Thunder Athletic',
      awayTeam: 'Falcons United',
      score: '3 - 1',
      date: '19 Apr 2026',
      status: 'FT',
      intensity: 76,
      players: [
        const PlayerModel(
          id: 'th_p3', name: 'Omar Ndiaye', position: 'ST',
          rating: 8.5, fatigue: 50, performanceStatus: PerformanceStatus.excellent,
          insight: 'Hat-trick threat — 3 goals, relentless movement',
          contribution: ContributionType.attack, impact: 'Unstoppable',
          goals: 3, assists: 0, tackles: 2, keyPasses: 1, isMOTM: true,
        ),
        const PlayerModel(
          id: 'th_p1', name: 'Luca Romano', position: 'CAM',
          rating: 8.4, fatigue: 46, performanceStatus: PerformanceStatus.excellent,
          insight: 'Three assists — sublime vision and execution',
          contribution: ContributionType.attack, impact: 'Maestro',
          goals: 1, assists: 3, tackles: 2, keyPasses: 9,
        ),
        const PlayerModel(
          id: 'f_p2', name: 'Jake Morrison', position: 'ST',
          rating: 7.9, fatigue: 58, performanceStatus: PerformanceStatus.good,
          insight: 'Consolation goal but isolated from team play',
          contribution: ContributionType.attack, impact: 'Consolation',
          goals: 1, assists: 1, tackles: 2, keyPasses: 2,
        ),
        const PlayerModel(
          id: 'f_p4', name: 'Luis Ferreira', position: 'CB',
          rating: 6.5, fatigue: 62, performanceStatus: PerformanceStatus.poor,
          insight: 'Beaten repeatedly on Ndiaye\'s runs',
          contribution: ContributionType.defense, impact: 'Exposed',
          goals: 0, assists: 0, tackles: 10, keyPasses: 1, isWorst: true,
        ),
      ],
      homeAnalysis: const TeamAnalysisModel(
        teamName: 'Thunder Athletic',
        possession: 56,
        style: 'High Line',
        pressureStyle: 'High Press',
        compactness: 'Wide',
        attackingZones: ['Central', 'Right Wing'],
        avgRating: 8.4,
        topPlayers: ['th_p3', 'th_p1'],
        worstPlayers: [],
      ),
      awayAnalysis: const TeamAnalysisModel(
        teamName: 'Falcons United',
        possession: 44,
        style: 'Counter-Attack',
        pressureStyle: 'Low Block',
        compactness: 'Compact',
        attackingZones: ['Central'],
        avgRating: 7.0,
        topPlayers: ['f_p2'],
        worstPlayers: ['f_p4'],
      ),
      summary: const MatchSummaryModel(
        dominantTeam: 'Thunder Athletic',
        homeAvgRating: 8.4,
        awayAvgRating: 7.0,
        motmPlayerId: 'th_p3',
        worstPlayerId: 'f_p4',
        keyMoments: [
          '12\' Romano free-kick assists Ndiaye — 1-0',
          '41\' Romano chip — 2-0',
          '55\' Morrison pulls one back — 2-1',
          '74\' Ndiaye seals win — 3-1',
        ],
        overallNarrative:
            'Thunder Athletic put on a dominant home display against a conservative Falcons United. Romano and Ndiaye\'s partnership was irresistible — combining for all three goals. Falcons struggled to break from deep and Ferreira was repeatedly exposed in behind.',
      ),
      recommendations: [
        'Romano-Ndiaye partnership needs opposition study — strongest in league',
        'Ferreira\'s pace deficit creates vulnerability against speed threats',
        'Falcons must improve from counter-attack only approach',
        'Thunder press in first 15 minutes is extremely effective — replication needed',
      ],
    ),

    // ma_008 — Falcons United 2-0 Red Lions FC
    MatchAnalysisModel(
      matchId: 'ma_008',
      homeTeam: 'Falcons United',
      awayTeam: 'Red Lions FC',
      score: '2 - 0',
      date: '12 Apr 2026',
      status: 'FT',
      intensity: 68,
      players: [
        const PlayerModel(
          id: 'f_p2', name: 'Jake Morrison', position: 'ST',
          rating: 8.0, fatigue: 52, performanceStatus: PerformanceStatus.excellent,
          insight: 'Two goals — aerial and technical quality',
          contribution: ContributionType.attack, impact: 'Decisive',
          goals: 2, assists: 1, tackles: 2, keyPasses: 3, isMOTM: true,
        ),
        const PlayerModel(
          id: 'f_p3', name: 'Carlos Diaz', position: 'CM',
          rating: 7.8, fatigue: 50, performanceStatus: PerformanceStatus.good,
          insight: 'Energetic midfield display with 2 assists',
          contribution: ContributionType.balanced, impact: 'Engine',
          goals: 0, assists: 2, tackles: 10, keyPasses: 5,
        ),
        const PlayerModel(
          id: 'rl_p2', name: 'Sam Clarke', position: 'CM',
          rating: 7.0, fatigue: 58, performanceStatus: PerformanceStatus.average,
          insight: 'Lacked creativity in midfield',
          contribution: ContributionType.defense, impact: 'Neutral',
          goals: 0, assists: 0, tackles: 7, keyPasses: 2,
        ),
        const PlayerModel(
          id: 'f_p1', name: 'Marcus Webb', position: 'GK',
          rating: 8.2, fatigue: 38, performanceStatus: PerformanceStatus.excellent,
          insight: 'Three vital saves kept the clean sheet intact',
          contribution: ContributionType.defense, impact: 'Guardian',
          goals: 0, assists: 0, tackles: 0, keyPasses: 0,
        ),
      ],
      homeAnalysis: const TeamAnalysisModel(
        teamName: 'Falcons United',
        possession: 48,
        style: 'Counter-Attack',
        pressureStyle: 'Mid Block',
        compactness: 'Compact',
        attackingZones: ['Central'],
        avgRating: 7.8,
        topPlayers: ['f_p2', 'f_p3'],
        worstPlayers: [],
      ),
      awayAnalysis: const TeamAnalysisModel(
        teamName: 'Red Lions FC',
        possession: 52,
        style: 'Direct Play',
        pressureStyle: 'High Press',
        compactness: 'Wide',
        attackingZones: ['Right Wing'],
        avgRating: 7.2,
        topPlayers: [],
        worstPlayers: ['rl_p2'],
      ),
      summary: const MatchSummaryModel(
        dominantTeam: 'Falcons United',
        homeAvgRating: 7.8,
        awayAvgRating: 7.2,
        motmPlayerId: 'f_p2',
        worstPlayerId: 'rl_p2',
        keyMoments: [
          '29\' Morrison header from Diaz cross — 1-0',
          '61\' Morrison penalty — 2-0',
        ],
        overallNarrative:
            'Falcons United\'s efficient counter-attacking football earned a clean sheet win over Red Lions. Morrison was the difference-maker with two goals, while Webb\'s three saves kept things comfortable. Red Lions\' possession stats flattered their overall performance.',
      ),
      recommendations: [
        'Morrison\'s aerial threat must be utilised with more set-piece routines',
        'Falcons\' compact defensive shape limiting dangerous opponent chances',
        'Red Lions\' high press not creating enough turnovers — timing off',
        'Webb\'s improved form since recovery should be noted for selection',
      ],
    ),
  ];

  // ── IAnalysisRepository ───────────────────────────────────────────────────

  @override
  Future<List<MatchAnalysisModel>> fetchAnalyses({String? clubId}) async {
    await Future.delayed(_delay);
    if (clubId == null) return List.unmodifiable(_analyses);
    return _analyses
        .where((a) => a.homeTeam.contains(_clubName(clubId)) ||
            a.awayTeam.contains(_clubName(clubId)))
        .toList();
  }

  @override
  Future<MatchAnalysisModel> fetchAnalysisById(String id) async {
    await Future.delayed(_delay);
    return _analyses.firstWhere(
      (a) => a.matchId == id,
      orElse: () => throw RepositoryException('Analysis not found: $id'),
    );
  }

  @override
  Future<List<MatchAnalysisModel>> fetchAnalysesPaged({
    required int page,
    int pageSize = 20,
    String? clubId,
    String? matchId,
  }) async {
    await Future.delayed(_delay);
    var list = await fetchAnalyses(clubId: clubId);
    if (matchId != null) {
      list = list.where((a) => a.matchId == matchId).toList();
    }
    final start = page * pageSize;
    final end = (start + pageSize).clamp(0, list.length);
    if (start >= list.length) return [];
    return list.sublist(start, end);
  }

  @override
  Future<MatchAnalysisModel?> fetchLatestAnalysis({String? clubId}) async {
    await Future.delayed(_delay);
    final list = await fetchAnalyses(clubId: clubId);
    if (list.isEmpty) return null;
    return list.first; // Already ordered latest-first
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static String _clubName(String clubId) {
    const names = {
      'club_01': 'GoalSight',
      'club_02': 'Falcons',
      'club_03': 'Panthers',
      'club_04': 'Red Lions',
      'club_05': 'Thunder',
    };
    return names[clubId] ?? '';
  }
}
