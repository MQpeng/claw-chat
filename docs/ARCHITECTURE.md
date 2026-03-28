# claw-chat 架构设计文档

## 项目整体架构

claw-chat 采用 Flutter + Riverpod 作为技术栈，遵循分层架构设计，分为：

```
lib/
├── core/            # 核心工具、常量、通用组件
├── data/            # 数据层
│   ├── datasource/  # 数据源（本地、远程）
│   └── repository/  # 数据仓库
├── domain/          # 领域层
│   ├── entities/    # 实体模型
│   └── repositories/ # 仓库接口定义
├── presentation/    # 表现层
│   ├── pages/       # 页面
│   ├── widgets/     # 组件
│   ├── providers/   # Riverpod 状态管理
│   └── themes/      # 主题配置
└── main.dart        # 入口
```

## 技术选型

| 模块 | 技术选型 | Pub 热门度 | 说明 |
|------|---------|------------|------|
| 框架 | Flutter | - | 跨平台 UI 框架 |
| 状态管理 | [flutter_riverpod](https://pub.dev/packages/flutter_riverpod) | ⭐ 6.4k+ likes | 简洁、可测试的状态管理，社区活跃度高 |
| 网络 | [dio](https://pub.dev/packages/dio) | ⭐ 9.3k+ likes | 强大的 HTTP 请求库，支持拦截器、文件上传下载 |
| WebSocket | [web_socket_channel](https://pub.dev/packages/web_socket_channel) | ⭐ 3.4k+ likes | Dart 官方维护，流式 WebSocket 通信 |
| QR 扫码 | [mobile_scanner](https://pub.dev/packages/mobile_scanner) | ⭐ 1.2k+ likes | 目前最活跃的 Flutter 扫码库，支持相机预览，比 deprecated 的 qr_code_scanner 更好 |
| QR 生成 | [qr_flutter](https://pub.dev/packages/qr_flutter) | ⭐ 2.8k+ likes | 生成二维码，这里用不到，但后续服务端界面可能需要 |
| 本地存储 | [shared_preferences](https://pub.dev/packages/shared_preferences) | ⭐ 11.7k+ likes | Flutter 官方，存储简单键值对配置 |
| 结构化存储 | [hive](https://pub.dev/packages/hive) | ⭐ 8.2k+ likes | 轻量级 NoSQL 存储，适合移动端存储消息和会话，速度快 |
| Markdown 渲染 | [flutter_markdown](https://pub.dev/packages/flutter_markdown) | ⭐ 2.5k+ likes | Flutter 官方维护，稳定渲染 Markdown |
| 代码高亮 | [flutter_highlight](https://pub.dev/packages/flutter_highlight) | ⭐ 620+ likes | 配合 flutter_markdown 实现代码块高亮 |
| 数学公式渲染 | [flutter_math_fork](https://pub.dev/packages/flutter_math_fork) | ⭐ 260+ likes | 支持 TeX 公式渲染，部分 AI 回复会包含数学公式 |
| 网络图片缓存 | [cached_network_image](https://pub.dev/packages/cached_network_image) | ⭐ 7.5k+ likes | 流行的网络图片缓存和加载组件 |
| 文件选择 | [file_picker](https://pub.dev/packages/file_picker) | ⭐ 3.9k+ likes | 跨平台文件选择支持，社区活跃维护 |
| 拍照选择图片 | [image_picker](https://pub.dev/packages/image_picker) | ⭐ 11.1k+ likes | Flutter 官方，相机拍照和相册选图 |
| PDF 预览 | [flutter_pdfview](https://pub.dev/packages/flutter_pdfview) | ⭐ 1.3k+ likes | Android/iOS 预览 PDF 文件，基于原生控件 |
| 权限处理 | [permission_handler](https://pub.dev/packages/permission_handler) | ⭐ 5.7k+ likes | 请求运行时权限（相机、存储等）|
| 路径获取 | [path_provider](https://pub.dev/packages/path_provider) | ⭐ 12.8k+ likes | Flutter 官方，获取应用存储目录 |
| 打开文件 | [open_file](https://pub.dev/packages/open_file) | ⭐ 2.3k+ likes | 调用系统打开已下载文件 |
| 链接打开 | [url_launcher](https://pub.dev/packages/url_launcher) | ⭐ 13.7k+ likes | Flutter 官方，打开外部链接到浏览器 |
| JSON 序列化 | [json_annotation](https://pub.dev/packages/json_annotation) | ⭐ 2.5k+ likes | Dart 官方，配合 build_runner 序列化 JSON |
| 屏幕自适应 | [flutter_screenutil](https://pub.dev/packages/flutter_screenutil) | ⭐ 4.7k+ likes | 适配不同尺寸屏幕，统一设计稿尺寸 |
| 图标库 | [font_awesome_flutter](https://pub.dev/packages/font_awesome_flutter) | ⭐ 4.8k+ likes | 提供丰富的图标，社区广泛使用 |
| 浮动操作按钮 | [flutter_speed_dial](https://pub.dev/packages/flutter_speed_dial) | ⭐ 1.1k+ likes | 多级悬浮按钮，用于附件选择菜单 |
| 消息气泡 | [chat_bubbles](https://pub.dev/packages/chat_bubbles) | ⭐ 1.3k+ likes | 简单易用，成熟稳定的聊天气泡组件，支持 WhatsApp 风格气泡，可自定义颜色和圆角，满足聊天需求 |
| 多行扩展输入框 | [auto_size_text_field](https://pub.dev/packages/auto_size_text_field) | ⭐ 500+ likes | 轻量的自动增长高度多行输入框，完美匹配聊天输入场景，用法和原生TextField一致 |
| 设备信息 | [device_info_plus](https://pub.dev/packages/device_info_plus) | ⭐ 2.1k+ likes | 获取设备信息用于日志和调试 |
| 日志 | [logger](https://pub.dev/packages/logger) | ⭐ 2.4k+ likes | 美观且易用的日志打印 |
| 代码规范 | [flutter_lints](https://pub.dev/packages/flutter_lints) | ⭐ 6.0k+ likes | Flutter 官方推荐，包含静态代码检查规则 |
| UI 基础组件库 | [fluent_ui](https://pub.dev/packages/fluent_ui) | ⭐ 3.2k+ likes | Windows 风格设计规范流畅，适配桌面端表现好。适配移动端也没问题，满足我们大部分基础 UI 需求 |
| 消息气泡 | [chat_bubbles](https://pub.dev/packages/chat_bubbles) | ⭐ 1.3k+ likes | 简单易用，成熟稳定的聊天气泡组件，支持 WhatsApp 风格气泡，可自定义颜色和圆角，满足聊天需求 |
| Markdown 渲染 | [flutter_markdown](https://pub.dev/packages/flutter_markdown) | ⭐ 2.5k+ likes | Flutter 官方维护，稳定渲染 Markdown 格式的聊天内容 |
| 代码块高亮 | [flutter_highlight](https://pub.dev/packages/flutter_highlight) | ⭐ 620+ likes | 配合 flutter_markdown 实现代码块语法高亮 |
| 数学公式渲染 | [flutter_math_fork](https://pub.dev/packages/flutter_math_fork) | ⭐ 260+ likes | 支持 TeX 公式渲染，AI 回复可能包含数学公式 |
| 网络图片展示缓存 | [cached_network_image](https://pub.dev/packages/cached_network_image) | ⭐ 7.5k+ likes | 聊天中展示图片，带缓存功能 |
| 对话框/Toast | [fluttertoast](https://pub.dev/packages/fluttertoast) | ⭐ 4.4k+ likes | 简单易用的 Toast 提示 |
| 下拉刷新上拉加载 | [pull_to_refresh_flutter3](https://pub.dev/packages/pull_to_refresh_flutter3) | ⭐ 660+ likes | 活跃维护的下拉刷新组件，支持多种指示器样式，用于消息/会话列表 |
| 侧滑删除 | [flutter_slidable](https://pub.dev/packages/flutter_slidable) | ⭐ 2.9k+ likes | 成熟的侧滑菜单组件，用于会话列表侧滑操作 |
| 选择器 | [flutter_picker](https://pub.dev/packages/flutter_picker) | ⭐ 1.4k+ likes | 滚动选择器，可用于选择分组、主题等 |
| 弹性拖拽排序 | [reorderables](https://pub.dev/packages/reorderables) | ⭐ 1.3k+ likes | 支持拖拽重排的列表/网格，会话管理拖拽排序 |
| 空状态组件 | [empty_widget](https://pub.dev/packages/empty_widget) | ⭐ 220+ likes | 快速实现列表空状态（无会话/无消息）展示 |
| 输入法表情选择 | [emoji_picker_flutter](https://pub.dev/packages/emoji_picker_flutter) | ⭐ 1.3k+ likes | 提供 emoji 选择面板，可选，不做也可以用系统输入法 |
| 深色模式切换 | 原生 Flutter 能力 | - | Flutter 原生支持系统深色模式切换，无需额外轮子 |
| 输入框多行扩展 | 原生 TextField 能力 | - | Flutter TextField 自带最大行数限制扩展，不用轮子 |

## 配对流程设计

### 1. 配对入口
首次打开应用时，如果没有保存的配置，自动进入配对页面。

### 2. 配对方式
提供两种配对方式：
- **QR 扫码配对**（推荐）
- **手动输入配置**

### 3. QR 扫码配对流程

```
用户点击"扫码配对"
  ↓
请求相机权限
  ↓
权限拒绝 → 提示用户需要相机权限才能扫码，引导去应用设置开启
  ↓
权限允许 → 打开 QR 扫码视图
  ↓
扫描 OpenClaw Web UI 中的配对二维码
  ↓
解析二维码得到 `gatewayUrl` 和 `token`
  ↓
自动保存配置到本地
  ↓
自动发起连接测试
  ↓
连接成功 → 进入主聊天界面
连接失败 → 显示错误提示，允许用户修改配置重试
```

### 4. 二维码格式
配对二维码为 JSON 格式：

```json
{
  "url": "https://your-openclaw-gateway.com",
  "token": "your-bootstrap-token"
}
```

### 5. 手动输入配对流程

```
用户点击"手动配置"
  ↓
显示输入表单：
  - Gateway URL 输入框
  - Token 输入框
  - "测试连接"按钮
  ↓
用户输入信息后点击测试连接
  ↓
测试连接成功 → 保存配置进入主界面
测试连接失败 → 显示错误，允许修改重试
```

### 6. 已有配置
如果本地已有保存的配置，应用启动后自动连接 OpenClaw Gateway，进入主聊天界面。如果连接失败，显示错误并允许重新配对。

## 数据模型设计

### 1. ChatSession（会话）

```dart
class ChatSession {
  final String id;
  String name;
  final DateTime createdAt;
  DateTime updatedAt;
  bool isPinned;
  bool isArchived;
  int unreadCount;
}
```

### 2. ChatMessage（消息）

```dart
class ChatMessage {
  final String id;
  final String sessionId;
  final MessageRole role; // user / assistant / system
  final String content;
  final DateTime createdAt;
  MessageStatus status; // sending / sent / error
  final List<FileItem> attachments; // 附件列表
}
```

### 3. FileItem（文件附件）

```dart
class FileItem {
  final String id;
  final String name;
  final int size;
  final String url; // 远程 URL
  final String? localPath; // 本地路径（下载后）
  final String mimeType;
  final FileItemType type; // image / video / audio / pdf / other
}
```

## OpenClaw 通信协议

### 1. 连接建立
通过 WebSocket 连接到 Gateway：
```
ws://<gateway-url>/ws
```
请求头携带认证 Token：
```
Authorization: Bearer <token>
```

### 2. 发送消息
发送 JSON 格式的请求：
```json
{
  "type": "chat",
  "id": "<message-id>",
  "sessionId": "<session-id>",
  "content": "<message-text>",
  "attachments": [...]
}
```

### 3. 接收流式响应
逐块接收助手回复，通过事件回调更新 UI：
```json
{
  "type": "chunk",
  "id": "<message-id>",
  "chunk": "<text-chunk>"
}
```

```json
{
  "type": "done",
  "id": "<message-id>"
}
```

```json
{
  "type": "tool_call",
  "id": "<message-id>",
  "tool": "...",
  "params": {...}
}
```

```json
{
  "type": "error",
  "id": "<message-id>",
  "message": "<error-message>"
}
```

## 状态管理设计

使用 Riverpod Provider 划分状态：

| Provider | 作用 |
|----------|------|
| `themeProvider` | 主题状态（亮色/暗色） |
| `connectionProvider` | OpenClaw 连接状态 |
| `sessionListProvider` | 会话列表 |
| `currentSessionIdProvider` | 当前选中的会话 ID |
| `currentSessionProvider` | 当前会话对象 |
| `chatMessagesProvider` | 当前会话消息列表 |
| `sessionSearchQueryProvider` | 会话搜索关键词 |
| `filteredSessionsProvider` | 搜索过滤后的会话列表 |

## 页面路由设计

| 页面 | 说明 |
|------|------|
| `PairingPage` | 配对/登录页面 |
| `ChatPage` | 主聊天页面（包含会话侧边栏） |
| `SettingsPage` | 设置页面 |

## 主题设计

- 使用 Flutter `ThemeData` 定义亮色和暗色主题
- 使用 `themeProvider` 保存当前主题选择
- 提供切换主题功能，保存选择到本地 `shared_preferences`
- 支持跟随系统主题自动切换

## 存储设计

- **shared_preferences**: 存储主题设置、字体大小、连接配置
- **Hive**: 存储会话列表、消息列表、文件信息
  - 不需要复杂的 SQL 查询，Hive 轻量快速，适合移动端存储结构化数据
  - 内置对象适配器，不需要额外的代码生成（也支持生成）

## 整体交互流程

```
启动 App
  ↓
读取本地配置
  ↓
无配置 → 进入 PairingPage
有配置 → 自动连接 Gateway
    ↓
    连接成功 → 进入 ChatPage
    连接失败 → 显示错误 → 返回 PairingPage
  ↓
PairingPage → 用户完成配对/手动配置
  ↓
连接测试成功 → 保存配置 → 进入 ChatPage
  ↓
ChatPage
  ↓
展示会话列表 + 当前会话消息
  ↓
用户发送消息 → 通过 WebSocket 发送 → 接收流式响应 → 更新 UI
  ↓
可以随时进入设置页面修改配置、切换主题、清理缓存
```

## 配色方案建议

- 主色调：蓝色系 (#2196F3)，代表科技、可靠
- 背景：
  - 亮色：白色 / 浅灰色
  - 暗色：深灰色 / 黑色
- 用户气泡：主蓝色，文字白色
- 助手气泡：灰色，文字黑色/白色（根据主题）

## 适配说明

- 优先适配 Android 手机（当前需求只开发 Android）
- 支持竖屏和横屏
- 大屏幕平板自动调整布局（会话侧边栏默认显示）
