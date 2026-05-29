import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';

// ─── Form Data Model ──────────────────────────────────────────────────────────

class UploadFormData {
  UploadFormData({
    this.fileName,
    this.fileSize,
    this.homeTeam = '',
    this.awayTeam = '',
    this.competition = '',
    this.venue = '',
    this.notes = '',
    DateTime? matchDate,
  }) : matchDate = matchDate ?? DateTime.now();

  final String? fileName;
  final String? fileSize;
  final String homeTeam;
  final String awayTeam;
  final String competition;
  final String venue;
  final String notes;
  final DateTime matchDate;

  UploadFormData copyWith({
    String? fileName,
    String? fileSize,
    String? homeTeam,
    String? awayTeam,
    String? competition,
    String? venue,
    String? notes,
    DateTime? matchDate,
  }) {
    return UploadFormData(
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      homeTeam: homeTeam ?? this.homeTeam,
      awayTeam: awayTeam ?? this.awayTeam,
      competition: competition ?? this.competition,
      venue: venue ?? this.venue,
      notes: notes ?? this.notes,
      matchDate: matchDate ?? this.matchDate,
    );
  }

  bool get isTeamFormValid =>
      homeTeam.trim().isNotEmpty && awayTeam.trim().isNotEmpty;

  bool get isMetadataFormValid =>
      competition.trim().isNotEmpty && venue.trim().isNotEmpty;
}

// ─── Upload Drop Zone ─────────────────────────────────────────────────────────

class UploadDropZone extends StatefulWidget {
  const UploadDropZone({
    super.key,
    required this.onSelectFile,
  });

  final VoidCallback onSelectFile;

  @override
  State<UploadDropZone> createState() => _UploadDropZoneState();
}

