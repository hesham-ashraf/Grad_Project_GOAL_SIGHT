import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../data/models/manager_model.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/repository_providers.dart';
import '../../widgets/admin/admin_manager_widgets.dart';

class ManagersPage extends ConsumerStatefulWidget {
  const ManagersPage({super.key});

  @override
  ConsumerState<ManagersPage> createState() => _ManagersPageState();
}

class _ManagersPageState extends ConsumerState<ManagersPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late List<Animation<double>> _fades;
  late List<Animation<Offset>> _slides;

  String _searchQuery = '';
  String _statusFilter = 'All'; // All | Active | Disabled
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();

    _fades = List.generate(3, (i) {
      final start = (i * 0.2).clamp(0.0, 0.7);
      final end = (start + 0.35).clamp(0.0, 1.0);
      return CurvedAnimation(
        parent: _ctrl,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      );
    });
    _slides = _fades.map((f) {
      return Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(f);
    }).toList();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  List<ManagerModel> get _filtered {
    return ref.watch(adminManagersProvider).where((m) {
      final matchesSearch = _searchQuery.isEmpty ||
          m.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          m.email.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesStatus = _statusFilter == 'All' ||
          (_statusFilter == 'Active' && m.isActive) ||
          (_statusFilter == 'Disabled' && !m.isActive);
      return matchesSearch && matchesStatus;
    }).toList();
  }

  Widget _reveal(int i, Widget child) {
    return FadeTransition(
      opacity: _fades[i],
      child: SlideTransition(position: _slides[i], child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final managers = _filtered;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.manage_accounts_outlined, color: AppColors.accentCyan, size: 20),
            const SizedBox(width: 8),
            Text('Managers', style: AppTextStyles.title(color: AppColors.textPrimary).copyWith(fontSize: context.sp(17, min: 15, max: 20))),
          ],
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primaryPurple.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.person_add_rounded, color: AppColors.primaryPurple, size: 18),
            ),
            onPressed: _showAddManagerSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(context.rs(20, min: 16, max: 28), context.rs(4, min: 2, max: 8), context.rs(20, min: 16, max: 28), 0),
            child: Column(
              children: [
                // 0 — Stats header
                _reveal(0, const ManagerStatsHeader()),
                const SizedBox(height: 14),
                // 1 — Search + Filter
                _reveal(1, Column(
                  children: [
                    // Search bar
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: AppColors.outline),
                      ),
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (v) => setState(() => _searchQuery = v),
                        style: AppTextStyles.body(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Search managers...',
                          hintStyle: AppTextStyles.body(color: AppColors.textMuted),
                          prefixIcon: const Icon(Icons.search, color: AppColors.textMuted, size: 18),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, color: AppColors.textMuted, size: 16),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Filter chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: ['All', 'Active', 'Disabled'].map((filter) {
                          final isSelected = _statusFilter == filter;
                          Color chipColor = AppColors.accentCyan;
                          if (filter == 'Active') chipColor = AppColors.accentGreen;
                          if (filter == 'Disabled') chipColor = AppColors.danger;
                          return GestureDetector(
                            onTap: () => setState(() => _statusFilter = filter),
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                color: isSelected ? chipColor.withValues(alpha: 0.15) : AppColors.surfaceElevated,
                                borderRadius: BorderRadius.circular(AppRadius.pill),
                                border: Border.all(
                                  color: isSelected ? chipColor.withValues(alpha: 0.5) : AppColors.outline,
                                ),
                              ),
                              child: Text(
                                filter,
                                style: AppTextStyles.caption(
                                  color: isSelected ? chipColor : AppColors.textSecondary,
                                ).copyWith(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                )),
                const SizedBox(height: 10),
              ],
            ),
          ),
          // 2 — Manager list
          Expanded(
            child: managers.isEmpty
                ? _reveal(2, _EmptyState(query: _searchQuery))
                : ListView.builder(
                    padding: EdgeInsets.fromLTRB(context.rs(20, min: 16, max: 28), context.rs(4, min: 2, max: 8), context.rs(20, min: 16, max: 28), context.rs(100, min: 80, max: 120)),
                    physics: const BouncingScrollPhysics(),
                    itemCount: managers.length,
                    itemBuilder: (context, i) => EnhancedManagerCard(manager: managers[i]),
                  ),
          ),
        ],
      ),
    );
  }

  void _showAddManagerSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddManagerSheet(),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String query;
  const _EmptyState({required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppColors.surfaceElevated,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.manage_accounts_outlined, color: AppColors.textMuted, size: 40),
          ),
          const SizedBox(height: 16),
          Text(
            query.isEmpty ? 'No managers yet' : 'No results for "$query"',
            style: AppTextStyles.body(color: AppColors.textSecondary),
          ),
          if (query.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Try a different search term', style: AppTextStyles.caption(color: AppColors.textMuted)),
          ],
        ],
      ),
    );
  }
}

