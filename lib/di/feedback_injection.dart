import 'package:get_it/get_it.dart';

import '../data/local_data_source.dart';
import '../data/remote_data_source.dart';
import '../data/feedback_repository.dart';
import '../domain/usecases/get_feedback_visibility_usecase.dart';
import '../domain/usecases/mark_feedback_notification_as_seen_usecase.dart';
import '../domain/usecases/send_feedback_message_usecase.dart';
import '../domain/usecases/should_show_feedback_notification_usecase.dart';
import '../presentation/viewmodels/feedback_viewmodel.dart';

final getIt = GetIt.instance;

void setupFeedbackDI() {
  getIt.registerLazySingleton<FeedbackRemoteDataSource>(() => FeedbackRemoteDataSource());
  getIt.registerLazySingleton<FeedbackLocalDataSource>(() => FeedbackLocalDataSource());

  getIt.registerLazySingleton<IFeedbackRepository>(
    () => FeedbackRepositoryImpl(
      remoteDataSource: getIt<FeedbackRemoteDataSource>(),
      localDataSource: getIt<FeedbackLocalDataSource>(),
    ),
  );

  getIt.registerLazySingleton<GetFeedbackVisibilityUseCase>(
    () => GetFeedbackVisibilityUseCase(getIt<IFeedbackRepository>()),
  );
  getIt.registerLazySingleton<ShouldShowFeedbackNotificationUseCase>(
    () => ShouldShowFeedbackNotificationUseCase(getIt<IFeedbackRepository>()),
  );
  getIt.registerLazySingleton<MarkFeedbackNotificationAsSeenUseCase>(
    () => MarkFeedbackNotificationAsSeenUseCase(getIt<IFeedbackRepository>()),
  );
  getIt.registerLazySingleton<SendFeedbackMessageUseCase>(
    () => SendFeedbackMessageUseCase(getIt<IFeedbackRepository>()),
  );

  getIt.registerFactory<FeedbackViewModel>(() => FeedbackViewModel(
      getIt<GetFeedbackVisibilityUseCase>(),
      getIt<ShouldShowFeedbackNotificationUseCase>(),
      getIt<MarkFeedbackNotificationAsSeenUseCase>(),
      getIt<SendFeedbackMessageUseCase>(),
    ),
  );
}
