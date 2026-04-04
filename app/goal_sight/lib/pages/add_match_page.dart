import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/match.dart';
import '../providers/match_provider.dart';

const Color _primaryGold = Color(0xFFFFD700);
const Color _accentAmber = Color(0xFFFFA000);
const Color _darkBackground = Color(0xFF0A0A0F);
const Color _cardDark = Color(0xFF1A1A24);
const Color _textPrimary = Color(0xFFFFFFFF);
const Color _textSecondary = Color(0xFFB8B8C8);

class AddMatchPage extends StatefulWidget {
  const AddMatchPage({super.key});

  @override
  _AddMatchPageState createState() => _AddMatchPageState();
}

class _AddMatchPageState extends State<AddMatchPage> {
  final _formKey = GlobalKey<FormState>();
  final _teamAController = TextEditingController();
  final _teamBController = TextEditingController();
  final _scoreAController = TextEditingController();
  final _scoreBController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _teamAController.dispose();
    _teamBController.dispose();
    _scoreAController.dispose();
    _scoreBController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: _primaryGold,
              onPrimary: _darkBackground,
              surface: _cardDark,
              onSurface: _textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final match = Match(
      teamA: _teamAController.text.trim(),
      teamB: _teamBController.text.trim(),
      scoreA: int.parse(_scoreAController.text.trim()),
      scoreB: int.parse(_scoreBController.text.trim()),
      matchDate: _selectedDate,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    final provider = Provider.of<MatchProvider>(context, listen: false);
    final success = await provider.addMatch(match);

    setState(() {
      _isSubmitting = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: _darkBackground),
              SizedBox(width: 12),
              Text('Match added successfully!'),
            ],
          ),
          backgroundColor: _primaryGold,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: _textPrimary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  provider.error ?? 'Failed to add match. Please try again.',
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBackground,
      appBar: AppBar(
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [_primaryGold, _accentAmber],
          ).createShader(bounds),
          child: const Text(
            'ADD NEW MATCH',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _primaryGold.withOpacity(0.1),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _darkBackground,
                _darkBackground.withOpacity(0.95),
              ],
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeaderSection(),
                  const SizedBox(height: 32),
                  _buildTextField(
                    controller: _teamAController,
                    label: 'Team A',
                    icon: Icons.group,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter Team A name';
                      }
                      return null;
                    },
                  ),
                const SizedBox(height: 20),
                _buildTextField(
                  controller: _teamBController,
                  label: 'Team B',
                  icon: Icons.group,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter Team B name';
                    }
                    if (value.trim().toLowerCase() ==
                        _teamAController.text.trim().toLowerCase()) {
                      return 'Team B must be different from Team A';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _scoreAController,
                        label: 'Score A',
                        icon: Icons.sports_soccer,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Required';
                          }
                          final score = int.tryParse(value.trim());
                          if (score == null || score < 0) {
                            return 'Invalid score';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        controller: _scoreBController,
                        label: 'Score B',
                        icon: Icons.sports_soccer,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Required';
                          }
                          final score = int.tryParse(value.trim());
                          if (score == null || score < 0) {
                            return 'Invalid score';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildDatePicker(),
                const SizedBox(height: 20),
                _buildTextField(
                  controller: _notesController,
                  label: 'Notes (Optional)',
                  icon: Icons.note,
                  maxLines: 3,
                ),
                const SizedBox(height: 32),
                _buildSubmitButton(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primaryGold.withOpacity(0.15), _accentAmber.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _primaryGold.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_primaryGold, _accentAmber],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: _primaryGold.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.add_circle_rounded, color: _darkBackground, size: 32),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'New Match',
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Fill in the details below',
                  style: TextStyle(
                    color: _textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _primaryGold.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        style: const TextStyle(color: _textPrimary),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: _textSecondary),
          prefixIcon: Icon(icon, color: _primaryGold),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.red, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return Container(
      decoration: BoxDecoration(
        color: _cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _primaryGold.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _selectDate(context),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              const Icon(Icons.calendar_today, color: _primaryGold),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Match Date',
                    style: TextStyle(
                      color: _textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                    style: const TextStyle(
                      color: _textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
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

  Widget _buildSubmitButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_primaryGold, _accentAmber],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _primaryGold.withOpacity(0.5),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: _primaryGold.withOpacity(0.3),
            blurRadius: 40,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isSubmitting ? null : _submitForm,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: _isSubmitting
                ? const Center(
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(_darkBackground),
                        strokeWidth: 3,
                      ),
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_circle_rounded, color: _darkBackground, size: 26),
                      SizedBox(width: 12),
                      Text(
                        'ADD MATCH',
                        style: TextStyle(
                          color: _darkBackground,
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

