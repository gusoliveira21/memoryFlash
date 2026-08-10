import '../../data/feedback_repository.dart';

class MarkFeedbackNotificationAsSeenUseCase {
  final IFeedbackRepository repository;

  MarkFeedbackNotificationAsSeenUseCase(this.repository);

  Future<void> call() async {
    await repository.setSeenNotification(true);
  }
}
