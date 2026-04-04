import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/match_provider.dart';
import '../models/match.dart';
import 'match_detail_page.dart';

const Color _primaryGold = Color(0xFFFFD700);
const Color _accentAmber = Color(0xFFFFA000);
const Color _darkBackground = Color(0xFF0A0A0F);
const Color _cardDark = Color(0xFF1A1A24);
const Color _textPrimary = Color(0xFFFFFFFF);
const Color _textSecondary = Color(0xFFB8B8C8);

class MatchHistoryPage extends StatefulWidget {
  @override
  _MatchHistoryPageState createState() => _MatchHistoryPageState();
}

class _MatchHistoryPageState extends State<MatchHistoryPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MatchProvider>(context, listen: false).loadMatches();
    });
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
            'MATCH HISTORY',
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
        child: Consumer<MatchProvider>(
          builder: (context, matchProvider, child) {
            if (matchProvider.isLoading && matchProvider.matches.isEmpty) {
              return Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(_primaryGold),
                ),
              );
            }

            if (matchProvider.matches.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.history_rounded,
                      size: 80,
                      color: _textSecondary,
                    ),
                    SizedBox(height: 24),
                    Text(
                      'No Match History',
                      style: TextStyle(
                        color: _textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Start adding matches to see them here',
                      style: TextStyle(
                        color: _textSecondary,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () => matchProvider.loadMatches(),
              color: _primaryGold,
              child: ListView.builder(
                padding: EdgeInsets.all(20),
                itemCount: matchProvider.matches.length,
                itemBuilder: (context, index) {
                  final match = matchProvider.matches[index];
                       return _buildMatchCard(context, match, index);
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMatchCard(BuildContext context, Match match, int index) {
    final dateStr = '${match.matchDate.day}/${match.matchDate.month}/${match.matchDate.year}';
     return TweenAnimationBuilder<double>(
       tween: Tween<double>(begin: 0, end: 1),
       duration: Duration(milliseconds: 500 + index * 80),
       curve: Curves.easeOut,
       builder: (context, value, child) {
         return Opacity(
           opacity: value,
           child: Transform.translate(
             offset: Offset(0, 30 * (1 - value)),
             child: child,
           ),
         );
       },
       child: Container(
         margin: EdgeInsets.only(bottom: 16),
         decoration: BoxDecoration(
           color: _cardDark,
           borderRadius: BorderRadius.circular(20),
           border: Border.all(
             color: _primaryGold.withOpacity(0.2),
             width: 1,
           ),
           boxShadow: [
             BoxShadow(
               color: Colors.black.withOpacity(0.3),
               blurRadius: 10,
               offset: Offset(0, 4),
             ),
           ],
         ),
         child: Material(
           color: Colors.transparent,
           child: InkWell(
             onTap: () {
               Navigator.of(context).push(
                 PageRouteBuilder(
                   pageBuilder: (context, animation, secondaryAnimation) => MatchDetailPage(match: match),
                   transitionsBuilder: (context, animation, secondaryAnimation, child) {
                     return FadeTransition(
                       opacity: animation,
                       child: child,
                     );
                   },
                   transitionDuration: Duration(milliseconds: 400),
                 ),
               );
             },
             borderRadius: BorderRadius.circular(20),
             child: Padding(
               padding: EdgeInsets.all(20),
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Row(
                     children: [
                       Container(
                         padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                         decoration: BoxDecoration(
                           gradient: LinearGradient(
                             colors: [_primaryGold, _accentAmber],
                           ),
                           borderRadius: BorderRadius.circular(8),
                         ),
                         child: Text(
                           'Match #${match.id ?? index + 1}',
                           style: TextStyle(
                             color: _darkBackground,
                             fontSize: 12,
                             fontWeight: FontWeight.w700,
                           ),
                         ),
                       ),
                       Spacer(),
                       Icon(Icons.chevron_right_rounded, color: _textSecondary),
                     ],
                   ),
                   SizedBox(height: 16),
                   Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                       Expanded(
                         child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             Text(
                               match.teamA,
                               style: TextStyle(
                                 color: _textPrimary,
                                 fontSize: 18,
                                 fontWeight: FontWeight.w700,
                               ),
                             ),
                             SizedBox(height: 4),
                             Text(
                               'vs',
                               style: TextStyle(
                                 color: _textSecondary,
                                 fontSize: 14,
                               ),
                             ),
                             SizedBox(height: 4),
                             Text(
                               match.teamB,
                               style: TextStyle(
                                 color: _textPrimary,
                                 fontSize: 18,
                                 fontWeight: FontWeight.w700,
                               ),
                             ),
                           ],
                         ),
                       ),
                       Container(
                         padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                         decoration: BoxDecoration(
                           gradient: LinearGradient(
                             colors: [_primaryGold, _accentAmber],
                           ),
                           borderRadius: BorderRadius.circular(12),
                         ),
                         child: Text(
                           '${match.scoreA} - ${match.scoreB}',
                           style: TextStyle(
                             color: _darkBackground,
                             fontSize: 24,
                             fontWeight: FontWeight.w900,
                           ),
                         ),
                       ),
                     ],
                   ),
                   SizedBox(height: 16),
                   Divider(color: _textSecondary.withOpacity(0.2)),
                   SizedBox(height: 12),
                   Row(
                     children: [
                       Icon(Icons.calendar_today_rounded, size: 16, color: _textSecondary),
                       SizedBox(width: 8),
                       Text(
                         dateStr,
                         style: TextStyle(
                           color: _textSecondary,
                           fontSize: 14,
                         ),
                       ),
                       if (match.notes != null && match.notes!.isNotEmpty) ...[
                         Spacer(),
                         Icon(Icons.note_rounded, size: 16, color: _textSecondary),
                         SizedBox(width: 8),
                         Text(
                           'Has notes',
                           style: TextStyle(
                             color: _textSecondary,
                             fontSize: 14,
                           ),
                         ),
                       ],
                     ],
                   ),
                 ],
               ),
             ),
           ),
         ),
       ),
     );
  }
}

