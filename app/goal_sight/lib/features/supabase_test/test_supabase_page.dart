import 'package:flutter/material.dart';

import '../../core/supabase/supabase_config.dart';
import '../../core/supabase/supabase_client.dart';

class TestSupabasePage extends StatefulWidget {
  const TestSupabasePage({super.key});

  @override
  State<TestSupabasePage> createState() => _TestSupabasePageState();
}

class _TestSupabasePageState extends State<TestSupabasePage> {
  late final Future<List<Map<String, dynamic>>> _teamsFuture;
  late final bool _hasConfig;

  @override
  void initState() {
    super.initState();
    _hasConfig = hasSupabaseConfig;
    _teamsFuture = _hasConfig ? _fetchTeams() : Future.value(const []);
  }

  // Simple fetch from the "teams" table.
  Future<List<Map<String, dynamic>>> _fetchTeams() async {
    try {
      final data = await supabase.from('teams').select();
      return List<Map<String, dynamic>>.from(data as List);
    } catch (error) {
      // Bubble the error to the UI so it is visible to you.
      throw Exception('Failed to load teams: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Supabase Teams'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _teamsFuture,
        builder: (context, snapshot) {
          if (!_hasConfig) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Supabase is not configured yet.\nSet SUPABASE_URL and SUPABASE_ANON_KEY in the .env file to load teams.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.redAccent),
              ),
            );
          }

          final teams = snapshot.data ?? const [];
          if (teams.isEmpty) {
            return const Center(child: Text('No teams found.'));
          }

          return ListView.separated(
            itemCount: teams.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final team = teams[index];
              final teamName = team['name']?.toString() ?? 'Unknown team';
              final teamId = team['id']?.toString() ?? 'N/A';

              return ListTile(
                title: Text(teamName),
                subtitle: Text('ID: $teamId'),
              );
            },
          );
        },
      ),
    );
  }
}
