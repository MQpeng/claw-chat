// GENERATED CODE - DO NOT MODIFY BY HAND

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

/// Callers can lookup localized strings with an instance of AppLocalizations returned
/// by `AppLocalizations.of(context)`.
///
/// Applications need to include translation delegate in their [App] widget:
///
/// ```dart
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   title: 'claw-chat',
/// );
/// ```
abstract class AppLocalizations {
  AppLocalizations();

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static List<LocalizationsDelegate<dynamic>> get localizationsDelegates =>
      <LocalizationsDelegate<dynamic>>[
    delegate,
  ];

  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  String get connectToOpenClaw;

  String get scanQRCodeFromOpenClawWebUI;

  String get scanQRCode;

  String get manualConfiguration;

  String get gatewayURL;

  String get token;

  String get yourPairingToken;

  String get invalidQRCodeFormat;

  String get pleaseFillInBothGatewayURLAndToken;

  String get configurationSaved;

  String get saveAndConnect;

  String get newSession;

  String get sessionName;

  String get enterSessionName;

  String get create;

  String get deleteSession;

  String get areYouSureYouWantToDelete;

  String get cancel;

  String get delete;

  String get renameSession;

  String get save;

  String get settings;

  String get themeMode;

  String get followSystem;

  String get light;

  String get dark;

  String get clearAllSessions;

  String get deleteAllSessionsAndMessages;

  String get thisActionCannotBeUndone;

  String get allDataCleared;

  String get reconnectToOpenClaw;

  String get disconnectAndReconnect;

  String get version;

  String get openClaw;

  String get lightweightFlutterMobileClient;

  String get selectASessionToStartChatting;

  String get notConnected;

  String get searchSessions;

  String get createNew;

  String get pairing;

  String get error;

  String get pleaseSelectASessionFirst;

  String get notConnectedToOpenClaw;

  String get addAttachment;

  String get send;

  String get cameraPermissionRequired;

  String get storagePermissionRequired;

  String get invalidQR;

  String get loading;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  SynchronousFuture<AppLocalizations> load(Locale locale) {
    switch (locale.languageCode) {
      case 'zh':
        return SynchronousFuture<AppLocalizations>(
          AppLocalizationsZh(),
        );
      case 'en':
      default:
        return SynchronousFuture<AppLocalizations>(
          AppLocalizationsEn(),
        );
    }
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
