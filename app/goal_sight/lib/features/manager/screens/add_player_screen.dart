// ---------------------------------------------------------------------------
// GoalSight — Add Player Screen
//
// Manager fills in player name, position, and optional jersey number.
// Calls SupabasePlayerRepository.createPlayer() then pops with the new player.
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/haptic_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../providers/manager_players_provider.dart';
import '../../../providers/repository_providers.dart';

const _positions = [
  'GK',
  'CB', 'LB', 'RB', 'LWB', 'RWB',
  'CDM', 'CM', 'CAM', 'DM',
  'LW', 'RW', 'CF', 'ST',
];

class AddPlayerScreen extends ConsumerStatefulWidget {
  const AddPlayerScreen({super.key});

  @override
  ConsumerState<AddPlayerScreen> createState() => _AddPlayerScreenState();
}

class _AddPlayerScreenState extends ConsumerState<AddPlayerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late List<Animation<double>> _fades;
  late List<Animation<Offset>> _slides;

  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _jerseyCtrl = TextEditingController();

  String _selectedPosition = 'ST';
  bool _saving = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _fades = List.generate(4, (i) {
      final start = (i * 0.18).clamp(0.0, 0.7);
      final end = (start + 0.3).clamp(0.0, 1.0);
      return CurvedAnimation(
        parent: _ctrl,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      );
    });
    _slides = _fades
        .map((f) =>
            Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
                .animate(f))
        .toList();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _nameCtrl.dispose();
    _jerseyCtrl.dispose();
    super.dispose();
  }

  Widget _reveal(int i, Widget child) => FadeTransition(
        opacity: _fades[i],
        child: SlideTransition(position: _slides[i], child: child),
      );

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final clubId = ref.read(managerClubIdProvider);
    if (clubId == null || clubId.isEmpty) {
      setState(() => _errorMsg = 'Could not determine your club. Please log in again.');
      return;
    }

    setState(() {
      _saving = true;
      _errorMsg = null;
    });
    HapticService.medium();

    try {
      final repo = ref.read(playerRepositoryProvider);
      final player = await repo.createPlayer(
        fullName: _nameCtrl.text.trim(),
        position: _selectedPosition,
        clubId: clubId,
        jerseyNumber: _jerseyCtrl.text.isNotEmpty
            ? int.tryParse(_jerseyCtrl.text.trim())
            : null,
      );

      // Invalidate the players cache so the list refreshes on pop.
      ref.invalidate(managerPlayersProvider);

      HapticService.success();
      if (mounted) {
        context.pop(player);
      }
    } catch (e) {
      HapticService.error();
      setState(() {
        _saving = false;
        _errorMsg = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hPad = context.rs(20, min: 16, max: 28);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ───────────────────────────────────────────────────
            _reveal(
              0,
              Padding(
                padding: EdgeInsets.fromLTRB(
                    hPad, context.rs(20, min: 16, max: 28), hPad, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        HapticService.selection();
                        context.pop();
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: AppColors.outlineSubtle),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: AppColors.textSecondary, size: 16),
                      ),
                    ),
                    SizedBox(width: context.rs(16, min: 12, max: 20)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add Player',
                            style: AppTextStyles.headline(
                                    color: AppColors.textPrimary)
                                .copyWith(
                                    fontSize: context.rs(24, min: 20, max: 28)),
                          ),
                          Text(
                            'New squad member',
                            style: AppTextStyles.caption(
                                color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    // Save button in header
                    GestureDetector(
                      onTap: _saving ? null : _save,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(
                          gradient:
                              _saving ? null : AppGradients.brand,
                          color: _saving
                              ? AppColors.surfaceElevated
                              : null,
                          borderRadius: AppRadius.button,
                          boxShadow:
                              _saving ? null : AppShadows.buttonGlow,
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.textMuted,
                                ),
                              )
                            : Text(
                                'Save',
                                style: AppTextStyles.button(
                                        color: Colors.white)
                                    .copyWith(fontSize: 14),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: context.rs(24, min: 20, max: 32)),

            // ── Form ─────────────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: hPad),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Error box
                      if (_errorMsg != null) ...[
                        _reveal(
                          0,
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.danger.withValues(alpha: 0.08),
                              borderRadius: AppRadius.card,
                              border: Border.all(
                                  color:
                                      AppColors.danger.withValues(alpha: 0.35)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline,
                                    color: AppColors.danger, size: 18),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _errorMsg!,
                                    style: AppTextStyles.body(
                                        color: AppColors.danger),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: context.rs(16, min: 12, max: 20)),
                      ],

                      // Full Name
                      _reveal(
                        1,
                        _FieldLabel(label: 'Full Name', required: true),
                      ),
                      SizedBox(height: context.rs(8, min: 6, max: 10)),
                      _reveal(
                        1,
                        TextFormField(
                          controller: _nameCtrl,
                          style:
                              AppTextStyles.body(color: AppColors.textPrimary),
                          decoration: _inputDecoration(
                            hint: 'e.g. Mohamed Salah',
                            icon: Icons.person_outline_rounded,
                          ),
                          textCapitalization: TextCapitalization.words,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Player name is required';
                            }
                            if (v.trim().length < 2) {
                              return 'Name must be at least 2 characters';
                            }
                            return null;
                          },
                        ),
                      ),

                      SizedBox(height: context.rs(20, min: 16, max: 24)),

                      // Position
                      _reveal(
                        2,
                        _FieldLabel(label: 'Position', required: true),
                      ),
                      SizedBox(height: context.rs(8, min: 6, max: 10)),
                      _reveal(
                        2,
                        _PositionPicker(
                          selected: _selectedPosition,
                          onSelect: (pos) =>
                              setState(() => _selectedPosition = pos),
                        ),
                      ),

                      SizedBox(height: context.rs(20, min: 16, max: 24)),

                      // Jersey Number (optional)
                      _reveal(
                        3,
                        _FieldLabel(label: 'Jersey Number', required: false),
                      ),
                      SizedBox(height: context.rs(8, min: 6, max: 10)),
                      _reveal(
                        3,
                        TextFormField(
                          controller: _jerseyCtrl,
                          style:
                              AppTextStyles.body(color: AppColors.textPrimary),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(2),
                          ],
                          decoration: _inputDecoration(
                            hint: 'Optional (1–99)',
                            icon: Icons.tag_rounded,
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return null;
                            final n = int.tryParse(v);
                            if (n == null || n < 1 || n > 99) {
                              return 'Enter a number between 1 and 99';
                            }
                            return null;
                          },
                        ),
                      ),

                      SizedBox(height: context.rs(40, min: 32, max: 56)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.body(color: AppColors.textMuted),
      prefixIcon: Icon(icon, color: AppColors.textMuted, size: 18),
      filled: true,
      fillColor: AppColors.surfaceElevated,
      border: OutlineInputBorder(
        borderRadius: AppRadius.input,
        borderSide: const BorderSide(color: AppColors.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.input,
        borderSide: BorderSide(color: AppColors.outlineSubtle),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.input,
        borderSide:
            const BorderSide(color: AppColors.primaryPurple, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppRadius.input,
        borderSide:
            BorderSide(color: AppColors.danger.withValues(alpha: 0.6)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: AppRadius.input,
        borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
      ),
      errorStyle: AppTextStyles.caption(color: AppColors.danger)
          .copyWith(fontSize: 11),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}

// ─── Field Label ──────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String label;
  final bool required;
  const _FieldLabel({required this.label, required this.required});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: AppTextStyles.body(color: AppColors.textSecondary)
              .copyWith(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        if (required) ...[
          const SizedBox(width: 4),
          Text('*',
              style: AppTextStyles.caption(color: AppColors.danger)
                  .copyWith(fontSize: 13)),
        ],
      ],
    );
  }
}

// ─── Position Picker ──────────────────────────────────────────────────────────

class _PositionPicker extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;
  const _PositionPicker({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _positions.map((pos) {
        final isSelected = selected == pos;
        return GestureDetector(
          onTap: () {
            HapticService.selection();
            onSelect(pos);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: isSelected ? AppGradients.brand : null,
              color: isSelected ? null : AppColors.surfaceElevated,
              borderRadius: AppRadius.chip,
              border: Border.all(
                color: isSelected
                    ? Colors.transparent
                    : AppColors.outlineSubtle,
              ),
              boxShadow: isSelected ? AppShadows.buttonGlow : null,
            ),
            child: Text(
              pos,
              style: AppTextStyles.button(
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ).copyWith(fontSize: 13),
            ),
          ),
        );
      }).toList(),
    );
  }
}