// ─── Add Manager Sheet ────────────────────────────────────────────────────────

class _AddManagerSheet extends ConsumerStatefulWidget {
  const _AddManagerSheet();

  @override
  ConsumerState<_AddManagerSheet> createState() => _AddManagerSheetState();
}

class _AddManagerSheetState extends ConsumerState<_AddManagerSheet> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _canUpload = true;
  bool _canEditPlayers = true;
  bool _canManageStaff = false;
  bool _saving = false;
  String? _errorMsg;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final clubId = ref.read(adminClubIdProvider);
    if (clubId == null || clubId.isEmpty) {
      setState(() =>
          _errorMsg = 'Create your club first (from the dashboard), then add managers.');
      return;
    }

    setState(() {
      _saving = true;
      _errorMsg = null;
    });

    try {
      final repo = ref.read(managerRepositoryProvider);
      final manager = await repo.promoteUserToManager(
        email: _emailCtrl.text.trim(),
        clubId: clubId,
        canUpload: _canUpload,
        canEditPlayers: _canEditPlayers,
        canManageStaff: _canManageStaff,
      );
      ref.invalidate(managerListProvider);
      if (mounted) Navigator.of(context).pop(manager);
    } catch (e) {
      setState(() {
        _saving = false;
        _errorMsg = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 20,
        left: 20,
        right: 20,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryPurple.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.manage_accounts_outlined, color: AppColors.primaryPurple, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text('Promote to Manager', style: AppTextStyles.title(color: Colors.white)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'The user must have a GoalSight account. Enter their email to promote them from fan to manager.',
                style: AppTextStyles.caption(color: AppColors.textMuted),
              ),
              if (_errorMsg != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.danger.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.danger, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_errorMsg!,
                            style: AppTextStyles.caption(color: AppColors.danger)),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              _Field(ctrl: _emailCtrl, label: 'Fan Email Address', hint: 'user@example.com', icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Email is required';
                  if (!v.contains('@') || !v.contains('.')) return 'Enter a valid email';
                  return null;
                }),
              const SizedBox(height: 20),
              Text('Access Permissions', style: AppTextStyles.body(color: AppColors.textSecondary)),
              const SizedBox(height: 10),
              _Toggle(title: 'Upload Matches', subtitle: 'Allow video uploads to AI pipeline', value: _canUpload, onChanged: (v) => setState(() => _canUpload = v)),
              _Toggle(title: 'Edit Player Data', subtitle: 'Modify squad & player records', value: _canEditPlayers, onChanged: (v) => setState(() => _canEditPlayers = v)),
              _Toggle(title: 'Manage Sub-Staff', subtitle: 'Onboard assistant managers', value: _canManageStaff, onChanged: (v) => setState(() => _canManageStaff = v)),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving ? null : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.outline),
                        foregroundColor: AppColors.textSecondary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saving ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryPurple,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 18, height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text('Promote', style: AppTextStyles.button(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final String hint;
  final IconData icon;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  const _Field({
    required this.ctrl,
    required this.label,
    required this.hint,
    required this.icon,
    this.validator,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption(color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          style: AppTextStyles.body(color: Colors.white),
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.body(color: AppColors.textMuted),
            prefixIcon: Icon(icon, color: AppColors.textMuted, size: 18),
            filled: true,
            fillColor: AppColors.surfaceRaised,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(color: AppColors.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(color: AppColors.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(color: AppColors.primaryPurple),
            ),
            errorStyle: AppTextStyles.caption(color: AppColors.danger).copyWith(fontSize: 11),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}

class _Toggle extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _Toggle({required this.title, required this.subtitle, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceRaised,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.outline),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.body(color: Colors.white)),
                  Text(subtitle, style: AppTextStyles.caption(color: AppColors.textMuted)),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: AppColors.accentCyan,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      ),
    );
  }
}
