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
          Row(
            children: [
              _CropAvatar(url: p.cropUrl, role: p.autoRole),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('#${p.trackId} · ${p.autoRole}',
                        style: AppTextStyles.caption(color: AppColors.textMuted)),
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
        Text('Which team is YOUR club?',
            style: AppTextStyles.title(color: AppColors.textPrimary)),
        const SizedBox(height: 10),
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
                child: Container(
                  margin: EdgeInsets.only(right: t == teamIds.first ? 10 : 0),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isSel
                        ? AppColors.primaryPurple.withValues(alpha: 0.18)
                        : AppColors.surfaceElevated,
                    borderRadius: AppRadius.card,
                    border: Border.all(
                      color: isSel
                          ? AppColors.primaryPurple
                          : AppColors.outlineSubtle,
                      width: isSel ? 1.6 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white24),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          entry.label.isEmpty ? 'Team $t' : entry.label,
                          style: AppTextStyles.body(color: AppColors.textPrimary),
                        ),
                      ),
                      if (isSel)
                        const Icon(Icons.check_circle,
                            color: AppColors.primaryPurple, size: 20),
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

class _CropAvatar extends StatelessWidget {
  const _CropAvatar({required this.url, required this.role});
  final String? url;
  final String role;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: 52,
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        role == 'goalkeeper' ? Icons.sports_handball : Icons.person,
        color: AppColors.textMuted,
      ),
    );
    if (url == null || !url!.startsWith('http')) return fallback;
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(
        url!,
        width: 52,
        height: 64,
        fit: BoxFit.cover,
        headers: const {'ngrok-skip-browser-warning': 'true'},
        errorBuilder: (_, __, ___) => fallback,
      ),
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
