import '../../data/feedback_repository.dart';

class GetFeedbackVisibilityUseCase {
  final IFeedbackRepository repository;

  GetFeedbackVisibilityUseCase(this.repository);

  Future<bool> call() async {
    return await repository.isFeedbackFeatureEnabled();
  }
}
