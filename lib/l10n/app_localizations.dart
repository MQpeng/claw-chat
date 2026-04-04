import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales: an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the value field. This list
/// should match the list of supported locales on this method.
///
/// See https://developer.apple.com/documentation/Xcode/adding-支持语言-to-your-xcode-project
/// for more information.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// is preferred.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh')
  ];

  /// No description provided for @connectToOpenClaw.
  ///
  /// In en, this message translates to:
  /// **'Connect to OpenClaw'**
  String get connectToOpenClaw;

  /// No description provided for @scanQRCodeFromOpenClawWebUI.
  ///
  /// In en, this message translates to:
  /// **'Scan QR code from OpenClaw Web UI\nor enter configuration manually'**
  String get scanQRCodeFromOpenClawWebUI;

  /// No description provided for @scanQRCode.
  ///
  /// In en, this message translates to:
  /// **'Scan QR Code'**
  String get scanQRCode;

  /// No description provided for @manualConfiguration.
  ///
  /// In en, this message translates to:
  /// **'Manual Configuration'**
  String get manualConfiguration;

  /// No description provided for @gatewayURL.
  ///
  /// In en, this message translates to:
  /// **'Gateway URL'**
  String get gatewayURL;

  /// No description provided for @token.
  ///
  /// In en, this message translates to:
  /// **'Token'**
  String get token;

  /// No description provided for @yourPairingToken.
  ///
  /// In en, this message translates to:
  /// **'Your pairing token'**
  String get yourPairingToken;

  /// No description provided for @invalidQRCodeFormat.
  ///
  /// In en, this message translates to:
  /// **'Invalid QR code format'**
  String get invalidQRCodeFormat;

  /// No description provided for @pleaseFillInBothGatewayURLAndToken.
  ///
  /// In en, this message translates to:
  /// **'Please fill in both Gateway URL and Token'**
  String get pleaseFillInBothGatewayURLAndToken;

  /// No description provided for @configurationSaved.
  ///
  /// In en, this message translates to:
  /// **'Configuration saved'**
  String get configurationSaved;

  /// No description provided for @saveAndConnect.
  ///
  /// In en, this message translates to:
  /// **'Save & Connect'**
  String get saveAndConnect;

  /// No description provided for @newSession.
  ///
  /// In en, this message translates to:
  /// **'New Session'**
  String get newSession;

  /// No description provided for @sessionName.
  ///
  /// In en, this message translates to:
  /// **'Session Name'**
  String get sessionName;

  /// No description provided for @enterSessionName.
  ///
  /// In en, this message translates to:
  /// **'Enter session name'**
  String get enterSessionName;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @deleteSession.
  ///
  /// In en, this message translates to:
  /// **'Delete Session'**
  String get deleteSession;

  /// No description provided for @areYouSureYouWantToDelete.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete'**
  String get areYouSureYouWantToDelete;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @renameSession.
  ///
  /// In en, this message translates to:
  /// **'Rename Session'**
  String get renameSession;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @themeMode.
  ///
  /// In en, this message translates to:
  /// **'Theme Mode'**
  String get themeMode;

  /// No description provided for @followSystem.
  ///
  /// In en, this message translates to:
  /// **'Follow system'**
  String get followSystem;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @clearAllSessions.
  ///
  /// In en, this message translates to:
  /// **'Clear All Sessions'**
  String get clearAllSessions;

  /// No description provided for @deleteAllSessionsAndMessages.
  ///
  /// In en, this message translates to:
  /// **'Delete all sessions and messages'**
  String get deleteAllSessionsAndMessages;

  /// No description provided for @thisActionCannotBeUndone.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone'**
  String get thisActionCannotBeUndone;

  /// No description provided for @allDataCleared.
  ///
  /// In en, this message translates to:
  /// **'All data cleared'**
  String get allDataCleared;

  /// No description provided for @reconnectToOpenClaw.
  ///
  /// In en, this message translates to:
  /// **'Reconnect to OpenClaw'**
  String get reconnectToOpenClaw;

  /// No description provided for @disconnectAndReconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect and reconnect'**
  String get disconnectAndReconnect;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @openClaw.
  ///
  /// In en, this message translates to:
  /// **'OpenClaw'**
  String get openClaw;

  /// No description provided for @lightweightFlutterMobileClient.
  ///
  /// In en, this message translates to:
  /// **'Lightweight Flutter mobile client for OpenClaw\nConnect directly to your OpenClaw Gateway via LAN/Tailscale'**
  String get lightweightFlutterMobileClient;

  /// No description provided for @selectASessionToStartChatting.
  ///
  /// In en, this message translates to:
  /// **'Select a session to start chatting'**
  String get selectASessionToStartChatting;

  /// No description provided for @notConnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get notConnected;

  /// No description provided for @searchSessions.
  ///
  /// In en, this message translates to:
  /// **'Search Sessions'**
  String get searchSessions;

  /// No description provided for @createNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get createNew;

  /// No description provided for @pairing.
  ///
  /// In en, this message translates to:
  /// **'Connecting'**
  String get pairing;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @pleaseSelectASessionFirst.
  ///
  /// In en, this message translates to:
  /// **'Please select a session first'**
  String get pleaseSelectASessionFirst;

  /// No description provided for @notConnectedToOpenClaw.
  ///
  /// In en, this message translates to:
  /// **'Not connected to OpenClaw'**
  String get notConnectedToOpenClaw;

  /// No description provided for @addAttachment.
  ///
  /// In en, this message translates to:
  /// **'Add attachment'**
  String get addAttachment;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @cameraPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Camera permission is required for scanning QR code'**
  String get cameraPermissionRequired;

  /// No description provided for @storagePermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Storage permission is required for selecting files'**
  String get storagePermissionRequired;

  /// No description provided for @invalidQR.
  ///
  /// In en, this message translates to:
  /// **'Invalid QR code'**
  String get invalidQR;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loading;

  /// No description provided for @scanQrOrEnterManually.
  ///
  /// In en, this message translates to:
  /// **'Scan QR code or enter manually'**
  String get scanQrOrEnterManually;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get or;

  /// No description provided for @invalidQrCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid QR code'**
  String get invalidQrCode;

  /// No description provided for @scanQrCode.
  ///
  /// In en, this message translates to:
  /// **'Scan QR Code'**
  String get scanQrCode;

  /// No description provided for @showToken.
  ///
  /// In en, this message translates to:
  /// **'Show token'**
  String get showToken;

  /// No description provided for @hideToken.
  ///
  /// In en, this message translates to:
  /// **'Hide token'**
  String get hideToken;

  /// No description provided for @connect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;

  /// No description provided for @disconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get disconnected;

  /// No description provided for @connecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting'**
  String get connecting;

  /// No description provided for @connected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// No description provided for @connectionError.
  ///
  /// In en, this message translates to:
  /// **'Connection Error'**
  String get connectionError;

  /// No description provided for @openClawMobileClient.
  ///
  /// In en, this message translates to:
  /// **'OpenClaw Mobile Client'**
  String get openClawMobileClient;

  /// No description provided for @chat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chat;

  /// No description provided for @skills.
  ///
  /// In en, this message translates to:
  /// **'Skills'**
  String get skills;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get noData;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @voice.
  ///
  /// In en, this message translates to:
  /// **'Voice'**
  String get voice;

  /// No description provided for @screen.
  ///
  /// In en, this message translates to:
  /// **'Screen'**
  String get screen;

  /// No description provided for @cameraPermissionPermanentlyDenied.
  ///
  /// In en, this message translates to:
  /// **'Camera permission has been permanently denied. Please enable it in app settings.'**
  String get cameraPermissionPermanentlyDenied;

  /// No description provided for @storagePermissionPermanentlyDenied.
  ///
  /// In en, this message translates to:
  /// **'Storage permission has been permanently denied. Please enable it in app settings.'**
  String get storagePermissionPermanentlyDenied;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get chooseFromGallery;

  /// No description provided for @chooseFile.
  ///
  /// In en, this message translates to:
  /// **'Choose File'**
  String get chooseFile;

  /// No description provided for @notConnectedCannotOpenSession.
  ///
  /// In en, this message translates to:
  /// **'Not connected to OpenClaw Gateway. Cannot open session.'**
  String get notConnectedCannotOpenSession;

  /// No description provided for @notConnectedCannotCreateSession.
  ///
  /// In en, this message translates to:
  /// **'Not connected to OpenClaw Gateway. Cannot create new session.'**
  String get notConnectedCannotCreateSession;

  /// No description provided for @logs.
  ///
  /// In en, this message translates to:
  /// **'Logs'**
  String get logs;

  /// No description provided for @notConnectedWillOpenOffline.
  ///
  /// In en, this message translates to:
  /// **'Not connected. Opening session in offline mode. Will auto-reconnect.'**
  String get notConnectedWillOpenOffline;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @reconnect.
  ///
  /// In en, this message translates to:
  /// **'Reconnect'**
  String get reconnect;

  /// No description provided for @selectModel.
  ///
  /// In en, this message translates to:
  /// **'Select Model'**
  String get selectModel;

  /// No description provided for @themeMode.
  ///
  /// In en, this message translates to:
  /// **'Theme Mode'**
  String get themeMode;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'Follow system'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeColor.
  ///
  /// In en, this message translates to:
  /// **'Theme Color'**
  String get themeColor;

  /// No description provided for @defaultModel.
  ///
  /// In en, this message translates to:
  /// **'Default Model'**
  String get defaultModel;

  /// No description provided for @serverDefault.
  ///
  /// In en, this message translates to:
  /// **'Server default'**
  String get serverDefault;

  /// No description provided for @clearAllData.
  ///
  /// In en, this message translates to:
  /// **'Clear All Data'**
  String get clearAllData;

  /// No description provided for @clearAllDataConfirmation.
  ///
  /// In en, this message translates to:
  /// **'This will delete all sessions and messages.\nThis action cannot be undone.'**
  String get clearAllDataConfirmation;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'claw-chat'**
  String get appName;

  /// No description provided for @aboutText.
  ///
  /// In en, this message translates to:
  /// **'Lightweight Flutter mobile client for OpenClaw\nConnect directly to your OpenClaw Gateway via LAN/Tailscale'**
  String get aboutText;

  /// No description provided for @failedToLoadModels.
  ///
  /// In en, this message translates to:
  /// **'Failed to load models'**
  String get failedToLoadModels;

  /// No description provided for @clientLogs.
  ///
  /// In en, this message translates to:
  /// **'Client Logs'**
  String get clientLogs;

  /// No description provided for @pauseAutoScroll.
  ///
  /// In en, this message translates to:
  /// **'Pause auto-scroll'**
  String get pauseAutoScroll;

  /// No description provided for @resumeAutoScroll.
  ///
  /// In en, this message translates to:
  /// **'Resume auto-scroll'**
  String get resumeAutoScroll;

  /// No description provided for @copyAllLogs.
  ///
  /// In en, this message translates to:
  /// **'Copy all logs'**
  String get copyAllLogs;

  /// No description provided for @clearLogs.
  ///
  /// In en, this message translates to:
  /// **'Clear logs'**
  String get clearLogs;

  /// No description provided for @logsCopied.
  ///
  /// In en, this message translates to:
  /// **'Logs copied to clipboard'**
  String get logsCopied;

  /// No description provided for @noLogsYet.
  ///
  /// In en, this message translates to:
  /// **'No logs yet'**
  String get noLogsYet;

  /// No description provided for @logsWillAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Logs will appear here when app runs'**
  String get logsWillAppearHere;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'zh': return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
