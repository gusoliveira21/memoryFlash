import 'local_data_source.dart';
import 'remote_data_source.dart';

abstract class IFeedbackRepository {
  Future<bool> isFeedbackFeatureEnabled();
  Future<bool> hasSeenNotification();
  Future<void> setSeenNotification(bool value);
  Future<bool> submitFeedback(String message);
}

class FeedbackRepositoryImpl implements IFeedbackRepository {
  final FeedbackRemoteDataSource remoteDataSource;
  final FeedbackLocalDataSource localDataSource;

  FeedbackRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<bool> isFeedbackFeatureEnabled() async {
    return await remoteDataSource.checkFeedbackEnabled();
  }

  @override
  Future<bool> hasSeenNotification() async {
    return await localDataSource.getHasSeenFeedbackNotification();
  }

  @override
  Future<void> setSeenNotification(bool value) async {
    await localDataSource.setHasSeenFeedbackNotification(value);
  }

  @override
  Future<bool> submitFeedback(String message) async {
    return await remoteDataSource.sendFeedback(message);
  }
}
