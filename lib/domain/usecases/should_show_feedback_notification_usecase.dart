import '../../data/feedback_repository.dart';

class ShouldShowFeedbackNotificationUseCase {
  final IFeedbackRepository repository;

  ShouldShowFeedbackNotificationUseCase(this.repository);

  Future<bool> call() async {
    final isFeatureEnabled = await repository.isFeedbackFeatureEnabled();
    final hasUserSeenIt = await repository.hasSeenNotification();

    // Só exibe a notificação proativa se a feature existir E o usuário não tiver silenciado
    return isFeatureEnabled && !hasUserSeenIt;
  }
}
