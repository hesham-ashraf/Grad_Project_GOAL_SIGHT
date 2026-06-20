// ---------------------------------------------------------------------------
// GoalSight — Player Naming Screen (mandatory human-in-the-loop step)
//
// Shown after the model detects players (Stage 1). The manager:
//   1) picks which DETECTED team (0/1) is their own club,
//   2) names the detected players (optionally assigning an existing squad
//      player from suggestions, which links a real player_id).
// Returns a [NamingResult] (mappings + my_team_id) the upload flow submits to
// POST /jobs/{id}/players to resume the full pipeline.
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../data/models/analysis_job_model.dart';
import '../../../data/models/player_profile_model.dart';
import '../../../providers/manager_players_provider.dart';

class NamingResult {
  const NamingResult({required this.mappings, required this.myTeamId});
  final List<PlayerNameMapping> mappings;
  final int myTeamId;
}

class PlayerNamingScreen extends ConsumerStatefulWidget {
  const PlayerNamingScreen({super.key, required this.data});

  final NamingData data;

  @override
  ConsumerState<PlayerNamingScreen> createState() => _PlayerNamingScreenState();
}

class _PlayerNamingScreenState extends ConsumerState<PlayerNamingScreen> {
  final Map<int, TextEditingController> _controllers = {};
  final Map<int, String?> _playerIds = {}; // track_id -> existing squad player id
  int? _myTeamId;
  bool _squadAutoMatched = false; // run the jersey→squad link only once

  /// Link detected players to squad members by shirt number — once, after the
  /// squad loads. Only fills tracks the manager hasn't already named/linked, so
  /// it never overwrites manual edits. A no-op when jerseys weren't detected.
  void _applySquadAutoMatch(List<PlayerProfileModel> squad) {
    if (_squadAutoMatched || squad.isEmpty) return;
    _squadAutoMatched = true;
    for (final p in widget.data.players) {
      final jersey = p.jerseyNumber;
      if (jersey == null) continue;
      final ctrl = _controllers[p.trackId];
      if (ctrl == null || ctrl.text.trim().isNotEmpty) continue; // keep manual
      final match = squad.where((s) => s.jerseyNumber?.toString() == jersey);
      if (match.isEmpty) continue;
      ctrl.text = match.first.name;
      _playerIds[p.trackId] = match.first.id;
    }
  }

