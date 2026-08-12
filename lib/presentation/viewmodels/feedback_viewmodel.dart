import 'package:flutter/widgets.dart';
import '../../domain/usecases/get_feedback_visibility_usecase.dart';
import '../../domain/usecases/should_show_feedback_notification_usecase.dart';
import '../../domain/usecases/mark_feedback_notification_as_seen_usecase.dart';
import '../../domain/usecases/send_feedback_message_usecase.dart';

class FeedbackViewModel extends ChangeNotifier with WidgetsBindingObserver {
  final GetFeedbackVisibilityUseCase _getVisibilityUseCase;
  final ShouldShowFeedbackNotificationUseCase _shouldShowAlertUseCase;
  final MarkFeedbackNotificationAsSeenUseCase _markAsSeenUseCase;
  final SendFeedbackMessageUseCase _sendMessageUseCase;

  bool _showFeedbackButton = false;
  bool get showFeedbackButton => _showFeedbackButton;

  bool _triggerProactiveAlert = false;
  bool get triggerProactiveAlert => _triggerProactiveAlert;

  bool _isSending = false;
  bool get isSending => _isSending;

  FeedbackViewModel(
    this._getVisibilityUseCase,
    this._shouldShowAlertUseCase,
    this._markAsSeenUseCase,
    this._sendMessageUseCase,
  ) {
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _init();
    }
  }

  Future<void> _init() async {
    final results = await Future.wait([
      _getVisibilityUseCase(),
      _shouldShowAlertUseCase(),
    ]);

    _showFeedbackButton = results[0];
    _triggerProactiveAlert = results[1];

    notifyListeners();
  }

  Future<void> markAlertAsSeen() async {
    await _markAsSeenUseCase();
    _triggerProactiveAlert = false;
    notifyListeners();
  }

  Future<bool> submitFeedback(String message, {String? email}) async {
    _isSending = true;
    notifyListeners();

    final success = await _sendMessageUseCase(message, email: email);

    _isSending = false;
    notifyListeners();

    return success;
  }
}
