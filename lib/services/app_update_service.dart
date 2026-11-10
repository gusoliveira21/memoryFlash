import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:url_launcher/url_launcher.dart';

class AppUpdateService {
  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.gusoliveira21.memoryflash';
  static const String playStoreMarketUri =
      'market://details?id=com.gusoliveira21.memoryflash';

  /// Verifica se há atualizações disponíveis no Google Play
  static Future<bool> isUpdateAvailable() async {
    if (!Platform.isAndroid) return false;
    try {
      final info = await InAppUpdate.checkForUpdate();
      return info.updateAvailability == UpdateAvailability.updateAvailable;
    } catch (e) {
      debugPrint('Verificação de atualização in-app: $e');
      return false;
    }
  }

  /// Inicia a atualização imediata ou abre a Play Store caso ocorra falha
  static Future<void> performUpdate() async {
    if (!Platform.isAndroid) return;
    try {
      await InAppUpdate.performImmediateUpdate();
    } catch (e) {
      debugPrint('Falha ao iniciar InAppUpdate imediato, redirecionando para a Play Store: $e');
      await openPlayStore();
    }
  }

  /// Abre a página do app na Play Store
  static Future<void> openPlayStore() async {
    final marketUri = Uri.parse(playStoreMarketUri);
    final webUri = Uri.parse(playStoreUrl);
    try {
      if (await canLaunchUrl(marketUri)) {
        await launchUrl(marketUri, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(webUri)) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Erro ao abrir a Play Store: $e');
    }
  }
}

