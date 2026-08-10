import '../../data/feedback_repository.dart';

class ShouldShowFeedbackNotificationUseCase {
  final IFeedbackRepository repository;

  ShouldShowFeedbackNotificationUseCase(this.repository);

  Future<bool> call() async {
    final isFeatureEnabled = await repository.isFeedbackFeatureEnabled();
    final hasUserSeenIt = await repository.hasSeenNotification();

    return isFeatureEnabled && !hasUserSeenIt;
  }
}
