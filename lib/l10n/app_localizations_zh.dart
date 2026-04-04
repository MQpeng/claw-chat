// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get connectToOpenClaw => '连接 OpenClaw';

  @override
  String get scanQRCodeFromOpenClawWebUI => '从 OpenClaw 网页扫码\n或手动输入配置';

  @override
  String get scanQRCode => '扫描二维码';

  @override
  String get manualConfiguration => '手动配置';

  @override
  String get gatewayURL => '网关地址';

  @override
  String get token => '令牌';

  @override
  String get yourPairingToken => '配对令牌';

  @override
  String get invalidQRCodeFormat => '二维码格式无效';

  @override
  String get pleaseFillInBothGatewayURLAndToken => '请填写网关地址和令牌';

  @override
  String get configurationSaved => '配置已保存';

  @override
  String get saveAndConnect => '保存并连接';

  @override
  String get newSession => '新建会话';

  @override
  String get sessionName => '会话名称';

  @override
  String get enterSessionName => '输入会话名称';

  @override
  String get create => '创建';

  @override
  String get deleteSession => '删除会话';

  @override
  String get areYouSureYouWantToDelete => '确认删除会话';

  @override
  String get cancel => '取消';

  @override
  String get delete => '删除';

  @override
  String get renameSession => '重命名会话';

  @override
  String get save => '保存';

  @override
  String get settings => '设置';

  @override
  String get themeMode => '主题模式';

  @override
  String get followSystem => '跟随系统';

  @override
  String get light => '浅色';

  @override
  String get dark => '深色';

  @override
  String get clearAllSessions => '清空所有会话';

  @override
  String get deleteAllSessionsAndMessages => '删除所有会话和消息';

  @override
  String get thisActionCannotBeUndone => '此操作无法撤销';

  @override
  String get allDataCleared => '所有数据已清空';

  @override
  String get reconnectToOpenClaw => '重新连接 OpenClaw';

  @override
  String get disconnectAndReconnect => '断开并重连';

  @override
  String get version => '版本';

  @override
  String get openClaw => 'OpenClaw';

  @override
  String get lightweightFlutterMobileClient => 'OpenClaw 轻量级 Flutter 移动客户端\n直接连接到你的 OpenClaw 网关，通过 LAN/Tailscale 直连';

  @override
  String get selectASessionToStartChatting => '选择一个会话开始聊天';

  @override
  String get notConnected => '未连接';

  @override
  String get searchSessions => '搜索会话';

  @override
  String get createNew => '新建';

  @override
  String get pairing => '配对中';

  @override
  String get error => '错误';

  @override
  String get pleaseSelectASessionFirst => '请先选择一个会话';

  @override
  String get notConnectedToOpenClaw => '未连接到 OpenClaw';

  @override
  String get addAttachment => '添加附件';

  @override
  String get send => '发送';

  @override
  String get cameraPermissionRequired => '扫码需要相机权限';

  @override
  String get storagePermissionRequired => '选择文件需要存储权限';

  @override
  String get invalidQR => '二维码无效';

  @override
  String get loading => '加载中';

  @override
  String get scanQrOrEnterManually => '扫描二维码或手动输入';

  @override
  String get or => '或';

  @override
  String get invalidQrCode => '二维码无效';

  @override
  String get scanQrCode => '扫描二维码';

  @override
  String get showToken => '显示令牌';

  @override
  String get hideToken => '隐藏令牌';

  @override
  String get connect => '连接';

  @override
  String get disconnected => '未连接';

  @override
  String get connecting => '连接中';

  @override
  String get connected => '已连接';

  @override
  String get connectionError => '连接错误';

  @override
  String get openClawMobileClient => 'OpenClaw 移动端';

  @override
  String get chat => '聊天';

  @override
  String get skills => '技能';

  @override
  String get refresh => '刷新';

  @override
  String get noData => '无数据';

  @override
  String get retry => '重试';

  @override
  String get selectModel => '选择模型';

  @override
  String get voice => '语音';

  @override
  String get screen => '投屏';

  @override
  String get cameraPermissionPermanentlyDenied => '相机权限已被永久拒绝，请在应用设置中开启。';

  @override
  String get storagePermissionPermanentlyDenied => '存储权限已被永久拒绝，请在应用设置中开启。';

  @override
  String get openSettings => '打开设置';

  @override
  String get takePhoto => '拍照';

  @override
  String get chooseFromGallery => '从相册选择';

  @override
  String get chooseFile => '选择文件';

  @override
  String get notConnectedCannotOpenSession => '未连接到 OpenClaw Gateway，无法打开会话。';

  @override
  String get notConnectedCannotCreateSession => '未连接到 OpenClaw Gateway，无法新建会话。';

  @override
  String get logs => '日志';

  @override
  String get notConnectedWillOpenOffline => '未连接，将以离线模式打开会话，将自动重连。';

  @override
  String get ok => '确定';

  @override
  String get reconnect => '重连';

  @override
  String get themeSystem => '跟随系统';

  @override
  String get themeLight => '浅色';

  @override
  String get themeDark => '深色';

  @override
  String get themeColor => '主题颜色';

  @override
  String get defaultModel => '默认模型';

  @override
  String get serverDefault => '服务器默认';

  @override
  String get clearAllData => '清空所有数据';

  @override
  String get clearAllDataConfirmation => '这会删除所有会话和消息。\n此操作无法撤销。';

  @override
  String get clear => '清空';

  @override
  String get appName => 'claw-chat';

  @override
  String get aboutText => 'OpenClaw 轻量级 Flutter 移动客户端\n通过 LAN/Tailscale 直接连接你的 OpenClaw 网关';

  @override
  String get failedToLoadModels => '加载模型失败';

  @override
  String get clientLogs => '客户端日志';

  @override
  String get pauseAutoScroll => '暂停自动滚动';

  @override
  String get resumeAutoScroll => '恢复自动滚动';

  @override
  String get copyAllLogs => '复制所有日志';

  @override
  String get clearLogs => '清空日志';

  @override
  String get logsCopied => '日志已复制到剪贴板';

  @override
  String get noLogsYet => '暂无日志';

  @override
  String get logsWillAppearHere => '运行时日志会显示在这里';
}