class _UploadDropZoneState extends State<UploadDropZone>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Text(
          'Upload Match Footage',
          style: AppTextStyles.headline().copyWith(
            fontSize: context.sp(26, min: 20, max: 32),
          ),
        ),
        SizedBox(height: context.rs(6, min: 4, max: 8)),
        Text(
          'Upload your match video and our AI will generate a complete tactical analysis in minutes.',
          style: AppTextStyles.body(color: AppColors.textSecondary),
        ),
        SizedBox(height: context.rs(28, min: 20, max: 36)),

        // Drop zone card
        MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: GestureDetector(
            onTap: widget.onSelectFile,
            child: AnimatedBuilder(
              animation: _pulseAnim,
              builder: (context, child) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    vertical: context.rs(48, min: 36, max: 60),
                    horizontal: context.rs(24, min: 16, max: 32),
                  ),
                  decoration: BoxDecoration(
                    borderRadius: AppRadius.cardLarge,
                    color: _isHovered
                        ? AppColors.surfaceRaised
                        : AppColors.surfaceElevated,
                    border: Border.all(
                      color: AppColors.accentCyan.withValues(
                        alpha: _isHovered ? 0.8 : _pulseAnim.value * 0.45,
                      ),
                      width: _isHovered ? 2.0 : 1.5,
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.surfaceElevated,
                        AppColors.primaryPurple.withValues(alpha: 0.08),
                      ],
                    ),
                    boxShadow: _isHovered
                        ? [
                            BoxShadow(
                              color: AppColors.accentCyan.withValues(alpha: 0.12),
                              blurRadius: 32,
                              offset: const Offset(0, 8),
                            )
                          ]
                        : AppShadows.card,
                  ),
                  child: Column(
                    children: [
                      // Animated icon
                      _AnimatedUploadIcon(
                        pulseValue: _pulseAnim.value,
                        isHovered: _isHovered,
                      ),
                      SizedBox(height: context.rs(20, min: 16, max: 28)),
                      Text(
                        _isHovered ? 'Release to Select' : 'Drag & Drop Your Match Video',
                        style: AppTextStyles.title().copyWith(
                          fontSize: context.sp(18, min: 15, max: 22),
                          color: _isHovered
                              ? AppColors.accentCyan
                              : AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: context.rs(8, min: 6, max: 10)),
                      Text(
                        'or tap to browse files',
                        style: AppTextStyles.body(color: AppColors.textMuted),
                      ),
                      SizedBox(height: context.rs(20, min: 16, max: 28)),
                      // Format chips
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        alignment: WrapAlignment.center,
                        children: ['MP4', 'MOV', 'AVI', 'MKV'].map((fmt) {
                          return _FormatChip(label: fmt);
                        }).toList(),
                      ),
                      SizedBox(height: context.rs(12, min: 8, max: 16)),
                      Text(
                        'Max file size: 5 GB • Min resolution: 1080p',
                        style: AppTextStyles.caption(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        SizedBox(height: context.rs(16, min: 12, max: 20)),

        // Browse button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: widget.onSelectFile,
            icon: const Icon(Icons.folder_open_rounded),
            label: const Text('Browse Files'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryPurple,
              foregroundColor: AppColors.textPrimary,
              padding: EdgeInsets.symmetric(
                vertical: context.rs(14, min: 12, max: 18),
              ),
              shape: const RoundedRectangleBorder(
                borderRadius: AppRadius.button,
              ),
              elevation: 0,
              shadowColor: Colors.transparent,
            ),
          ),
        ),
        SizedBox(height: context.rs(20, min: 16, max: 24)),

        // Info cards row
        context.adaptiveLayout(
          narrow: Column(
            children: _buildInfoCards(context),
          ),
          wide: Row(
            children: _buildInfoCards(context)
                .map((c) => Expanded(child: c))
                .toList()
                .expand((w) => [
                      w,
                      const SizedBox(width: 12),
                    ])
                .toList()
              ..removeLast(),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildInfoCards(BuildContext context) {
    return [
      const _InfoTile(
        icon: Icons.schedule_rounded,
        color: AppColors.primaryBlue,
        title: 'Processing Time',
        subtitle: '2–5 min per match',
      ),
      SizedBox(height: context.isPhone ? 10 : 0),
      const _InfoTile(
        icon: Icons.auto_awesome_rounded,
        color: AppColors.primaryPurple,
        title: 'AI Analysis',
        subtitle: '8 intelligent stages',
      ),
      SizedBox(height: context.isPhone ? 10 : 0),
      const _InfoTile(
        icon: Icons.analytics_rounded,
        color: AppColors.accentGreen,
        title: 'Full Report',
        subtitle: 'Players + Tactics + Insights',
      ),
    ];
  }
}

class _AnimatedUploadIcon extends StatelessWidget {
  const _AnimatedUploadIcon({
    required this.pulseValue,
    required this.isHovered,
  });

  final double pulseValue;
  final bool isHovered;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 84,
      height: 84,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow ring
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (isHovered ? AppColors.accentCyan : AppColors.primaryPurple)
                  .withValues(alpha: pulseValue * 0.12),
            ),
          ),
          // Inner ring
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (isHovered ? AppColors.accentCyan : AppColors.primaryPurple)
                  .withValues(alpha: 0.15),
              border: Border.all(
                color: (isHovered ? AppColors.accentCyan : AppColors.primaryPurple)
                    .withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: Icon(
              isHovered
                  ? Icons.cloud_done_rounded
                  : Icons.cloud_upload_rounded,
              size: 32,
              color: isHovered ? AppColors.accentCyan : AppColors.primaryPurple,
            ),
          ),
        ],
      ),
    );
  }
}

