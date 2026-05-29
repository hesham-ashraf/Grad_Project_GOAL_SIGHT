import '../../models/match_analysis_model.dart';

abstract interface class IAnalysisRepository {
  Future<List<MatchAnalysisModel>> fetchAnalyses({String? clubId});

  Future<MatchAnalysisModel> fetchAnalysisById(String id);

  Future<List<MatchAnalysisModel>> fetchAnalysesPaged({
    required int page,
    int pageSize = 20,
    String? clubId,
    String? matchId,
  });

  Future<MatchAnalysisModel?> fetchLatestAnalysis({String? clubId});
}
