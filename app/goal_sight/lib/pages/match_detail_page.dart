import 'package:flutter/material.dart';
import '../models/match.dart';
import 'charts_page.dart';

const Color _primaryGold = Color(0xFFFFD700);
const Color _accentAmber = Color(0xFFFFA000);
const Color _darkBackground = Color(0xFF0A0A0F);
const Color _cardDark = Color(0xFF1A1A24);
const Color _textPrimary = Color(0xFFFFFFFF);
const Color _textSecondary = Color(0xFFB8B8C8);

class MatchDetailPage extends StatelessWidget {
  final Match match;

  MatchDetailPage({required this.match});

  @override
  Widget build(BuildContext context) {
    final dateStr = '${match.matchDate.day}/${match.matchDate.month}/${match.matchDate.year}';
    final winner = match.scoreA > match.scoreB
        ? match.teamA
        : match.scoreB > match.scoreA
            ? match.teamB
            : 'Draw';

    return Scaffold(
      backgroundColor: _darkBackground,
      appBar: AppBar(
        title: ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [_primaryGold, _accentAmber],
          ).createShader(bounds),
          child: Text(
            'MATCH DETAILS',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.bar_chart_rounded, color: _primaryGold),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChartsPage(match: match),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildScoreCard(),
              SizedBox(height: 24),
              _buildInfoCard(
                icon: Icons.calendar_today_rounded,
                title: 'Match Date',
                content: dateStr,
              ),
              SizedBox(height: 16),
              _buildInfoCard(
                icon: Icons.emoji_events_rounded,
                title: 'Winner',
                content: winner,
              ),
              SizedBox(height: 16),
              _buildTeamStatsCard(match.teamA, match.scoreA, true),
              SizedBox(height: 16),
              _buildTeamStatsCard(match.teamB, match.scoreB, false),
              if (match.notes != null && match.notes!.isNotEmpty) ...[
                SizedBox(height: 16),
                _buildNotesCard(),
              ],
              SizedBox(height: 24),
              _buildViewChartsButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreCard() {
    return Container(
      padding: EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primaryGold.withOpacity(0.2), _accentAmber.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _primaryGold.withOpacity(0.4),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: _primaryGold.withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            match.teamA,
            style: TextStyle(
              color: _textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_primaryGold, _accentAmber],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${match.scoreA}',
                  style: TextStyle(
                    color: _darkBackground,
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  '-',
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_primaryGold, _accentAmber],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${match.scoreB}',
                  style: TextStyle(
                    color: _darkBackground,
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            match.teamB,
            style: TextStyle(
              color: _textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
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
                    color: _textSecondary,
                    fontSize: 13,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  content,
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamStatsCard(String teamName, int score, bool isTeamA) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isTeamA ? _primaryGold.withOpacity(0.3) : _accentAmber.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isTeamA ? [_primaryGold, _accentAmber] : [_accentAmber, _primaryGold],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                teamName.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  color: _darkBackground,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  teamName,
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Goals: $score',
                  style: TextStyle(
                    color: _textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isTeamA ? [_primaryGold, _accentAmber] : [_accentAmber, _primaryGold],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$score',
              style: TextStyle(
                color: _darkBackground,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesCard() {
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
            children: [
              Icon(Icons.note_rounded, color: _primaryGold, size: 24),
              SizedBox(width: 12),
              Text(
                'Notes',
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            match.notes!,
            style: TextStyle(
              color: _textSecondary,
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewChartsButton(BuildContext context) {
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
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChartsPage(match: match),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bar_chart_rounded, color: _darkBackground, size: 24),
                SizedBox(width: 12),
                Text(
                  'VIEW CHARTS',
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

