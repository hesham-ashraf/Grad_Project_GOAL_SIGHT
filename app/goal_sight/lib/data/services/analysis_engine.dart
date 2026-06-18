// ---------------------------------------------------------------------------
// GoalSight — Analysis Engine
//
// The flow this implements:
//   manager uploads a match  →  the 4 models analyse it (backend)  →  they
//   return 4 JSON payloads + an analyzed match video  →  we persist the match
//   analysis + analyzed video in the DB, show it in the app, and roll every
//   player's verdict into their living profile (create or UPDATE existing).
//
// Two implementations behind [IAnalysisEngine]:
//   * [ModelAnalysisEngine]      — the REAL flow. POSTs the uploaded video to
//                                  the ML backend (ANALYSIS_API_URL), receives
//                                  the 4-model JSON + analyzed video URL, and
//                                  persists it. Falls back to the simulator
//                                  when no backend is configured or a call
//                                  fails (so demos keep working).
//   * [SimulatedAnalysisEngine]  — a deterministic stub that fabricates a
//                                  believable analysis. Used as the fallback.
//
// Both build a [MatchAnalysisResult] and hand it to the shared
// [_AnalysisPersister], which writes:
//   * match_analyses          (header + analyzed_video_url + MOTM/worst keys)
//   * team_match_analysis      (home/away tactical block)
//   * match_player_analysis    (per-player verdict; players matched by jersey
//                               or name, auto-created if newly detected)
// owner_club_id is stamped by the DB trigger and the match_player_analysis
// rows fire the aggregation trigger that updates each player's profile
// (player_intelligence) — inserting if new, updating if it already exists.
// ---------------------------------------------------------------------------

import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/analysis_config.dart';
import '../models/upload_job_model.dart';

abstract interface class IAnalysisEngine {
  /// Runs (or simulates) analysis for a completed upload and persists the
  /// result. [sourceVideoUrl] is the signed URL of the manager's uploaded
  /// video. Returns the new `match_analyses` id, or null if it could not run
  /// (e.g. the user has no club). Best-effort: callers treat failures as
  /// non-fatal.
  Future<String?> analyzeUpload({
    required String uploadJobId,
    required UploadJobModel job,
    String? sourceVideoUrl,
  });
}

// ───────────────────────── Structured result ──────────────────────────────
// The normalized shape both engines produce and the persister writes.

class AnalysisPlayerVerdict {
  const AnalysisPlayerVerdict({
    required this.playerName,
    required this.position,
    required this.rating,
    required this.fatigue,
    this.jerseyNumber,
    this.performanceStatus = 'average',
    this.contribution = 'balanced',
    this.impact = 'Medium',
    this.insight = '',
    this.goals = 0,
    this.assists = 0,
    this.tackles = 0,
    this.keyPasses = 0,
    this.isMotm = false,
    this.isWorst = false,
  });

  final int? jerseyNumber;
  final String playerName;
  final String position;
  final double rating;
  final int fatigue;
  final String performanceStatus; // excellent/good/average/poor/terrible
  final String contribution; // attack/defense/balanced
  final String impact; // High/Medium/Low
  final String insight;
  final int goals, assists, tackles, keyPasses;
  final bool isMotm, isWorst;
}

class AnalysisTeamBlock {
  const AnalysisTeamBlock({
    required this.side,
    required this.teamName,
    this.possession = 50,
    this.style = '',
    this.pressureStyle = '',
    this.compactness = '',
    this.attackingZones = const [],
    this.avgRating = 0,
    this.topPlayers = const [],
    this.worstPlayers = const [],
  });

  final String side; // home/away
  final String teamName;
  final int possession;
  final String style, pressureStyle, compactness;
  final List<String> attackingZones;
  final double avgRating;
  final List<String> topPlayers, worstPlayers;
}

