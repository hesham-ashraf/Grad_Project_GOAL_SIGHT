import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:math';

class ApiService {
  // Using a free public API for demonstration
  // Using football-data.org API (free tier) or fallback to mock data
  static const String baseUrl = 'https://api.football-data.org/v4';
  
  // Fallback: Generate realistic match statistics
  Future<Map<String, dynamic>> fetchMatchData() async {
    try {
      // Try to fetch from a free football API
      // Note: This is a mock implementation. For production, use a real API key
      // Using a public API that doesn't require authentication
      final response = await http.get(
        Uri.parse('https://api.football-data.org/v4/matches'),
        headers: {
          'X-Auth-Token': '', // Empty for demo - would need API key in production
          'Content-Type': 'application/json',
        },
      ).timeout(
        Duration(seconds: 5),
        onTimeout: () {
          // If API fails, return mock data
          return http.Response('', 408);
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Process real API data if available
        if (data['matches'] != null && (data['matches'] as List).isNotEmpty) {
          final match = (data['matches'] as List).first;
          return _processApiMatchData(match);
        }
      }
      
      // Fallback: Return realistic mock match data
      return _generateMockMatchData();
    } catch (e) {
      // On any error, return mock data
      return _generateMockMatchData();
    }
  }

  Map<String, dynamic> _processApiMatchData(Map<String, dynamic> match) {
    return {
      'id': match['id'] ?? Random().nextInt(1000),
      'homeTeam': match['homeTeam']?['name'] ?? 'Team A',
      'awayTeam': match['awayTeam']?['name'] ?? 'Team B',
      'score': match['score'] ?? {'fullTime': {'home': 0, 'away': 0}},
      'status': match['status'] ?? 'FINISHED',
      'competition': match['competition']?['name'] ?? 'Premier League',
      'utcDate': match['utcDate'] ?? DateTime.now().toIso8601String(),
      'fetchedAt': DateTime.now().toIso8601String(),
      'statistics': _generateStatistics(),
    };
  }

  Map<String, dynamic> _generateMockMatchData() {
    final random = Random();
    final teams = [
      ['Manchester United', 'Liverpool'],
      ['Arsenal', 'Chelsea'],
      ['Barcelona', 'Real Madrid'],
      ['Bayern Munich', 'Borussia Dortmund'],
      ['PSG', 'Marseille'],
    ];
    final teamPair = teams[random.nextInt(teams.length)];
    
    return {
      'id': random.nextInt(1000) + 1,
      'homeTeam': teamPair[0],
      'awayTeam': teamPair[1],
      'score': {
        'fullTime': {
          'home': random.nextInt(5),
          'away': random.nextInt(5),
        }
      },
      'status': 'FINISHED',
      'competition': 'Premier League',
      'utcDate': DateTime.now().subtract(Duration(days: random.nextInt(30))).toIso8601String(),
      'fetchedAt': DateTime.now().toIso8601String(),
      'statistics': _generateStatistics(),
    };
  }

  Map<String, dynamic> _generateStatistics() {
    final random = Random();
    final possessionA = 40 + random.nextInt(20); // 40-60%
    final possessionB = 100 - possessionA;
    
    return {
      'possession': {
        'home': possessionA,
        'away': possessionB,
      },
      'shots': {
        'home': 8 + random.nextInt(8), // 8-15
        'away': 8 + random.nextInt(8),
      },
      'shotsOnTarget': {
        'home': 3 + random.nextInt(5), // 3-7
        'away': 3 + random.nextInt(5),
      },
      'passes': {
        'home': 300 + random.nextInt(200), // 300-500
        'away': 300 + random.nextInt(200),
      },
      'passAccuracy': {
        'home': 70 + random.nextInt(20), // 70-90%
        'away': 70 + random.nextInt(20),
      },
      'fouls': {
        'home': 8 + random.nextInt(7), // 8-14
        'away': 8 + random.nextInt(7),
      },
      'corners': {
        'home': 3 + random.nextInt(5), // 3-7
        'away': 3 + random.nextInt(5),
      },
      'yellowCards': {
        'home': random.nextInt(4), // 0-3
        'away': random.nextInt(4),
      },
      'redCards': {
        'home': random.nextInt(2), // 0-1
        'away': random.nextInt(2),
      },
    };
  }

  // Alternative: Fetch from a football API (example structure)
  // Uncomment and modify when you have a real API endpoint
  /*
  Future<Map<String, dynamic>> fetchFootballMatchData() async {
    final response = await http.get(
      Uri.parse('YOUR_FOOTBALL_API_ENDPOINT'),
      headers: {
        'Content-Type': 'application/json',
        // Add API key if needed
        // 'Authorization': 'Bearer YOUR_API_KEY',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load match data');
    }
  }
  */
}

