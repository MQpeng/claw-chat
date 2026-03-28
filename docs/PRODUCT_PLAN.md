# claw-chat 产品规划

## 产品定位

**OpenClaw 客户端**：现代化的桌面/Web 客户端，提供媲美 ChatGPT 的聊天体验，同时支持办公/媒体文件预览，插件化架构支持 `openclaw plugins install` 扩展能力，作为 OpenClaw 的前端消息通道。

## 核心价值

- 🎨 **现代化 AI 聊天体验**：流畅的对话界面，支持流式输出、代码高亮、Markdown 渲染
- 📎 **丰富的文件支持**：办公文档、图片、音视频等媒体文件直接预览
- 🔌 **插件化架构**：兼容 OpenClaw 插件生态，插件可直接与客户端通信
- 🌐 **真跨平台**：支持 Android/iOS 移动端 + Windows/macOS/Linux 桌面 + Web，一处开发多端运行
- 🚀 **原生性能**：Flutter 自绘引擎，接近原生性能体验
- 🎨 **成熟聊天组件**：chat_ui 开箱即用，快速搭建专业聊天界面
- 🧠 **原生集成 OpenClaw**：直接与本地 OpenClaw 核心通信，享受完整能力

## 核心功能

### 一、聊天界面（核心体验）

#### 1. 对话管理
- **会话列表**：左侧展示历史会话，支持搜索、星标、分组
- **新建会话**：一键开始新对话
- **会话编辑**：重命名、删除、归档
- **上下文记忆**：自动保留对话上下文

#### 2. 消息展示
- **Markdown 完整渲染**：标题、列表、表格、引用、任务列表
- **代码高亮**：支持主流编程语言，带行号和复制按钮
- **流式输出**：类似 ChatGPT 的逐字显示效果
- **思考过程折叠/展开**：支持显示模型推理过程（可折叠）
- **LaTeX 公式支持**：科学计算和数学公式渲染
- **Mermaid 图表支持**：流程图、时序图直接渲染
- **消息表情反应**：支持对消息添加表情回应
- **复制/重新生成/收藏**：消息操作快捷按钮

#### 3. 用户输入
- **多行编辑**：支持 Shift+Enter 换行
- **自动完成**：命令和 @ 提及自动补全
- **文件上传**：拖拽或点击上传文件
- **提示词模板**：支持保存和快速选择常用提示词
- **语音输入**（可选）：浏览器原生语音识别

### 二、文件预览能力

| 文件类型 | 支持能力 |
|---------|---------|
| **图片** | JPG/PNG/GIF/WebP 直接预览，支持缩放 |
| **PDF** | 在线预览，翻页、缩放 |
| **Word** | `.docx` 文本和格式预览 |
| **Excel** | `.xlsx` 表格预览 |
| **PowerPoint** | `.pptx` 幻灯片预览 |
| **纯文本** | 各种代码/文本文件直接显示 |
| **音频** | MP3/WAV 在线播放 |
| **视频** | MP4/WebM 在线播放 |
| **SVG** | 矢量图预览 |

### 三、插件系统

#### 1. OpenClaw 插件集成
- 兼容 `openclaw plugins install` 安装机制
- 插件可向客户端注册 UI 扩展点
- 插件可以：
  - 自定义命令
  - 添加侧边栏面板
  - 处理特定类型文件
  - 提供自定义工具界面
- 插件与客户端通过 JSON-RPC 通信

#### 2. 插件通信协议
- 客户端 ↔ OpenClaw ↔ 插件 三层通信
- 插件可以主动发送消息到客户端
- 客户端事件（如文件上传、消息发送）可触发插件
- 支持插件自定义 UI 组件（通过 WebView 或者 Flutter 桥接）

#### 3. 插件商店/列表
- 已安装插件展示
- 插件启用/禁用/卸载
- 浏览可用插件（从 clawhub.ai）

### 四、设置与配置

