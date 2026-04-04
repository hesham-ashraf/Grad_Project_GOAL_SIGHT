import 'package:flutter/material.dart';

const Color _primaryGold = Color(0xFFFFD700);
const Color _accentAmber = Color(0xFFFFA000);
const Color _darkBackground = Color(0xFF0A0A0F);
const Color _cardDark = Color(0xFF1A1A24);
const Color _textPrimary = Color(0xFFFFFFFF);
const Color _textSecondary = Color(0xFFB8B8C8);

class AboutPage extends StatelessWidget {
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
            'ABOUT',
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
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_primaryGold, _accentAmber],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _primaryGold.withOpacity(0.5),
                      blurRadius: 30,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'GS',
                    style: TextStyle(
                      color: _darkBackground,
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 32),
              Text(
                'GoalSight',
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'AI Football Analysis System',
                style: TextStyle(
                  color: _textSecondary,
                  fontSize: 18,
                ),
              ),
              SizedBox(height: 40),
              _buildInfoCard(
                icon: Icons.info_rounded,
                title: 'Version',
                content: '1.0.0',
              ),
              SizedBox(height: 16),
              _buildInfoCard(
                icon: Icons.description_rounded,
                title: 'Description',
                content: 'GoalSight is a comprehensive football analysis system that helps you track matches, analyze performance, and visualize statistics with advanced charts and insights.',
              ),
              SizedBox(height: 16),
              _buildInfoCard(
                icon: Icons.code_rounded,
                title: 'Features',
                content: '• Match tracking and history\n• Advanced analytics and charts\n• Real-time statistics\n• Detailed match summaries\n• Profile management',
              ),
              SizedBox(height: 16),
              _buildInfoCard(
                icon: Icons.developer_mode_rounded,
                title: 'Developed with',
                content: 'Flutter • Dart • SQLite • Provider',
              ),
              SizedBox(height: 40),
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _cardDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _primaryGold.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.favorite_rounded,
                      color: _primaryGold,
                      size: 32,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Made with passion for football',
                      style: TextStyle(
                        color: _textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      '© 2025 GoalSight. All rights reserved.',
                      style: TextStyle(
                        color: _textSecondary,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String content,
  }) {
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_primaryGold, _accentAmber],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: _darkBackground, size: 24),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  content,
                  style: TextStyle(
                    color: _textSecondary,
                    fontSize: 14,
                    height: 1.5,
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