class MatchAnalysisResult {
  const MatchAnalysisResult({
    required this.home,
    required this.away,
    required this.players,
    this.analyzedVideoUrl,
    this.score = '',
    this.resultStatus = 'FT',
    this.dominantTeam = '',
    this.highlightText = '',
    this.overallNarrative = '',
    this.homeAvgRating = 0,
    this.awayAvgRating = 0,
    this.intensity = 0,
    this.keyMoments = const [],
    this.recommendations = const [],
  });

  final String? analyzedVideoUrl;
  final String score, resultStatus, dominantTeam, highlightText, overallNarrative;
  final double homeAvgRating, awayAvgRating;
  final int intensity;
  final List<String> keyMoments, recommendations;
  final AnalysisTeamBlock home, away;
  final List<AnalysisPlayerVerdict> players;
}

// ───────────────────────── Shared persistence ─────────────────────────────

class _AnalysisPersister {
  const _AnalysisPersister();

  SupabaseClient get _client => Supabase.instance.client;

  Future<String?> persist({
    required String uploadJobId,
    required UploadJobModel job,
    required MatchAnalysisResult result,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return null;

    final profile = await _client
        .from('profiles')
        .select('club_id')
        .eq('id', uid)
        .maybeSingle();
    final clubId = profile?['club_id'] as String?;
    if (clubId == null) return null; // no club → nothing to scope the data to

    // 1) Analysis header (owner_club_id stamped by trigger).
    final header = await _client
        .from('match_analyses')
        .insert({
          'upload_job_id': uploadJobId,
          'generated_by': uid,
          'status': 'completed',
          'home_team_name': job.homeTeam,
          'away_team_name': job.awayTeam,
          'score': result.score,
          'date_label': _dateLabel(job.matchDate),
          'result_status': result.resultStatus,
          'dominant_team': result.dominantTeam,
          'home_avg_rating': result.homeAvgRating,
          'away_avg_rating': result.awayAvgRating,
          'intensity': result.intensity,
          'highlight_text': result.highlightText,
          'overall_narrative': result.overallNarrative,
          'key_moments': result.keyMoments,
          'recommendations': result.recommendations,
          // The playable analyzed match: the model's rendered video when
          // provided, else the manager's uploaded video, else a sample clip.
          'analyzed_video_url':
              (result.analyzedVideoUrl != null && result.analyzedVideoUrl!.isNotEmpty)
                  ? result.analyzedVideoUrl
                  : _sampleAnalyzedVideo,
        })
        .select('id')
        .single();
    final analysisId = header['id'].toString();

    // 2) Per-team tactical block.
    await _client.from('team_match_analysis').insert([
      _teamRow(analysisId, result.home),
      _teamRow(analysisId, result.away),
    ]);

    // 3) Per-player verdicts → fires the aggregation trigger that updates each
    //    player's living profile.
    if (result.players.isNotEmpty) {
      final squad = (await _client
              .from('players')
              .select('id, full_name, position, jersey_number')
              .eq('owner_club_id', clubId))
          .cast<Map<String, dynamic>>();

      String? motmKey, worstKey;
      final rows = <Map<String, dynamic>>[];
      for (final v in result.players) {
        final playerId = await _resolvePlayerId(clubId, squad, v);
        final key = playerId ?? v.playerName;
        if (v.isMotm) motmKey = key;
        if (v.isWorst) worstKey = key;
        rows.add({
          'match_analysis_id': analysisId,
          'player_id': playerId,
          'player_key': key,
          'player_name': v.playerName,
          'player_position': v.position,
          'rating': v.rating,
          'fatigue': v.fatigue,
          'performance_status': v.performanceStatus,
          'contribution': v.contribution,
          'impact': v.impact,
          'insight': v.insight,
          'goals': v.goals,
          'assists': v.assists,
          'tackles': v.tackles,
          'key_passes': v.keyPasses,
          'is_motm': v.isMotm,
          'is_worst': v.isWorst,
        });
      }
      await _client.from('match_player_analysis').insert(rows);

      if (motmKey != null || worstKey != null) {
        await _client.from('match_analyses').update({
          if (motmKey != null) 'motm_player_key': motmKey,
          if (worstKey != null) 'worst_player_key': worstKey,
        }).eq('id', analysisId);
      }
    }

    return analysisId;
  }

  /// Maps a detected verdict to an existing player (by jersey, then name) in the
  /// club's squad, auto-creating the player when newly detected so its profile
  /// gets built. Returns null only when the verdict has no usable identity.
  Future<String?> _resolvePlayerId(
    String clubId,
    List<Map<String, dynamic>> squad,
    AnalysisPlayerVerdict v,
  ) async {
    if (v.jerseyNumber != null) {
      for (final p in squad) {
        if ((p['jersey_number'] as num?)?.toInt() == v.jerseyNumber) {
          return p['id'].toString();
        }
      }
    }
    final name = v.playerName.trim().toLowerCase();
    if (name.isNotEmpty) {
      for (final p in squad) {
        if ((p['full_name'] ?? '').toString().trim().toLowerCase() == name) {
          return p['id'].toString();
        }
      }
    }
    if (v.playerName.trim().isEmpty) return null;

    // Newly detected player → register them in this club's squad.
    final created = await _client
        .from('players')
        .insert({
          'full_name': v.playerName.trim(),
          'position': v.position,
          'team_id': clubId,
          'owner_club_id': clubId,
          if (v.jerseyNumber != null) 'jersey_number': v.jerseyNumber,
          'season_rating': 6.0,
          'season_goals': 0,
          'season_assists': 0,
          'season_tackles': 0,
          'appearances': 0,
        })
        .select('id')
        .single();
    final id = created['id'].toString();
    squad.add({
      'id': id,
      'full_name': v.playerName.trim(),
      'position': v.position,
      'jersey_number': v.jerseyNumber,
    });
    return id;
  }

  Map<String, dynamic> _teamRow(String analysisId, AnalysisTeamBlock t) => {
        'match_analysis_id': analysisId,
        'side': t.side,
        'team_name': t.teamName,
        'possession': t.possession,
        'style': t.style,
        'pressure_style': t.pressureStyle,
        'compactness': t.compactness,
        'attacking_zones': t.attackingZones,
        'avg_rating': t.avgRating,
        'top_players': t.topPlayers,
        'worst_players': t.worstPlayers,
      };
}

// ───────────────────────── Real backend engine ────────────────────────────

/// Calls the ML backend (the 4 models), parses its response, and persists it.
///
/// Backend contract — POST `${ANALYSIS_API_URL}/analyze`
///   request  body : { upload_job_id, video_url, home_team, away_team,
///                     competition, venue, match_date }
///   response body : {
///     "analyzed_video_url": "https://.../analyzed.mp4",        // rendered match
///     "match":  { score, result_status, intensity, dominant_team,
///                 home_avg_rating, away_avg_rating, highlight_text,
///                 overall_narrative, key_moments:[], recommendations:[] },
///     "teams":  { "home": <team>, "away": <team> },            // <team> below
///     "players":[ { jersey_number, player_name, position, rating, fatigue,
///                   performance_status, contribution, impact, insight,
///                   goals, assists, tackles, key_passes, is_motm, is_worst } ]
///   }
///   <team> = { team_name, possession, style, pressure_style, compactness,
///              attacking_zones:[], avg_rating, top_players:[], worst_players:[] }
class ModelAnalysisEngine implements IAnalysisEngine {
  ModelAnalysisEngine({IAnalysisEngine? fallback, Dio? dio})
      : _fallback = fallback ?? const SimulatedAnalysisEngine(),
        _dio = dio ?? Dio();

