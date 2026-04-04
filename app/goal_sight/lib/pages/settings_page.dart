import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const Color _primaryGold = Color(0xFFFFD700);
const Color _accentAmber = Color(0xFFFFA000);
const Color _darkBackground = Color(0xFF0A0A0F);
const Color _cardDark = Color(0xFF1A1A24);
const Color _textPrimary = Color(0xFFFFFFFF);
const Color _textSecondary = Color(0xFFB8B8C8);

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = true;
  String _language = 'English';
  double _fontSize = 16.0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications') ?? true;
      _darkModeEnabled = prefs.getBool('darkMode') ?? true;
      _language = prefs.getString('language') ?? 'English';
      _fontSize = prefs.getDouble('fontSize') ?? 16.0;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications', _notificationsEnabled);
    await prefs.setBool('darkMode', _darkModeEnabled);
    await prefs.setString('language', _language);
    await prefs.setDouble('fontSize', _fontSize);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: _darkBackground),
            SizedBox(width: 12),
            Text('Settings saved successfully!'),
          ],
        ),
        backgroundColor: _primaryGold,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBackground,
      appBar: AppBar(
        title: ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [_primaryGold, _accentAmber],
          ).createShader(bounds),
          child: Text(
            'SETTINGS',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.0,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionHeader('Notifications'),
              SizedBox(height: 16),
              _buildSwitchTile(
                'Enable Notifications',
                'Receive alerts for match updates',
                _notificationsEnabled,
                (value) => setState(() => _notificationsEnabled = value),
                Icons.notifications_rounded,
              ),
              SizedBox(height: 32),
              _buildSectionHeader('Appearance'),
              SizedBox(height: 16),
              _buildSwitchTile(
                'Dark Mode',
                'Use dark theme',
                _darkModeEnabled,
                (value) => setState(() => _darkModeEnabled = value),
                Icons.dark_mode_rounded,
              ),
              SizedBox(height: 16),
              _buildLanguageSelector(),
              SizedBox(height: 32),
              _buildSectionHeader('Text Size'),
              SizedBox(height: 16),
              _buildFontSizeSlider(),
              SizedBox(height: 32),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 5,
          height: 28,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_primaryGold, _accentAmber],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        SizedBox(width: 16),
        Text(
          title,
          style: TextStyle(
            color: _textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
    IconData icon,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: _cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _primaryGold.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_primaryGold, _accentAmber],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: _darkBackground, size: 24),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: _textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: _textSecondary,
            fontSize: 13,
          ),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: _primaryGold,
        ),
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return Container(
      decoration: BoxDecoration(
        color: _cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _primaryGold.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_primaryGold, _accentAmber],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.language_rounded, color: _darkBackground, size: 24),
        ),
        title: Text(
          'Language',
          style: TextStyle(
            color: _textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          _language,
          style: TextStyle(
            color: _textSecondary,
            fontSize: 13,
          ),
        ),
        trailing: Icon(Icons.chevron_right_rounded, color: _textSecondary),
        onTap: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: _cardDark,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (context) => Container(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Select Language',
                    style: TextStyle(
                      color: _textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 20),
                  ...['English', 'Spanish', 'French', 'German'].map((lang) {
                    return ListTile(
                      title: Text(
                        lang,
                        style: TextStyle(color: _textPrimary),
                      ),
                      trailing: _language == lang
                          ? Icon(Icons.check, color: _primaryGold)
                          : null,
                      onTap: () {
                        setState(() => _language = lang);
                        Navigator.pop(context);
                      },
                    );
                  }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFontSizeSlider() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _primaryGold.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Font Size',
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${_fontSize.toInt()}',
                style: TextStyle(
                  color: _primaryGold,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Slider(
            value: _fontSize,
            min: 12.0,
            max: 24.0,
            divisions: 12,
            activeColor: _primaryGold,
            inactiveColor: _textSecondary.withOpacity(0.3),
            onChanged: (value) => setState(() => _fontSize = value),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primaryGold, _accentAmber],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _primaryGold.withOpacity(0.5),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _saveSettings,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.save_rounded, color: _darkBackground, size: 24),
                SizedBox(width: 12),
                Text(
                  'SAVE SETTINGS',
                  style: TextStyle(
                    color: _darkBackground,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
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

