import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../providers/app_providers.dart';
import '../../widgets/fan/player_intelligence_widgets.dart';

class PlayerProfileScreen extends ConsumerStatefulWidget {
  const PlayerProfileScreen({super.key, required this.playerId});

  final String playerId;

  @override
  ConsumerState<PlayerProfileScreen> createState() =>
      _PlayerProfileScreenState();
}

class _PlayerProfileScreenState extends ConsumerState<PlayerProfileScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<Animation<double>> _fades;
  late final List<Animation<Offset>> _slides;

  // Hero + 10 content sections
  static const int _sectionCount = 11;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600))
      ..forward();

    _fades = List.generate(_sectionCount, (i) {
      final start = (i * 0.08).clamp(0.0, 0.85);
      final end = (start + 0.22).clamp(0.0, 1.0);
      return CurvedAnimation(
          parent: _ctrl,
          curve: Interval(start, end, curve: Curves.easeOutCubic));
    });

    _slides = _fades
        .map((f) =>
            Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
                .animate(f))
        .toList();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Widget _section(int idx, Widget child) => FadeTransition(
        opacity: _fades[idx],
        child: SlideTransition(position: _slides[idx], child: child),
      );

  @override
  Widget build(BuildContext context) {
    final teamMembers = ref.watch(teamMembersProvider);
    final matches = teamMembers.where((m) => m.id == widget.playerId);
    final player = matches.isEmpty ? null : matches.first;

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context, player?.name ?? 'Player Profile'),
      body: player == null
          ? _buildNotFound(context)
          : _buildContent(context, player),
    );
  }

  // ── Not Found ─────────────────────────────────────────────────────────────

  Widget _buildNotFound(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.surfaceElevated, AppColors.background],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_off_rounded,
                color: AppColors.textMuted,
                size: context.rs(56, min: 44, max: 68)),
            SizedBox(height: context.rs(14, min: 10, max: 18)),
            Text('Player Not Found',
                style: AppTextStyles.title(color: AppColors.textPrimary)
                    .copyWith(fontSize: context.rs(18, min: 15, max: 22))),
            SizedBox(height: context.rs(8, min: 6, max: 10)),
            Text('The requested player could not be located.',
                style: AppTextStyles.body(color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }

  // ── Main Content ──────────────────────────────────────────────────────────

  Widget _buildContent(BuildContext context, dynamic player) {
    final h = context.rs(16, min: 12, max: 20);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── 0. Hero Header (no top padding — fills behind AppBar) ────────
          _section(0, PlayerHeroHeader(player: player)),

          Padding(
            padding: EdgeInsets.fromLTRB(h, 0, h, context.rs(48, min: 36, max: 64)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: h),

                // ── 1. Rating Progression ──────────────────────────────────
                _section(1, RatingProgressionCard(player: player)),
                SizedBox(height: h),

                // ── 2. Speed & Distance ────────────────────────────────────
                _section(2, SpeedDistanceCard(player: player)),
                SizedBox(height: h),

                // ── 3. Fatigue & Workload ──────────────────────────────────
                _section(3, FatigueWorkloadCard(player: player)),
                SizedBox(height: h),

                // ── 4. Consistency & Tactical Contribution ─────────────────
                _section(4, ConsistencyTacticalCard(player: player)),
                SizedBox(height: h),

                // ── 5. Strengths & Weaknesses ──────────────────────────────
                _section(5, PlayerStrengthsWeaknessesCard(player: player)),
                SizedBox(height: h),

                // ── 6. AI Insights ─────────────────────────────────────────
                _section(6, PlayerAIInsightsCard(player: player)),
                SizedBox(height: h),

                // ── 7. Match History ───────────────────────────────────────
                _section(7, MatchHistoryCard(player: player)),
                SizedBox(height: h),

                // ── 8. Risk Dashboard ──────────────────────────────────────
                _section(8, PlayerRiskCard(player: player)),
                SizedBox(height: h),

                // ── 9. Season Intelligence Summary ─────────────────────────
                _section(9, SeasonIntelligenceCard(player: player)),
                SizedBox(height: h),

                // ── 10. Position Badge ─────────────────────────────────────
                _section(10, _PositionBadgeCard(player: player)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(BuildContext context, String title) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      titleSpacing: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.outlineSubtle),
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: AppColors.textPrimary, size: 18),
                onPressed: () => context.pop(),
              ),
            ),
          ),
        ),
      ),
      title: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.outlineSubtle),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.person_rounded,
                    color: AppColors.accentCyan, size: 15),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    title,
                    style: AppTextStyles.body(color: AppColors.textPrimary)
                        .copyWith(fontWeight: FontWeight.w700, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.outlineSubtle),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.auto_awesome_rounded,
                        color: AppColors.primaryPurple, size: 14),
                    const SizedBox(width: 5),
                    Text('AI INTEL',
                        style: AppTextStyles.caption(
                                color: AppColors.primaryPurple)
                            .copyWith(fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Position Badge Card ──────────────────────────────────────────────────────

class _PositionBadgeCard extends StatelessWidget {
  const _PositionBadgeCard({required this.player});
  final dynamic player;

  String _positionDescription(String position) {
    switch (position) {
      case 'GK':
        return 'The last line of defence. Commands the penalty area, organises the backline, and distributes precisely to initiate attacks.';
      case 'CB':
        return 'Anchors the defensive shape. Reads the game to intercept, wins aerial duels, and plays out confidently from the back.';
      case 'LB':
      case 'RB':
        return 'Dynamic fullback who provides width in attack via overlapping runs while maintaining defensive discipline in transition.';
      case 'DM':
        return 'The defensive shield in front of the back four. Breaks up opposition plays, recycles possession, and controls the tempo.';
      case 'CM':
        return 'The engine of the midfield. Box-to-box energy, progressive passing, and an ability to contribute both defensively and offensively.';
      case 'CAM':
      case 'AM':
        return 'The creative hub operating in pockets of space. Unlocks defences with incisive passes and threatening runs in the final third.';
      case 'LW':
      case 'RW':
        return 'Explosive wide attacker who stretches defences, beats markers in 1v1 situations, and delivers quality into the box.';
      case 'ST':
      case 'CF':
        return 'The focal point of the attack. Clinical in front of goal, holds up play effectively, and creates space for teammates.';
      default:
        return 'A versatile player who contributes across multiple phases of play with technical quality and tactical intelligence.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final String position = player.position as String;
    return Container(
      padding: EdgeInsets.all(context.rs(16, min: 12, max: 20)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryBlue.withValues(alpha: 0.08),
            AppColors.surfaceElevated,
          ],
        ),
        borderRadius: AppRadius.cardLarge,
        border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: context.rs(54, min: 44, max: 64),
            height: context.rs(54, min: 44, max: 64),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryBlue.withValues(alpha: 0.25),
                  AppColors.accentCyan.withValues(alpha: 0.1),
                ],
              ),
              border: Border.all(
                  color: AppColors.primaryBlue.withValues(alpha: 0.4)),
            ),
            child: Center(
              child: Text(
                position,
                style: AppTextStyles.title(color: AppColors.accentCyan)
                    .copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: context.rs(14, min: 11, max: 16)),
              ),
            ),
          ),
          SizedBox(width: context.rs(14, min: 10, max: 18)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Role Profile',
                    style: AppTextStyles.body(color: AppColors.textPrimary)
                        .copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: context.rs(14, min: 12, max: 16))),
                const SizedBox(height: 4),
                Text(
                  _positionDescription(position),
                  style: AppTextStyles.caption(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