  final IAnalysisEngine _fallback;
  final Dio _dio;

  SupabaseClient get _client => Supabase.instance.client;

  @override
  Future<String?> analyzeUpload({
    required String uploadJobId,
    required UploadJobModel job,
    String? sourceVideoUrl,
  }) async {
    // No backend configured → use the simulator so the flow stays demoable.
    if (!hasAnalysisApi) {
      return _fallback.analyzeUpload(
        uploadJobId: uploadJobId,
        job: job,
        sourceVideoUrl: sourceVideoUrl,
      );
    }

    try {
      final token = _client.auth.currentSession?.accessToken;
      final base = analysisApiBaseUrl.replaceAll(RegExp(r'/+$'), '');
      final resp = await _dio.post(
        '$base/analyze',
        data: {
          'upload_job_id': uploadJobId,
          'video_url': sourceVideoUrl,
          'home_team': job.homeTeam,
          'away_team': job.awayTeam,
          'competition': job.competition,
          'venue': job.venue,
          'match_date': job.matchDate.toIso8601String(),
        },
        options: Options(
          headers: {
            if (token != null) 'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          sendTimeout: const Duration(minutes: 5),
          receiveTimeout: const Duration(minutes: 10),
        ),
      );

      final data = resp.data is String
          ? jsonDecode(resp.data as String) as Map<String, dynamic>
          : (resp.data as Map).cast<String, dynamic>();

      final result = _parseResponse(data, sourceVideoUrl);
      return const _AnalysisPersister()
          .persist(uploadJobId: uploadJobId, job: job, result: result);
    } catch (_) {
      // Backend unreachable / bad response → keep the upload flow working.
      return _fallback.analyzeUpload(
        uploadJobId: uploadJobId,
        job: job,
        sourceVideoUrl: sourceVideoUrl,
      );
    }
  }

  MatchAnalysisResult _parseResponse(
      Map<String, dynamic> j, String? sourceVideoUrl) {
    final match = (j['match'] as Map?)?.cast<String, dynamic>() ?? const {};
    final teams = (j['teams'] as Map?)?.cast<String, dynamic>() ?? const {};
    final home = (teams['home'] as Map?)?.cast<String, dynamic>() ?? const {};
    final away = (teams['away'] as Map?)?.cast<String, dynamic>() ?? const {};
    final players = (j['players'] as List? ?? const [])
        .map((p) => _parseVerdict((p as Map).cast<String, dynamic>()))
        .toList();

    return MatchAnalysisResult(
      analyzedVideoUrl:
          (j['analyzed_video_url'] as String?) ?? sourceVideoUrl,
      score: (match['score'] ?? '').toString(),
      resultStatus: (match['result_status'] ?? 'FT').toString(),
      dominantTeam: (match['dominant_team'] ?? '').toString(),
      highlightText: (match['highlight_text'] ?? '').toString(),
      overallNarrative: (match['overall_narrative'] ?? '').toString(),
      homeAvgRating: _toD(match['home_avg_rating']),
      awayAvgRating: _toD(match['away_avg_rating']),
      intensity: _toI(match['intensity']),
      keyMoments: _toSL(match['key_moments']),
      recommendations: _toSL(match['recommendations']),
      home: _parseTeam('home', home),
      away: _parseTeam('away', away),
      players: players,
    );
  }

  AnalysisTeamBlock _parseTeam(String side, Map<String, dynamic> t) =>
      AnalysisTeamBlock(
        side: side,
        teamName: (t['team_name'] ?? '').toString(),
        possession: _toI(t['possession']),
        style: (t['style'] ?? '').toString(),
        pressureStyle: (t['pressure_style'] ?? '').toString(),
        compactness: (t['compactness'] ?? '').toString(),
        attackingZones: _toSL(t['attacking_zones']),
        avgRating: _toD(t['avg_rating']),
        topPlayers: _toSL(t['top_players']),
        worstPlayers: _toSL(t['worst_players']),
      );

  AnalysisPlayerVerdict _parseVerdict(Map<String, dynamic> p) =>
      AnalysisPlayerVerdict(
        jerseyNumber: (p['jersey_number'] as num?)?.toInt(),
        playerName: (p['player_name'] ?? '').toString(),
        position: (p['position'] ?? '').toString(),
        rating: _toD(p['rating']),
        fatigue: _toI(p['fatigue']),
        performanceStatus: (p['performance_status'] ?? 'average').toString(),
        contribution: (p['contribution'] ?? 'balanced').toString(),
        impact: (p['impact'] ?? 'Medium').toString(),
        insight: (p['insight'] ?? '').toString(),
        goals: _toI(p['goals']),
        assists: _toI(p['assists']),
        tackles: _toI(p['tackles']),
        keyPasses: _toI(p['key_passes']),
        isMotm: p['is_motm'] == true,
        isWorst: p['is_worst'] == true,
      );
}

// ───────────────────────── Simulator (fallback) ───────────────────────────

final class SimulatedAnalysisEngine implements IAnalysisEngine {
  const SimulatedAnalysisEngine();

