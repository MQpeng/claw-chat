# claw-chat 项目设计文档

## 1. 技术选型

| 层级         | 技术选型                     | 说明                                  |
|--------------|------------------------------|---------------------------------------|
| 框架         | Flutter 3.x                  | 跨平台，一致的体验，高性能            |
| UI 组件库    | chat_ui                      | 现成的聊天 UI 组件，快速开发          |
| 状态管理     | flutter_riverpod / Provider  | 简洁、可测试，适合 Flutter 开发       |
| 网络通信     | dio / web_socket_channel     | HTTP 请求 + WebSocket 流式响应        |
| 本地存储     | shared_preferences + hive   | 配置 + 会话数据存储                   |
| Markdown 渲染| flutter_markdown             | Markdown 消息渲染                     |
| 代码高亮     | highlight / flutter_highlight| 代码块语法高亮                        |
| 图片处理     | cached_network_image         | 图片缓存                              |
| 权限处理     | permission_handler           | 相机、存储权限处理                    |
| 文件选择     | file_picker                  | 文件选择                              |
| PDF 预览     | flutter_pdfview              | PDF 查看                              |

## 2. 项目结构

```
lib/
├── main.dart                    # 入口文件
├── app.dart                     # App 根组件
├── config/
│   └── app_config.dart          # 应用配置
├── core/
│   ├── constants/               # 常量定义
│   ├── theme/                   # 主题相关
│   ├── utils/                   # 工具函数
│   └── errors/                  # 错误处理
├── data/
│   ├── datasources/
│   │   ├── local/               # 本地数据存储
│   │   └── remote/              # 远程数据（OpenClaw API）
│   ├── models/                  # 数据模型
│   │   ├── chat_message.dart    # 消息模型
│   │   ├── chat_session.dart    # 会话模型
│   │   ├── openclaw_event.dart  # OpenClaw 事件模型
│   │   └── file_item.dart       # 文件模型
│   └── repositories/            # 数据仓库
│       ├── session_repository.dart
│       └── message_repository.dart
├── domain/
│   ├── repositories/            # 仓库接口定义
│   └── usecases/                # 用例
│       ├── create_session.dart
│       ├── delete_session.dart
│       ├── send_message.dart
│       ├── upload_file.dart
│       └── connect_openclaw.dart
├── presentation/
│   ├── screens/
│   │   ├── home_screen.dart     # 主屏幕
│   │   ├── chat_screen.dart     # 聊天屏幕
│   │   ├── settings_screen.dart # 设置屏幕
│   │   └── login_screen.dart    # 配对/登录屏幕
│   ├── widgets/
│   │   ├── chat_bubble.dart     # 气泡组件
│   │   ├── session_list.dart    # 会话列表
│   │   ├── input_bar.dart       # 输入栏（含文件选择）
│   │   ├── file_attachment.dart # 文件附件展示
│   │   ├── typing_indicator.dart# 正在输入指示器
│   │   └── ...
│   └── providers/               # Riverpod providers
│       ├── session_provider.dart
│       ├── chat_provider.dart
│       └── connection_provider.dart
└── features/
    ├── openclaw_plugin/         # OpenClaw 插件交互模块
    │   ├── openclaw_client.dart # 客户端
    │   ├── event_parser.dart    # 事件解析
    │   └── methods.dart         # API 方法定义
    └── file_handler/            # 文件处理模块
        ├── file_picker.dart
        ├── file_preview.dart
        └── file_uploader.dart
```

## 3. 数据模型设计

### 3.1 ChatSession（会话）

```dart
class ChatSession {
  final String id;
  String title;
  final DateTime createdAt;
  DateTime updatedAt;
  final String? modelId;
  final int unreadCount;
  final bool isPinned;
  final bool isArchived;
  final String? systemPrompt;
}
```

### 3.2 ChatMessage（消息）

```dart
class ChatMessage {
  final String id;
  final String sessionId;
  final MessageRole role; // user, assistant, system
  final String content;
  final List<FileItem> attachments; // 附件
  final MessageStatus status; // sending, sent, error
  final DateTime createdAt;
  final Map<String, dynamic>? metadata; // 额外信息
}
```

### 3.3 FileItem（文件）

```dart
class FileItem {
  final String id;
  final String name;
  final int size;
  final String type; // image, video, audio, document
  final String? localPath;
  final String? remoteUrl;
  final String? previewUrl;
}
```

## 4. 模块职责

### 4.1 OpenClaw 插件交互模块

负责与 OpenClaw 服务端通信：
- 处理连接建立和断开
- 发送用户消息
- 接收流式响应并解析
- 处理工具调用事件
- 文件上传下载接口

**关键类：**
- `OpenClawClient` - 客户端封装
- `OpenClawEventParser` - SSE 或 WebSocket 事件解析

### 4.2 文件处理模块

- 文件选择（相册、相机、文件管理器）
- 权限检查
- 上传进度管理
- 不同类型文件的预览
- 下载到本地

### 4.3 会话管理模块

- CRUD 会话
- 会话列表排序（置顶 > 更新时间）
- 搜索过滤
- 本地持久化存储

### 4.4 聊天界面模块

- 使用 `chat_ui` 组件库构建基础聊天界面
- 自定义气泡样式适配需求
- 处理输入和提交
- 渲染富文本消息

## 5. 通信流程

### 发送消息流程

```
用户输入 → 点击发送 → 创建本地消息（状态：sending）→ 
调用 OpenClawClient.sendMessage → 流式接收回复 → 
逐块更新 AI 消息 → 接收完成 → 状态更新为 sent
```

### 文件上传流程

```
用户点击附件 → 选择文件 → 创建 FileItem → 添加到消息 → 
上传到 OpenClaw → 获取远程 URL → 发送消息（包含附件信息）
```

### 多会话切换流程

```
用户点击会话列表项 → 更新当前选中 sessionId → 
从本地存储加载该会话消息 → 渲染聊天界面 → 滚动到底部
```

## 6. 风格约定

- 使用 Flutter 官方推荐的风格
- 命名：lowerCamelCase 变量/方法，UpperCamelCase 类/组件
- Widget 拆分为小组件，保持单一职责
- 注释：公共 API 需要文档注释，复杂逻辑需要说明
- 使用 flutter_lint 进行静态检查

## 7. 开发路线图

### Phase 1: 基础结构（v0.1.0）
- [ ] 项目初始化，配置 Flutter 环境
- [ ] 基础目录结构搭建
- [ ] 主题设置，明暗主题支持
- [ ] 配对/登录页面开发

### Phase 2: 核心聊天功能（v0.2.0）
- [ ] 会话列表开发
- [ ] 聊天界面基础开发，集成 chat_ui
- [ ] OpenClaw 基础连接和消息发送接收
- [ ] 流式响应支持

### Phase 3: 文件功能（v0.3.0）
- [ ] 文件选择和上传
- [ ] 图片预览
- [ ] 音视频播放
- [ ] 文档预览（PDF 优先）
- [ ] 文件下载

### Phase 4: 优化完善（v0.4.0）
- [ ] Markdown 渲染和代码高亮
- [ ] 消息操作（复制、删除、重新生成）
- [ ] 会话搜索、置顶、归档
- [ ] 性能优化
- [ ] Bug 修复

### Phase 5: 发布测试（v1.0.0）
- [ ] 多平台打包测试
- [ ] UI 完善
- [ ] 用户测试
- [ ] 正式发布