- **API / 连接设置**：配置 OpenClaw 服务地址
- **外观主题**：亮色/暗色/自动跟随系统
- **字体大小**：可调节
- **消息发送快捷键**：Enter / Ctrl+Enter 可选
- **数据存储位置**：会话历史本地存储路径配置

### 五、高级功能

- **全局搜索**：搜索所有历史会话和消息内容
- **导出对话**：导出为 Markdown/PDF/HTML
- **分享对话**：生成可分享链接（需要服务端支持）
- **多标签页**：同时打开多个对话
- **多人协作**（未来）：多个用户同一会话协作

## 技术架构

### 整体分层
```
┌─────────────────────────────────────────────┐
│                 claw-chat (Flutter)          │
│  - chat_ui 组件 + 文件预览                   │
│  - 跨平台原生 UI                              │
└──────────────┬──────────────────────────────┘
               │ HTTP / WebSocket
┌──────────────▼──────────────────────────────┐
│             OpenClaw Core (本地/远程)         │
│  - 消息处理                                   │
│  - 插件管理                                   │
│  - 工具执行                                   │
└──────────────┬──────────────────────────────┘
               │ IPC / 调用
┌──────────────▼──────────────────────────────┐
│              OpenClaw Plugins                │
│  - 自定义能力                                 │
│  - 结果返回客户端                              │
└─────────────────────────────────────────────┘
```

### 技术栈选型

**框架**：Flutter（跨平台，一次开发支持移动端、桌面、Web）
- 原生性能好，跨平台一致性好，适合客户端应用