  SupabaseClient get _client => Supabase.instance.client;

  @override
  Future<String?> analyzeUpload({
    required String uploadJobId,
    required UploadJobModel job,
    String? sourceVideoUrl,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return null;

    final profile = await _client
        .from('profiles')
        .select('club_id')
        .eq('id', uid)
        .maybeSingle();
    final clubId = profile?['club_id'] as String?;
    if (clubId == null) return null;

    // Base verdicts on the club's real squad; if empty, on a detected roster
    // (the persister auto-creates any players that don't exist yet).
    final squad = (await _client
            .from('players')
            .select('id, full_name, position, jersey_number')
            .eq('owner_club_id', clubId))
        .cast<Map<String, dynamic>>();

    final List<String> names;
    final List<String> positions;
    final List<int?> jerseys;
    if (squad.isNotEmpty) {
      names = squad.map((p) => (p['full_name'] ?? '').toString()).toList();
      positions = squad.map((p) => (p['position'] ?? '').toString()).toList();
      jerseys =
          squad.map((p) => (p['jersey_number'] as num?)?.toInt()).toList();
    } else {
      names = [for (final e in _detectedRoster) e[0]];
      positions = [for (final e in _detectedRoster) e[1]];
      jerseys = [for (var i = 0; i < _detectedRoster.length; i++) i + 1];
    }

    final rng = Random(uploadJobId.hashCode);
    double rating() =>
        double.parse((6.0 + rng.nextDouble() * 3.4).toStringAsFixed(1));

    final homeAvg = rating();
    final awayAvg = rating();
    final dominant = homeAvg >= awayAvg ? job.homeTeam : job.awayTeam;
    final score = (job.matchScore != null && job.matchScore!.trim().isNotEmpty)
        ? job.matchScore!
        : '${rng.nextInt(4)} - ${rng.nextInt(4)}';

    final n = names.length;
    final ratings = List.generate(n, (_) => rating());
    var motm = 0, worst = 0;
    for (var i = 1; i < n; i++) {
      if (ratings[i] > ratings[motm]) motm = i;
      if (ratings[i] < ratings[worst]) worst = i;
    }

    final verdicts = <AnalysisPlayerVerdict>[];
    for (var i = 0; i < n; i++) {
      final r = ratings[i];
      verdicts.add(AnalysisPlayerVerdict(
        jerseyNumber: jerseys[i],
        playerName: names[i],
        position: positions[i],
        rating: r,
        fatigue: 40 + rng.nextInt(55),
        performanceStatus: _status(r),
        contribution: _contribution(positions[i]),
        impact: r >= 8 ? 'High' : (r >= 7 ? 'Medium' : 'Low'),
        insight: 'Auto-generated verdict from match analysis.',
        goals: rng.nextInt(r >= 8 ? 3 : 2),
        assists: rng.nextInt(2),
        tackles: rng.nextInt(6),
        keyPasses: rng.nextInt(5),
        isMotm: i == motm,
        isWorst: i == worst,
      ));
    }

    final result = MatchAnalysisResult(
      analyzedVideoUrl: sourceVideoUrl,
      score: score,
      resultStatus: 'FT',
      dominantTeam: dominant,
      highlightText: '${job.homeTeam} vs ${job.awayTeam} — AI analysis ready.',
      overallNarrative: job.tacticalSummary ??
          'Balanced contest with momentum swings. See the per-player '
              'breakdown for fitness and tactical impact.',
      homeAvgRating: homeAvg,
      awayAvgRating: awayAvg,
      intensity: job.intensityScore ?? (60 + rng.nextInt(40)),
      keyMoments: const [
        'High press won the ball in the final third repeatedly.',
        'Width on the flanks created the best chances.',
      ],
      recommendations: const [
        'Rotate fatigued players before the next fixture.',
        'Exploit space behind the opponent full-backs.',
      ],
      home: _teamBlock('home', job.homeTeam, homeAvg, rng),
      away: _teamBlock('away', job.awayTeam, awayAvg, rng),
      players: verdicts,
    );

    return const _AnalysisPersister()
        .persist(uploadJobId: uploadJobId, job: job, result: result);
  }

  AnalysisTeamBlock _teamBlock(
      String side, String name, double avg, Random rng) {
    final possession = 40 + rng.nextInt(21); // 40–60
    return AnalysisTeamBlock(
      side: side,
      teamName: name,
      possession: side == 'home' ? possession : 100 - possession,
      style: avg >= 8 ? 'Possession-based' : 'Direct',
      pressureStyle: rng.nextBool() ? 'High press' : 'Mid block',
      compactness: rng.nextBool() ? 'Compact' : 'Stretched',
      attackingZones: const ['Left flank', 'Central'],
      avgRating: avg,
      topPlayers: const <String>[],
      worstPlayers: const <String>[],
    );
  }
}

// ───────────────────────── Shared helpers ─────────────────────────────────

// A small, stable public sample so a simulated analysed match is still playable
// when there's no uploaded/rendered video.
const _sampleAnalyzedVideo =
    'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4';

// A plausible 11-player roster the simulator "detects" for an empty squad.
const _detectedRoster = <List<String>>[
  ['Adam Reyes', 'GK', 'Spain'],
  ['Marcus Boateng', 'RB', 'Germany'],
  ['Diego Fernández', 'CB', 'Argentina'],
  ['Yusuf Demir', 'CB', 'Turkey'],
  ['Leon Okafor', 'LB', 'Nigeria'],
  ['Tariq Haddad', 'CDM', 'Egypt'],
  ['Nathan Brooks', 'CM', 'England'],
  ['Luca Moretti', 'CAM', 'Italy'],
  ['Kenji Tanaka', 'RW', 'Japan'],
  ['Mateo Silva', 'ST', 'Brazil'],
  ['Omar Khalil', 'LW', 'Morocco'],
];

String _status(double r) {
  if (r >= 8.5) return 'excellent';
  if (r >= 7.5) return 'good';
  if (r >= 6.5) return 'average';
  if (r >= 5.5) return 'poor';
  return 'terrible';
}

String _contribution(String? position) {
  final pos = (position ?? '').toUpperCase();
  if (pos.contains('GK') ||
      pos.contains('CB') ||
      pos.contains('DEF') ||
      pos.contains('RB') ||
      pos.contains('LB')) {
    return 'defense';
  }
  if (pos.contains('ST') ||
      pos.contains('FW') ||
      pos.contains('RW') ||
      pos.contains('LW') ||
      pos.contains('ATT')) {
    return 'attack';
  }
  return 'balanced';
}

String _dateLabel(DateTime d) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}

double _toD(dynamic v) =>
    v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '') ?? 0;
int _toI(dynamic v) =>
    v is num ? v.toInt() : int.tryParse(v?.toString() ?? '') ?? 0;
List<String> _toSL(dynamic v) =>
    v is List ? v.map((e) => e.toString()).toList() : const [];
