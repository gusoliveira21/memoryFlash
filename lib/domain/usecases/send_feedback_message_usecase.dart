import '../../data/feedback_repository.dart';

class SendFeedbackMessageUseCase {
  final IFeedbackRepository repository;

  SendFeedbackMessageUseCase(this.repository);

  Future<bool> call(String message) async {
    return await repository.submitFeedback(message);
  }
}
