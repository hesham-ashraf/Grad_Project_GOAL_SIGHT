import '../../models/upload_job_model.dart';

abstract interface class IUploadRepository {
  Future<List<UploadJobModel>> fetchUploadHistory({String? managerId});

  Future<UploadJobModel> fetchUploadById(String id);

  Future<UploadJobModel> createUploadJob(UploadJobModel job);

  Future<UploadJobModel> updateJobStatus(
    String id, {
    required UploadStatus status,
    double? progress,
    ProcessingStage? stage,
    String? failureReason,
  });

  Future<void> retryJob(String id);

  Stream<UploadJobModel> watchJob(String id);
}