**UI 组件库**：
- 核心聊天组件：[chat_ui](https://pub.dev/packages/chat_ui)（提供成熟的消息气泡、列表、输入组件，开箱即用）
- 补充：flutter_screenutil（适配不同屏幕尺寸）
- 图标：font_awesome_flutter

**Markdown 渲染**：
- flutter_markdown（官方推荐，支持 GFM）
- highlight 支持代码高亮

**文件预览**：
- PDF：flutter_pdfview
- 图片：原生 Image 组件 + photo_view 手势缩放
- Office：
  - docx: docx_reader → 转 widget 展示
  - excel: excel_reader → 表格展示
  - ppt: 转为图片预览
- 音视频：video_player（官方） + audioplayers

**状态管理**：
- Bloc / Cubit（推荐，可测试、可预测，适合中大型项目）
- 备选：Provider + ChangeNotifier（更轻量）

**网络通信**：
- dio（HTTP 请求，成熟稳定）
- web_socket_channel（WebSocket 支持流式输出）

**存储**：
- 配置存储：shared_preferences
- 数据库：isar（高性能 NoSQL 本地存储，存储会话历史）
- 文件缓存：path_provider + 原生文件 API

**打包**：
- Flutter 原生打包，一次编码多端输出：
  - Android / iOS
  - Windows / macOS / Linux
  - Web

### 项目结构（Flutter）
```
lib/
├── main.dart                 # 入口文件
├── app.dart                  # App 根 widget
├── models/                   # 数据模型
│   ├── chat_message.dart     # 消息模型
│   ├── chat_session.dart     # 会话模型
│   ├── plugin_info.dart      # 插件信息
│   └── openclaw_config.dart  # OpenClaw 配置
├── screens/                  # 页面
│   ├── home_screen.dart      # 主页面（侧边栏+聊天区）
│   ├── chat_screen.dart      # 聊天详情页
│   ├── plugin_list_screen.dart # 插件管理
│   └── settings_screen.dart  # 设置页
├── widgets/                  # 自定义组件
│   ├── chat/                 # 聊天相关
│   │   ├── message_bubble.dart
│   │   └── chat_input.dart
│   ├── preview/              # 文件预览
│   │   ├── pdf_preview.dart
│   │   ├── image_preview.dart
│   │   ├── office_preview.dart
│   │   └── audio_video_player.dart
│   └── common/               # 通用组件
├── services/                 # 服务
│   ├── openclaw_service.dart   # OpenClaw API 封装
│   ├── chat_session_service.dart # 会话管理
│   ├── plugin_service.dart      # 插件管理
│   └── file_preview_service.dart # 文件预览服务
├── bloc/                     # 状态管理 (BLoC)
│   ├── chat/
│   ├── sessions/
│   └── plugin/
├── theme/                    # 主题配置
│   ├── light_theme.dart
│   └── dark_theme.dart
└── utils/                    # 工具
    ├── constants.dart
    └── helpers.dart

docs/                         # 文档
test/                         # 测试
android/ ios/ windows/ macos/ linux/ # 平台相关配置
```

## OpenClaw 消息通道角色

claw-chat 本身作为 OpenClaw 的一个消息 channel：
1. 用户在 claw-chat 发送消息 → 通过 HTTP/WebSocket 发给 OpenClaw
2. OpenClaw 处理完成 → 把回复发给 claw-chat 显示
3. 插件通过 OpenClaw 核心 → 可以发送消息到 claw-chat → 在 UI 上显示
4. 插件可以接收 claw-chat 的事件 → 响应用户操作

## 功能优先级

### P0 - MVP（核心可用）
- [ ] 基础聊天界面（对话列表 + 消息展示 + 用户输入）
- [ ] Markdown 渲染 + 代码高亮
- [ ] 流式输出支持
- [ ] 与 OpenClaw WebAPI 通信
- [ ] 会话持久化（本地存储）
- [ ] 图片和基础文件预览
- [ ] 暗色/亮色主题

### P1 - 完善体验
- [ ] 完整 Office 文件预览（Word/Excel/PDF/PPT）
- [ ] 音视频预览
- [ ] 插件基础框架（插件通信、已安装插件列表）
- [ ] 全局消息搜索
- [ ] 提示词模板
- [ ] 导出对话

### P2 - 高级特性
- [ ] Flutter 原生打包（移动端 + 桌面端）
- [ ] 插件商店/浏览
- [ ] 多标签页（桌面版）
- [ ] LaTeX + Mermaid 支持
- [ ] 语音输入
- [ ] 分享对话

## 通信协议设计

### 整体架构

```
┌───────────────┐          HTTP/WebSocket           ┌────────────────┐
│   claw-chat   │  ←────────────────────────────→  │  OpenClaw Core  │
│  (Flutter)   │                                    │  (本地/服务端)  │
└───────────────┘                                    └────────┬───────┘
                                                             │ IPC
                                                             ↓
                                                      ┌───────────────┐
                                                      │  OpenClaw     │
                                                      │  Plugins      │
                                                      └───────────────┘
```

**混合通信方案**：
- 常规聊天请求：`POST + SSE (text/event-stream) 流式响应` - 实现简单，兼容所有平台
- 服务端主动推送：WebSocket 长连接 - 支持插件消息、系统事件实时推送

### 配置方式

用户在 claw-chat 设置中配置 OpenClaw 服务：

| 配置项 | 必填 | 说明 | 默认值 |
|--------|:----:|------|--------|
| `OpenClaw Base URL` | ✅ | OpenClaw 服务地址 | `http://localhost:3000` |
| `API Key` | - | 服务端认证密钥（如果开启） | - |

---

### API 端点详细定义

#### 1. 发送聊天消息（流式输出）

**请求**：`POST /v1/chat/completions`

```json
{
  "sessionId": "uuid-session-xxx",
  "message": "帮我写一个 Dart 函数",
  "files": [
    {
      "name": "test.dart",
      "type": "text/plain",
      "url": "/files/xxx"
    }
  ],
  "model": "custom-doubao/ark-code-latest"
}
```
- `sessionId`: 必填，会话 ID，新建会话传 `null` 或空字符串由服务端生成
- `message`: 必填，用户发送的文本内容
- `files`: 可选，附带的文件列表
- `model`: 可选，指定使用的模型，不传使用默认配置

**响应**：`Content-Type: text/event-stream`，逐块返回增量内容，格式对齐 OpenAI：

```
data: {"id": "msg-xxx", "delta": "帮", "finishReason": null}

data: {"id": "msg-xxx", "delta": "我写", "finishReason": null}

data: {"id": "msg-xxx", "delta": "一个 Dart 函数", "finishReason": null}

data: {"id": "msg-xxx", "delta": "", "finishReason": "stop"}

[DONE]
```

---

#### 2. 获取会话列表

**请求**：`GET /v1/sessions`

**响应**：
```json
{
  "code": 0,
  "data": [
    {
      "id": "session-xxx",
      "title": "帮我写代码",
      "lastMessage": "这是我的问题...",
      "lastMessageTime": 1703275200000,
      "starred": false,
      "archived": false,
      "unreadCount": 0
    }
  ]
}
```

---

#### 3. 获取会话历史消息

**请求**：`GET /v1/sessions/{sessionId}/messages`

**响应**：
```json
{
  "code": 0,
  "data": [
    {
      "id": "msg-1",
      "role": "user",
      "content": "Hello",
      "timestamp": 1703275200000,
      "files": []
    },
    {
      "id": "msg-2",
      "role": "assistant",
      "content": "Hi! How can I help you?",
      "timestamp": 1703275210000,
      "files": []
    }
  ]
}
```

---

#### 4. 新建会话

**请求**：`POST /v1/sessions`

```json
{
  "title": "新对话"
}
```

**响应**：
```json
{
  "code": 0,
  "data": {
    "id": "session-new-uuid",
    "title": "新对话",
    "createdAt": 1703275200000
  }
}
```

---

#### 5. 更新会话信息

**请求**：`PATCH /v1/sessions/{sessionId}`

```json
{
  "title": "新标题",
  "starred": true,
  "archived": false
}
```

**响应**：`{ "code": 0 }`

---

#### 6. 删除会话

**请求**：`DELETE /v1/sessions/{sessionId}`

**响应**：`{ "code": 0 }`

---

#### 7. 文件上传

**请求**：`POST /v1/files/upload`  
Content-Type: `multipart/form-data`

**响应**：
```json
{
  "code": 0,
  "data": {
    "id": "file-uuid",
    "name": "test.png",
    "url": "/v1/files/file-uuid",
    "type": "image/png",
    "size": 102400
  }
}
```

---

#### 8. 获取文件内容

**请求**：`GET /v1/files/{fileId}`

**响应**：返回二进制文件内容

---

#### 9. 获取已安装插件列表

**请求**：`GET /v1/plugins`

**响应**：
```json
{
  "code": 0,
  "data": [
    {
      "id": "weather",
      "name": "天气插件",
      "version": "1.0.0",
      "description": "查询天气信息",
      "enabled": true,
      "author": "openclaw",
      "homepage": "https://github.com/openclaw/plugins/tree/main/weather"
    }
  ]
}
```

---

#### 10. 安装插件

**请求**：`POST /v1/plugins/install`

```json
{
  "pluginId": "weather"
}
```

**响应**：`{ "code": 0, "message": "安装成功" }`

---

#### 11. 切换插件启用状态

**请求**：`POST /v1/plugins/{pluginId}/toggle`

```json
{
  "enabled": true
}
```

**响应**：`{ "code": 0 }`

---

#### 12. 卸载插件

**请求**：`DELETE /v1/plugins/{pluginId}`

**响应**：`{ "code": 0, "message": "卸载成功" }`

---

### WebSocket 双向通信（服务端 → 客户端推送）

claw-chat 启动后建立 WebSocket 连接：`ws://openclaw-host:port/v1/ws`

#### 消息类型

**1. 插件推送消息**
```json
{
  "type": "plugin_message",
  "pluginId": "weather",
  "sessionId": "current-session-id",
  "content": "# 北京 今日天气\n\n温度 15-25℃，晴天",
  "contentType": "markdown",
  "actions": [
    {
      "label": "查看未来三天",
      "actionId": "query_forecast",
      "payload": { "city": "北京" }
    }
  ]
}
```

**2. 插件动作响应回调**
```json
{
  "type": "plugin_action_result",
  "pluginId": "weather",
  "actionId": "query_forecast",
  "success": true,
  "content": "未来三天北京晴转多云...",
  "contentType": "markdown"
}
```

**3. 系统通知**
```json
{
  "type": "system_notice",
  "level": "info", // info | warning | error
  "message": "OpenClaw 将在 5 分钟后重启进行更新"
}
```

**4. 错误通知**
```json
{
  "type": "error",
  "message": "会话已过期，请重新连接"
}
```

#### 客户端 → WebSocket 消息

**触发插件动作**（用户点击插件按钮）：
```json
{
  "type": "plugin_action",
  "pluginId": "weather",
  "actionId": "query_forecast",
  "sessionId": "session-xxx",
  "payload": { "city": "北京" }
}
```

**心跳包**：
```json
{
  "type": "ping"
}
```
服务端响应：
```json
{
  "type": "pong"
}
```

---

### 完整的数据类型定义

```typescript
// 消息角色
type Role = 'user' | 'assistant' | 'system' | 'plugin';

// 附加文件
interface ChatFile {
  id: string;
  name: string;
  url: string;
  type: string; // MIME type
  size: number; // bytes
}

// 对话消息
interface Message {
  id: string;
  role: Role;
  content: string;
  timestamp: number;
  files?: ChatFile[];
  pluginId?: string; // 如果是插件消息
}

// 会话信息
interface Session {
  id: string;
  title: string;
  lastMessage?: string;
  lastMessageTime: number;
  createdAt: number;
  starred: boolean;
  archived: boolean;
  unreadCount: number;
}

// 插件信息
interface PluginInfo {
  id: string;
  name: string;
  version: string;
  description: string;
  enabled: boolean;
  author: string;
  homepage?: string;
}

// 插件动作按钮
interface PluginAction {
  label: string;
  actionId: string;
  payload?: Record<string, any>;
}
```

## 开发路线

### Phase 1: MVP 核心 (v0.1)
- [ ] Flutter 项目初始化，配置开发环境
- [ ] 基础布局：侧边栏（会话列表） + 聊天区 + 输入区
- [ ] 集成 chat_ui 组件，消息展示
- [ ] 对话列表和会话管理
- [ ] flutter_markdown + 代码高亮
- [ ] WebSocket 流式输出对接
- [ ] 与 OpenClaw 核心 API 对接
- [ ] Isar 本地存储会话历史
- [ ] 亮色/暗色主题切换

### Phase 2: 文件预览 (v0.2)
- [ ] 文件上传组件（支持拖拽/选择）
- [ ] 图片预览 + 手势缩放
- [ ] PDF 预览
- [ ] Word/Excel 文件预览
- [ ] 音视频播放
- [ ] 文件类型检测和处理分发

### Phase 3: 插件系统 (v0.3)
- [ ] 插件通信协议设计
- [ ] 插件管理界面（列表/启用/禁用）
- [ ] 插件与客户端通信通道（经由 OpenClaw 核心）
- [ ] 插件扩展点设计（UI 注入）
- [ ] 兼容 `openclaw plugins install` 机制
- [ ] WebView 支持插件自定义 UI
- [ ] 示例插件开发

### Phase 4: polish & 多端打包 (v0.4)
- [ ] 全局搜索（搜索历史会话和消息）
- [ ] 对话导出（Markdown/PDF）
- [ ] UI/UX 优化，适配不同屏幕
- [ ] 响应式适配（手机/平板/桌面）
- [ ] Flutter 多端打包（Android/iOS/Windows/macOS/Linux/Web）
- [ ] 编译和发布文档
- [ ] 测试完善

### Phase 5: v1.0 稳定发布
- [ ] 文档完善
- [ ] 性能优化
- [ ] Bug 修复
- [ ] 发布正式版本

## 界面布局参考

```
┌─────────────────┬─────────────────────────────────────────┐
│ 会话列表        │             聊天内容区                    │
│                 │  ╔═══════════════════════════════════╗  │
│ [+] 新建对话    │  ║  用户消息                          ║  │
│                 │  ╚═══════════════════════════════════╝  │
│ 会话 1          │                                         │
│ 会话 2  ●       │  ╔═══════════════════════════════════╗  │
│ *星标会话        │  ║  AI 回复                           ║  │
│                 │  ║  [代码块]                           ║  │
│ 归档            │  ║  [文件预览]                        ║  │
│                 │  ╚═══════════════════════════════════╝  │
│                 │                                         │
│ [插件] ▶        │  ↓ 滚动更多历史                         │
│ [设置] ⚙        │                                         │
│                 │         [输入框]         [发送按钮]       │
└─────────────────┴─────────────────────────────────────────┘
```

## 详细功能点拆分

### Phase 1: MVP 核心 v0.1 - 每个任务拆分为独立功能点

#### 1.1 项目初始化
- [ ] 创建 Flutter 项目 (`flutter create claw_chat`)
- [ ] 配置 `pubspec.yaml`，添加核心依赖：
  - chat_ui
  - flutter_bloc / bloc
  - dio
  - web_socket_channel
  - isar
  - shared_preferences
  - flutter_markdown
  - highlight
  - font_awesome_flutter
  - flutter_screenutil
- [ ] 配置开发环境，运行 `flutter doctor` 通过
- [ ] 配置 `.gitignore`

#### 1.2 数据模型
- [ ] `ChatMessage` - 消息模型：id、content、role (user/assistant)、timestamp、files、status (sending/success/error)
- [ ] `ChatSession` - 会话模型：id、title、lastMessageTime、starred、archived、modelId
- [ ] `OpenClawConfig` - 配置模型：baseUrl、apiKey、themeMode
- [ ] `PluginInfo` - 插件信息：id、name、version、description、enabled、author

#### 1.3 主题配置
- [ ] 定义亮色主题
- [ ] 定义暗色主题
- [ ] 主题切换逻辑
- [ ] 跟随系统选项

#### 1.4 基础布局
- [ ] 主页面 `HomeScreen`：Scaffold 根布局
- [ ] 桌面端：左侧侧边栏（固定宽度）+ 右侧聊天区（弹性）
- [ ] 移动端：会话列表页 → 聊天详情页 路由跳转
- [ ] 路由配置：go_router 或 Navigator 2.0

#### 1.5 侧边栏 - 会话列表
- [ ] 会话列表展示（标题 + 时间）
- [ ] "新建会话" 悬浮按钮
- [ ] 当前会话高亮
- [ ] 下拉刷新会话列表
- [ ] 会话长按菜单：重命名/删除/星标/归档

#### 1.6 聊天区集成 chat_ui
- [ ] 集成 chat_ui `ChatListView`
- [ ] 自定义消息气泡样式适配主题
- [ ] 自定义 `ChatInput` 发送按钮
- [ ] 点击发送消息回调处理

#### 1.7 Markdown 渲染
- [ ] flutter_markdown 集成
- [ ] 代码高亮插件
- [ ] 支持 GFM 表格、任务列表
- [ ] 代码块复制按钮

#### 1.8 网络层 - OpenClaw 服务
- [ ] dio 封装 HTTP 请求
- [ ] WebSocket 连接管理
- [ ] 发送消息接口
- [ ] 流式输出接收处理
- [ ] 插件消息推送监听

#### 1.9 会话存储
- [ ] Isar 数据库初始化
- [ ] 会话增删改查 CRUD
- [ ] 消息存储
- [ ] 配置读写 `shared_preferences`

#### 1.10 设置页面
- [ ] OpenClaw 服务地址配置输入框
- [ ] 主题选择开关（亮色/暗色/自动）
- [ ] 保存配置

#### 1.11 BLoC 状态管理
- [ ] `SessionsBloc` - 会话列表状态管理
- [ ] `ChatBloc` - 当前聊天状态管理
- [ ] `ConfigBloc` - 配置状态管理

---

### Phase 2: 文件预览 v0.2

#### 2.1 文件上传
- [ ] 文件选择器集成 `file_picker`
- [ ] 拖拽上传（桌面端）
- [ ] 上传中状态展示
- [ ] 已选文件在输入区展示

#### 2.2 文件预览基础设施
- [ ] 文件类型检测（后缀 + MIME）
- [ ] 预览分发器：根据类型选择对应的预览组件
- [ ] 文件缓存管理

#### 2.3 图片预览
- [ ] 图片展示
- [ ] 集成 `photo_view` 手势缩放
- [ ] 双击双击放大/缩小

#### 2.4 PDF 预览
- [ ] 集成 `flutter_pdfview`
- [ ] 页码控制器
- [ ] 手势缩放

#### 2.5 Word (docx) 预览
- [ ] 集成 `docx_reader` 解析
- [ ] 转换为 Flutter Widget 树
- [ ] 标题/段落/列表样式处理

#### 2.6 Excel (xlsx) 预览
- [ ] 集成 `excel_reader` 解析
- [ ] 表格展示 Sheet
- [ ] Sheet 切换

#### 2.7 音频播放
- [ ] 集成 `audioplayers`
- [ ] 播放/暂停控制
- [ ] 进度条

#### 2.8 视频播放
- [ ] 集成 `video_player`
- [ ] 播放控制
- [ ] 全屏播放

---

### Phase 3: 插件系统 v0.3

#### 3.1 插件通信协议
- [ ] 定义 JSON-RPC 请求/响应格式
- [ ] 定义插件事件类型
- [ ] 定义 UI 扩展数据结构

#### 3.2 插件服务
- [ ] 从 OpenClaw 核心获取已安装插件列表
- [ ] 插件启用/禁用
- [ ] 插件消息通道监听
- [ ] 客户端事件发送到插件

#### 3.3 插件管理页面
- [ ] 已安装插件列表展示
- [ ] 启用/禁用切换
- [ ] 插件详情展示（名称/版本/描述/作者）
- [ ] 卸载按钮

#### 3.4 插件 UI 扩展
- [ ] 侧边栏扩展点：插件可添加菜单项
- [ ] 消息内容扩展：插件可自定义消息组件
- [ ] WebView 容器：支持插件自定义 HTML UI
- [ ] 桥接：Flutter ↔ JS 通信

#### 3.5 插件商店
- [ ] 从 clawhub.ai 获取插件列表
- [ ] 插件详情展示
- [ ] 一键安装（调用 OpenClaw API）

---

### Phase 4:  polish & 打包 v0.4

#### 4.1 全局搜索
- [ ] 搜索输入框
- [ ] 搜索会话标题和消息内容
- [ ] 搜索结果高亮
- [ ] 点击跳转会话

#### 4.2 对话导出
- [ ] 导出为 Markdown
- [ ] 导出为 PDF
- [ ] 保存到文件分享

#### 4.3 UI/UX 优化
- [ ] 适配手机/平板/桌面不同尺寸
- [ ] 过渡动画
- [ ] 空状态提示
- [ ] 错误提示友好化

#### 4.4 多端打包
- [ ] Android 打包配置 (apk/appbundle)
- [ ] iOS 打包配置
- [ ] Windows 打包
- [ ] macOS 打包
- [ ] Linux 打包
- [ ] Web 编译

#### 4.5 编写打包文档
- [ ] 环境要求
- [ ] 构建步骤
- [ ] 发布说明

---

### Phase 5: v1.0 稳定发布

- [ ] 完整文档编写
- [ ] 性能优化（列表滚动、大文件预览）
- [ ] 修复已知 Bug
- [ ] 编写 README
- [ ] 发布 v1.0.0

## 后续开发步骤

1. 初始化 Flutter 项目，配置依赖
2. 创建数据模型和 BLoC 状态管理结构
3. 实现基础布局、会话列表、集成 chat_ui
4. 对接 OpenClaw API，实现流式输出
5. 本地存储会话历史
6. 完成 MVP P0 所有功能点
7. 逐步迭代添加文件预览和插件支持
