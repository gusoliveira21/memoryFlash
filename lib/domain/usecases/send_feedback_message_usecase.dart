import '../../data/feedback_repository.dart';

class SendFeedbackMessageUseCase {
  final IFeedbackRepository repository;

  SendFeedbackMessageUseCase(this.repository);

  Future<bool> call(String message, {String? email}) async {
    return await repository.submitFeedback(message, email: email);
  }
}