class _FormatChip extends StatelessWidget {
  const _FormatChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: AppRadius.chip,
        color: AppColors.surfaceRaised,
        border: Border.all(
          color: AppColors.outline,
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption(color: AppColors.accentCyan).copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: AppRadius.card,
        color: AppColors.surfaceElevated,
        border: Border.all(color: AppColors.outlineSubtle, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.15),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTextStyles.body(color: AppColors.textPrimary)
                        .copyWith(fontWeight: FontWeight.w600, fontSize: 13)),
                Text(subtitle,
                    style: AppTextStyles.caption(color: AppColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Selected File Card ───────────────────────────────────────────────────────

class SelectedFileCard extends StatelessWidget {
  const SelectedFileCard({
    super.key,
    required this.fileName,
    required this.fileSize,
    required this.onRemove,
  });

  final String fileName;
  final String fileSize;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: AppRadius.card,
        color: AppColors.accentGreen.withValues(alpha: 0.06),
        border: Border.all(
          color: AppColors.accentGreen.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentGreen.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: AppColors.accentGreen.withValues(alpha: 0.12),
            ),
            child: const Icon(
              Icons.video_file_rounded,
              color: AppColors.accentGreen,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  style: AppTextStyles.body(color: AppColors.textPrimary)
                      .copyWith(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        size: 12, color: AppColors.accentGreen),
                    const SizedBox(width: 4),
                    Text(
                      'Ready • $fileSize',
                      style: AppTextStyles.caption(color: AppColors.accentGreen),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.danger.withValues(alpha: 0.12),
              ),
              child: const Icon(
                Icons.close_rounded,
                size: 16,
                color: AppColors.danger,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Team Selection Form ──────────────────────────────────────────────────────

class TeamSelectionForm extends StatefulWidget {
  const TeamSelectionForm({
    super.key,
    required this.formData,
    required this.onChanged,
  });

  final UploadFormData formData;
  final ValueChanged<UploadFormData> onChanged;

  @override
  State<TeamSelectionForm> createState() => _TeamSelectionFormState();
}

class _TeamSelectionFormState extends State<TeamSelectionForm> {
  late final TextEditingController _homeCtrl;
  late final TextEditingController _awayCtrl;

  @override
  void initState() {
    super.initState();
    _homeCtrl = TextEditingController(text: widget.formData.homeTeam);
    _awayCtrl = TextEditingController(text: widget.formData.awayTeam);
  }

  @override
  void dispose() {
    _homeCtrl.dispose();
    _awayCtrl.dispose();
    super.dispose();
  }

  void _notifyChange() {
    widget.onChanged(widget.formData.copyWith(
      homeTeam: _homeCtrl.text,
      awayTeam: _awayCtrl.text,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return _FormSection(
      title: 'Teams',
      icon: Icons.groups_rounded,
      child: Column(
        children: [
          _GsTextField(
            controller: _homeCtrl,
            label: 'Home Team',
            hint: 'e.g. GoalSight FC',
            prefixIcon: Icons.home_rounded,
            accentColor: AppColors.accentCyan,
            onChanged: (_) => _notifyChange(),
          ),
          const SizedBox(height: 16),
          // VS divider
          Row(
            children: [
              const Expanded(
                child: Divider(
                  color: AppColors.outlineSubtle,
                  height: 1,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: AppRadius.chip,
                    color: AppColors.primaryPurple.withValues(alpha: 0.15),
                    border: Border.all(
                      color: AppColors.primaryPurple.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    'VS',
                    style: AppTextStyles.caption(color: AppColors.primaryPurple)
                        .copyWith(fontWeight: FontWeight.w800, letterSpacing: 1.5),
                  ),
                ),
              ),
              const Expanded(
                child: Divider(
                  color: AppColors.outlineSubtle,
                  height: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _GsTextField(
            controller: _awayCtrl,
            label: 'Away Team',
            hint: 'e.g. Falcons United',
            prefixIcon: Icons.flight_takeoff_rounded,
            accentColor: AppColors.warning,
            onChanged: (_) => _notifyChange(),
          ),
        ],
      ),
    );
  }
}

// ─── Match Metadata Form ──────────────────────────────────────────────────────

class MatchMetadataForm extends StatefulWidget {
  const MatchMetadataForm({
    super.key,
    required this.formData,
    required this.onChanged,
  });

  final UploadFormData formData;
  final ValueChanged<UploadFormData> onChanged;

  @override
  State<MatchMetadataForm> createState() => _MatchMetadataFormState();
}

class _MatchMetadataFormState extends State<MatchMetadataForm> {
  late final TextEditingController _venueCtrl;
  late final TextEditingController _notesCtrl;
  late String _selectedCompetition;
  late DateTime _selectedDate;

  static const _competitions = [
    'Premier League',
    'FA Cup',
    'League Cup',
    'Champions League',
    'Europa League',
    'Conference League',
    'Friendly',
    'Pre-season',
  ];

  @override
  void initState() {
    super.initState();
    _venueCtrl = TextEditingController(text: widget.formData.venue);
    _notesCtrl = TextEditingController(text: widget.formData.notes);
    _selectedCompetition = widget.formData.competition.isNotEmpty
        ? widget.formData.competition
        : _competitions[0];
    _selectedDate = widget.formData.matchDate;
    // Set default competition immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifyChange();
    });
  }

  @override
  void dispose() {
    _venueCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _notifyChange() {
    widget.onChanged(widget.formData.copyWith(
      competition: _selectedCompetition,
      venue: _venueCtrl.text,
      notes: _notesCtrl.text,
      matchDate: _selectedDate,
    ));
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primaryPurple,
              onPrimary: AppColors.textPrimary,
              surface: AppColors.surfaceElevated,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      _notifyChange();
    }
  }

  @override
  Widget build(BuildContext context) {
    return _FormSection(
      title: 'Match Details',
      icon: Icons.sports_soccer_rounded,
      child: Column(
        children: [
          // Competition dropdown
          _GsDropdownField<String>(
            label: 'Competition',
            prefixIcon: Icons.emoji_events_rounded,
            value: _selectedCompetition,
            items: _competitions,
            itemLabel: (c) => c,
            onChanged: (v) {
              if (v != null) {
                setState(() => _selectedCompetition = v);
                _notifyChange();
              }
            },
          ),
          const SizedBox(height: 14),

          // Date picker
          GestureDetector(
            onTap: _pickDate,
            child: _GsReadonlyField(
              label: 'Match Date',
              prefixIcon: Icons.calendar_today_rounded,
              value: _formatDate(_selectedDate),
              accentColor: AppColors.accentCyan,
            ),
          ),
          const SizedBox(height: 14),

          // Venue
          _GsTextField(
            controller: _venueCtrl,
            label: 'Venue / Stadium',
            hint: 'e.g. GoalSight Arena',
            prefixIcon: Icons.stadium_rounded,
            onChanged: (_) => _notifyChange(),
          ),
          const SizedBox(height: 14),

          // Notes (optional)
          _GsTextField(
            controller: _notesCtrl,
            label: 'Notes (optional)',
            hint: 'Any context about the match...',
            prefixIcon: Icons.notes_rounded,
            maxLines: 3,
            onChanged: (_) => _notifyChange(),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

// ─── Upload Confirmation Card ─────────────────────────────────────────────────

class UploadConfirmationCard extends StatelessWidget {
  const UploadConfirmationCard({
    super.key,
    required this.formData,
    required this.onConfirm,
    required this.onEdit,
  });

  final UploadFormData formData;
  final VoidCallback onConfirm;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final dateStr =
        '${formData.matchDate.day} ${months[formData.matchDate.month - 1]} ${formData.matchDate.year}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Title
        Text(
          'Review & Confirm',
          style: AppTextStyles.headline().copyWith(
            fontSize: context.sp(24, min: 20, max: 30),
          ),
        ),
        SizedBox(height: context.rs(6, min: 4, max: 8)),
        Text(
          'Please verify all match details before starting the AI analysis.',
          style: AppTextStyles.body(color: AppColors.textSecondary),
        ),
        SizedBox(height: context.rs(24, min: 18, max: 32)),

        // File card
        _ConfirmSection(
          title: 'Video File',
          icon: Icons.video_file_rounded,
          color: AppColors.accentGreen,
          rows: [
            _ConfirmRow(label: 'File', value: formData.fileName ?? '—'),
            _ConfirmRow(label: 'Size', value: formData.fileSize ?? '—'),
          ],
        ),
        SizedBox(height: context.rs(12, min: 8, max: 16)),

        // Match card
        _ConfirmSection(
          title: 'Match Info',
          icon: Icons.sports_soccer_rounded,
          color: AppColors.primaryBlue,
          rows: [
            _ConfirmRow(label: 'Home', value: formData.homeTeam),
            _ConfirmRow(label: 'Away', value: formData.awayTeam),
            _ConfirmRow(label: 'Competition', value: formData.competition),
            _ConfirmRow(label: 'Date', value: dateStr),
            _ConfirmRow(label: 'Venue', value: formData.venue),
            if (formData.notes.isNotEmpty)
              _ConfirmRow(label: 'Notes', value: formData.notes),
          ],
        ),
        SizedBox(height: context.rs(12, min: 8, max: 16)),

        // AI pipeline info card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: AppRadius.card,
            color: AppColors.primaryPurple.withValues(alpha: 0.06),
            border: Border.all(
              color: AppColors.primaryPurple.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryPurple.withValues(alpha: 0.15),
                ),
                child: const Icon(Icons.auto_awesome_rounded,
                    size: 20, color: AppColors.primaryPurple),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '8-Stage AI Analysis Pipeline',
                      style: AppTextStyles.body(color: AppColors.textPrimary)
                          .copyWith(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Player detection → Tracking → Possession → Speed → Tactics → Insights → Reports → Finalization',
                      style: AppTextStyles.caption(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: context.rs(24, min: 18, max: 32)),

        // Confirm button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onConfirm,
            icon: const Icon(Icons.rocket_launch_rounded),
            label: const Text('Start AI Analysis'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryPurple,
              foregroundColor: AppColors.textPrimary,
              padding: EdgeInsets.symmetric(
                vertical: context.rs(15, min: 12, max: 18),
              ),
              shape: const RoundedRectangleBorder(
                borderRadius: AppRadius.button,
              ),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Edit button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_rounded, size: 18),
            label: const Text('Edit Details'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              side: const BorderSide(
                color: AppColors.outline,
                width: 1.5,
              ),
              padding: EdgeInsets.symmetric(
                vertical: context.rs(13, min: 10, max: 16),
              ),
              shape: const RoundedRectangleBorder(
                borderRadius: AppRadius.button,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Upload Failed Card ───────────────────────────────────────────────────────

class UploadFailedCard extends StatelessWidget {
  const UploadFailedCard({
    super.key,
    required this.reason,
    required this.onRetry,
    required this.onEditDetails,
    required this.formData,
  });

  final String reason;
  final VoidCallback onRetry;
  final VoidCallback onEditDetails;
  final UploadFormData formData;

  static const _troubleshootingTips = [
    ('Check file format', 'Supported: MP4, MOV, AVI, MKV only'),
    ('Check resolution', 'Maximum supported resolution is 4K (3840×2160)'),
    ('Verify file integrity', 'Ensure the file is not corrupted and plays fully'),
    ('Check file size', 'Maximum file size is 5 GB'),
    ('Stable connection', 'Ensure you have a stable internet connection'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Error header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: AppRadius.cardLarge,
            color: AppColors.danger.withValues(alpha: 0.06),
            border: Border.all(
              color: AppColors.danger.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.danger.withValues(alpha: 0.12),
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  size: 34,
                  color: AppColors.danger,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Upload Failed',
                style: AppTextStyles.title(color: AppColors.danger),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: const BoxDecoration(
                  borderRadius: AppRadius.card,
                  color: AppColors.surfaceElevated,
                ),
                child: Text(
                  reason,
                  style: AppTextStyles.body(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: context.rs(20, min: 16, max: 28)),

        // Troubleshooting
        _FormSection(
          title: 'Troubleshooting Tips',
          icon: Icons.build_rounded,
          child: Column(
            children: _troubleshootingTips.map((tip) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.warning.withValues(alpha: 0.15),
                      ),
                      child: const Icon(
                        Icons.lightbulb_outline_rounded,
                        size: 11,
                        color: AppColors.warning,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tip.$1,
                            style: AppTextStyles.body(color: AppColors.textPrimary)
                                .copyWith(
                                    fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          Text(
                            tip.$2,
                            style: AppTextStyles.caption(
                                color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        SizedBox(height: context.rs(20, min: 16, max: 28)),

        // Retry button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry Upload'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryPurple,
              foregroundColor: AppColors.textPrimary,
              padding: EdgeInsets.symmetric(
                  vertical: context.rs(14, min: 12, max: 18)),
              shape: const RoundedRectangleBorder(borderRadius: AppRadius.button),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Edit details button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onEditDetails,
            icon: const Icon(Icons.edit_rounded, size: 18),
            label: const Text('Edit Match Details'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              side: const BorderSide(color: AppColors.outline, width: 1.5),
              padding: EdgeInsets.symmetric(
                  vertical: context.rs(13, min: 10, max: 16)),
              shape: const RoundedRectangleBorder(borderRadius: AppRadius.button),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Shared Private Widgets ───────────────────────────────────────────────────

class _FormSection extends StatelessWidget {
  const _FormSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: AppRadius.cardLarge,
        color: AppColors.surfaceElevated,
        border: Border.all(color: AppColors.outlineSubtle, width: 1),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accentCyan.withValues(alpha: 0.12),
                  ),
                  child: Icon(icon, size: 14, color: AppColors.accentCyan),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: AppTextStyles.body(color: AppColors.textPrimary)
                      .copyWith(fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.outlineSubtle),
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _GsTextField extends StatelessWidget {
  const _GsTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.prefixIcon,
    this.accentColor,
    this.maxLines = 1,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData prefixIcon;
  final Color? accentColor;
  final int maxLines;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? AppColors.primaryPurple;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.caption(color: AppColors.textMuted)
              .copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          onChanged: onChanged,
          style: AppTextStyles.body(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.body(color: AppColors.textMuted),
            prefixIcon: Icon(prefixIcon, size: 18, color: accent),
            filled: true,
            fillColor: AppColors.surfaceRaised,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: const OutlineInputBorder(
              borderRadius: AppRadius.input,
              borderSide: BorderSide(color: AppColors.outline, width: 1),
            ),
            enabledBorder: const OutlineInputBorder(
              borderRadius: AppRadius.input,
              borderSide: BorderSide(color: AppColors.outline, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppRadius.input,
              borderSide: BorderSide(color: accent, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class _GsDropdownField<T> extends StatelessWidget {
  const _GsDropdownField({
    required this.label,
    required this.prefixIcon,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  final String label;
  final IconData prefixIcon;
  final T value;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.caption(color: AppColors.textMuted)
              .copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<T>(
          initialValue: value,
          onChanged: onChanged,
          style: AppTextStyles.body(color: AppColors.textPrimary),
          dropdownColor: AppColors.surfaceElevated,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: AppColors.textMuted, size: 20),
          decoration: InputDecoration(
            prefixIcon:
                Icon(prefixIcon, size: 18, color: AppColors.accentCyan),
            filled: true,
            fillColor: AppColors.surfaceRaised,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: const OutlineInputBorder(
              borderRadius: AppRadius.input,
              borderSide: BorderSide(color: AppColors.outline, width: 1),
            ),
            enabledBorder: const OutlineInputBorder(
              borderRadius: AppRadius.input,
              borderSide: BorderSide(color: AppColors.outline, width: 1),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: AppRadius.input,
              borderSide:
                  BorderSide(color: AppColors.accentCyan, width: 1.5),
            ),
          ),
          items: items.map((item) {
            return DropdownMenuItem<T>(
              value: item,
              child: Text(itemLabel(item)),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _GsReadonlyField extends StatelessWidget {
  const _GsReadonlyField({
    required this.label,
    required this.prefixIcon,
    required this.value,
    this.accentColor,
  });

  final String label;
  final IconData prefixIcon;
  final String value;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? AppColors.primaryPurple;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.caption(color: AppColors.textMuted)
              .copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: AppRadius.input,
            color: AppColors.surfaceRaised,
            border: Border.all(color: AppColors.outline, width: 1),
          ),
          child: Row(
            children: [
              Icon(prefixIcon, size: 18, color: accent),
              const SizedBox(width: 10),
              Text(
                value,
                style: AppTextStyles.body(color: AppColors.textPrimary),
              ),
              const Spacer(),
              const Icon(Icons.edit_calendar_rounded,
                  size: 16, color: AppColors.textMuted),
            ],
          ),
        ),
      ],
    );
  }
}

class _ConfirmSection extends StatelessWidget {
  const _ConfirmSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.rows,
  });

  final String title;
  final IconData icon;
  final Color color;
  final List<_ConfirmRow> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: AppRadius.card,
        color: AppColors.surfaceElevated,
        border: Border.all(color: AppColors.outlineSubtle),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.12),
                  ),
                  child: Icon(icon, size: 13, color: color),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: AppTextStyles.body(color: AppColors.textPrimary)
                      .copyWith(fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.outlineSubtle),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: rows,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfirmRow extends StatelessWidget {
  const _ConfirmRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: AppTextStyles.caption(color: AppColors.textMuted)
                  .copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.caption(color: AppColors.textPrimary)
                  .copyWith(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