  @override
  void initState() {
    super.initState();
    for (final p in widget.data.players) {
      _controllers[p.trackId] = TextEditingController(
        text: (p.suggestedName != null &&
                !p.suggestedName!.toLowerCase().startsWith('player '))
            ? p.suggestedName
            : '',
      );
    }
    // Default the team selector to the first team that has players.
    final teams = widget.data.players
        .map((p) => p.teamId)
        .whereType<int>()
        .toSet()
        .toList()
      ..sort();
    if (teams.isNotEmpty) _myTeamId = teams.first;
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  List<DetectedPlayer> _playersForTeam(int? team) => widget.data.players
      .where((p) => p.teamId == team)
      .toList()
    ..sort((a, b) => b.trackLength.compareTo(a.trackLength));

  void _confirm() {
    if (_myTeamId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Select which team is your club first.'),
      ));
      return;
    }
    final mappings = <PlayerNameMapping>[];
    for (final p in widget.data.players) {
      final name = _controllers[p.trackId]!.text.trim();
      if (name.isEmpty) continue; // leave unnamed tracks out (no auto-naming)
      mappings.add(PlayerNameMapping(
        trackId: p.trackId,
        playerName: name,
        playerId: _playerIds[p.trackId],
      ));
    }
    Navigator.of(context).pop(
      NamingResult(mappings: mappings, myTeamId: _myTeamId!),
    );
  }

  @override
  Widget build(BuildContext context) {
    final squadAsync = ref.watch(managerPlayersProvider);
    final squad = squadAsync.asData?.value ?? const <PlayerProfileModel>[];
    _applySquadAutoMatch(squad);
    final teamIds = widget.data.teamLegend.map((e) => e.teamId).toList()..sort();
    final myPlayers = _playersForTeam(_myTeamId);
    final otherPlayers = widget.data.players
        .where((p) => p.teamId != _myTeamId)
        .toList()
      ..sort((a, b) => b.trackLength.compareTo(a.trackLength));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Name Your Players'),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(context.rs(16), 8, context.rs(16), 24),
                children: [
                  Text(
                    'The AI detected these players. Pick your club, then name '
                    'them. Named players on your team join your squad.',
                    style: AppTextStyles.body(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  _TeamPicker(
                    legend: widget.data.teamLegend,
                    teamIds: teamIds.isEmpty ? const [0, 1] : teamIds,
                    selected: _myTeamId,
                    onSelect: (t) => setState(() => _myTeamId = t),
                  ),
                  const SizedBox(height: 20),
                  if (myPlayers.isNotEmpty) ...[
                    const _SectionLabel('My Club', AppColors.accentCyan),
                    ...myPlayers.map((p) => _playerCard(p, squad, mine: true)),
                    const SizedBox(height: 12),
                  ],
                  if (otherPlayers.isNotEmpty) ...[
                    const _SectionLabel('Opponent / Others', AppColors.textMuted),
                    ...otherPlayers.map((p) => _playerCard(p, squad, mine: false)),
                  ],
                ],
              ),
            ),
            _ConfirmBar(
              count: widget.data.players.length,
              enabled: _myTeamId != null,
              onConfirm: _confirm,
            ),
          ],
        ),
      ),
    );
  }

  Widget _playerCard(DetectedPlayer p, List<PlayerProfileModel> squad,
      {required bool mine}) {
    final ctrl = _controllers[p.trackId]!;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.outlineSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Multi-frame verification gallery: swipe the strip, tap to expand
          // (pinch-zoom). More frames = easier to confirm the same player.
          _PlayerFramesGallery(player: p),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PlayerIdentityLine(player: p),
                    const SizedBox(height: 6),
                    TextField(
                      controller: ctrl,
                      textInputAction: TextInputAction.next,
                      style: AppTextStyles.body(color: AppColors.textPrimary),
                      onChanged: (_) {
                        if (_playerIds[p.trackId] != null) {
                          setState(() => _playerIds[p.trackId] = null);
                        }
                      },
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'Player name (optional)',
                        hintStyle: AppTextStyles.body(color: AppColors.textMuted),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Pick from the club's existing squad → guarantees the exact name
          // and links the real player_id (so this match's analysis attaches to
          // that player's profile). Free typing stays available above.
          if (mine && squad.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () => _pickFromSquad(p, squad),
                  icon: const Icon(Icons.groups_rounded, size: 16),
                  label: Text(
                    _playerIds[p.trackId] != null
                        ? 'Linked to squad ✓'
                        : 'Select from squad',
                    style: AppTextStyles.caption(
                      color: _playerIds[p.trackId] != null
                          ? AppColors.accentGreen
                          : AppColors.textSecondary,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    side: BorderSide(
                      color: _playerIds[p.trackId] != null
                          ? AppColors.accentGreen
                          : AppColors.outlineSubtle,
                    ),
                    shape: const RoundedRectangleBorder(
                        borderRadius: AppRadius.chip),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickFromSquad(
      DetectedPlayer p, List<PlayerProfileModel> squad) async {
    final chosen = await showModalBottomSheet<PlayerProfileModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _SquadPickerSheet(squad: squad),
    );
    if (chosen != null && mounted) {
      setState(() {
        _controllers[p.trackId]!.text = chosen.name;
        _playerIds[p.trackId] = chosen.id;
      });
    }
  }
}

/// Searchable list of the club's existing players — pick one to link it.
class _SquadPickerSheet extends StatefulWidget {
  const _SquadPickerSheet({required this.squad});
  final List<PlayerProfileModel> squad;

  @override
  State<_SquadPickerSheet> createState() => _SquadPickerSheetState();
}

class _SquadPickerSheetState extends State<_SquadPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? widget.squad
        : widget.squad
            .where((s) => s.name.toLowerCase().contains(q))
            .toList();
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 14,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Select a squad player',
              style: AppTextStyles.title(color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          TextField(
            autofocus: true,
            onChanged: (v) => setState(() => _query = v),
            style: AppTextStyles.body(color: AppColors.textPrimary),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search, color: AppColors.textMuted),
              hintText: 'Search players…',
            ),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.45),
            child: filtered.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text('No matching players.',
                        style:
                            AppTextStyles.body(color: AppColors.textMuted)),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final s = filtered[i];
                      return ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: AppColors.surfaceRaised,
                          child: Icon(Icons.person,
                              color: AppColors.textSecondary, size: 18),
                        ),
                        title: Text(s.name,
                            style: AppTextStyles.body(
                                color: AppColors.textPrimary)),
                        subtitle: Text(s.position,
                            style: AppTextStyles.caption(
                                color: AppColors.textMuted)),
                        onTap: () => Navigator.of(context).pop(s),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _TeamPicker extends StatelessWidget {
  const _TeamPicker({
    required this.legend,
    required this.teamIds,
    required this.selected,
    required this.onSelect,
  });

  final List<TeamLegendEntry> legend;
  final List<int> teamIds;
  final int? selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Which team is YOUR club?',
                style: AppTextStyles.title(color: AppColors.textPrimary)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.14),
                borderRadius: AppRadius.chip,
              ),
              child: Text('Required',
                  style: AppTextStyles.caption(color: AppColors.warning)
                      .copyWith(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'This decides which side owns the analytics, fatigue, risks and '
          'recommendations.',
          style: AppTextStyles.caption(color: AppColors.textMuted),
        ),
        const SizedBox(height: 12),
        Row(
          children: teamIds.map((t) {
            final entry = legend.firstWhere(
              (e) => e.teamId == t,
              orElse: () => TeamLegendEntry(teamId: t, label: 'Team $t'),
            );
            final isSel = selected == t;
            final color = entry.colorRgb.length == 3
                ? Color.fromARGB(255, entry.colorRgb[0], entry.colorRgb[1],
                    entry.colorRgb[2])
                : AppColors.primaryBlue;
            return Expanded(
              child: GestureDetector(
                onTap: () => onSelect(t),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  margin: EdgeInsets.only(right: t == teamIds.last ? 0 : 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: isSel
                        ? LinearGradient(
                            colors: [
                              AppColors.primaryPurple.withValues(alpha: 0.28),
                              AppColors.primaryBlue.withValues(alpha: 0.12),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isSel ? null : AppColors.surfaceElevated,
                    borderRadius: AppRadius.card,
                    border: Border.all(
                      color: isSel
                          ? AppColors.primaryPurple
                          : AppColors.outlineSubtle,
                      width: isSel ? 1.8 : 1,
                    ),
                    boxShadow: isSel
                        ? [
                            BoxShadow(
                              color:
                                  AppColors.primaryPurple.withValues(alpha: 0.3),
                              blurRadius: 16,
                              spreadRadius: -2,
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    children: [
                      AnimatedScale(
                        scale: isSel ? 1.12 : 1,
                        duration: const Duration(milliseconds: 240),
                        curve: Curves.easeOutBack,
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSel ? Colors.white : Colors.white24,
                              width: isSel ? 2 : 1,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          entry.label.isEmpty ? 'Team $t' : entry.label,
                          style: AppTextStyles.body(
                            color: isSel
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                          ).copyWith(
                            fontWeight:
                                isSel ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder: (c, a) =>
                            ScaleTransition(scale: a, child: c),
                        child: isSel
                            ? const Icon(Icons.check_circle,
                                key: ValueKey('sel'),
                                color: AppColors.primaryPurple,
                                size: 20)
                            : const SizedBox(
                                key: ValueKey('unsel'), width: 20),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// HTTP header that keeps ngrok from injecting its browser-warning HTML in
/// place of the actual image bytes.
const _kImageHeaders = {'ngrok-skip-browser-warning': 'true'};

Widget _frameFallback(String role, {double w = 52, double h = 64}) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        role == 'goalkeeper' ? Icons.sports_handball : Icons.person,
        color: AppColors.textMuted,
      ),
    );

/// Horizontal, swipeable strip of every extracted frame for one track. Tapping
/// any frame opens a full-screen, pinch-zoomable viewer that swipes between
/// frames — so the manager can verify identity from multiple angles.
class _PlayerFramesGallery extends StatelessWidget {
  const _PlayerFramesGallery({required this.player});
  final DetectedPlayer player;

  @override
  Widget build(BuildContext context) {
    final urls = player.galleryUrls;
    if (urls.isEmpty) return _frameFallback(player.autoRole);

    return SizedBox(
      height: 64,
      child: Row(
        children: [
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: urls.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => GestureDetector(
                onTap: () => Navigator.of(context).push(
                  PageRouteBuilder(
                    opaque: false,
                    barrierColor: Colors.black87,
                    pageBuilder: (_, __, ___) => _FramesViewerPage(
                      urls: urls,
                      initialIndex: i,
                      trackId: player.trackId,
                    ),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    urls[i],
                    width: 52,
                    height: 64,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.high,
                    headers: _kImageHeaders,
                    errorBuilder: (_, __, ___) =>
                        _frameFallback(player.autoRole),
                  ),
                ),
              ),
            ),
          ),
          if (urls.length > 1) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: const BoxDecoration(
                color: AppColors.surfaceRaised,
                borderRadius: AppRadius.chip,
              ),
              child: Row(
                children: [
                  const Icon(Icons.photo_library_outlined,
                      size: 13, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text('${urls.length}',
                      style: AppTextStyles.caption(color: AppColors.textMuted)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Full-screen pinch-zoom viewer that swipes between a track's frames.
class _FramesViewerPage extends StatefulWidget {
  const _FramesViewerPage({
    required this.urls,
    required this.initialIndex,
    required this.trackId,
  });
  final List<String> urls;
  final int initialIndex;
  final int trackId;

  @override
  State<_FramesViewerPage> createState() => _FramesViewerPageState();
}

class _FramesViewerPageState extends State<_FramesViewerPage> {
  late final PageController _page = PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          PageView.builder(
            controller: _page,
            itemCount: widget.urls.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (_, i) => Center(
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 5,
                child: Image.network(
                  widget.urls[i],
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  headers: _kImageHeaders,
                  errorBuilder: (_, __, ___) => const Icon(
                      Icons.broken_image_outlined,
                      color: Colors.white38,
                      size: 48),
                ),
              ),
            ),
          ),
          // Top bar: track id + frame counter + close.
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12,
            right: 12,
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: AppRadius.chip,
                  ),
                  child: Text(
                    'Track #${widget.trackId}  ·  ${_index + 1}/${widget.urls.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Identity line on each card: a prominent jersey-number pill (the most
/// reliable identifier from broadcast footage) when the model read one, plus
/// the role and the internal track id (kept small — it is NOT the shirt number).
class _PlayerIdentityLine extends StatelessWidget {
  const _PlayerIdentityLine({required this.player});
  final DetectedPlayer player;

  @override
  Widget build(BuildContext context) {
    final jersey = player.jerseyNumber;
    return Row(
      children: [
        if (jersey != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.18),
              borderRadius: AppRadius.chip,
              border: Border.all(
                  color: AppColors.primaryBlue.withValues(alpha: 0.55)),
            ),
            child: Text('#$jersey',
                style: AppTextStyles.body(color: AppColors.textPrimary)
                    .copyWith(fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 8),
        ],
        Text(player.autoRole,
            style: AppTextStyles.caption(color: AppColors.textSecondary)),
        const SizedBox(width: 8),
        Text('Track ${player.trackId}',
            style: AppTextStyles.caption(color: AppColors.textMuted)),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, this.color);
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10, top: 4),
        child: Text(text.toUpperCase(),
            style: AppTextStyles.caption(color: color)
                .copyWith(letterSpacing: 1.1, fontWeight: FontWeight.w700)),
      );
}

class _ConfirmBar extends StatelessWidget {
  const _ConfirmBar({
    required this.count,
    required this.enabled,
    required this.onConfirm,
  });
  final int count;
  final bool enabled;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.outlineSubtle)),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: enabled ? onConfirm : null,
          icon: const Icon(Icons.play_arrow_rounded),
          label: Text('Confirm Players & Analyze ($count detected)'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryPurple,
            foregroundColor: Colors.white,
            disabledBackgroundColor:
                AppColors.primaryPurple.withValues(alpha: 0.35),
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape:
                const RoundedRectangleBorder(borderRadius: AppRadius.button),
          ),
        ),
      ),
    );
  }
}
