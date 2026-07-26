# Social App（Flutter 学习工程）

<p align="center">
  <img src="http://qiniu.itopic.com.cn/%E5%BE%AE%E4%BF%A1%E5%9B%BE%E7%89%87_20260726153202_35_2125.jpg" width="280" />
  &nbsp;&nbsp;
  <img src="http://qiniu.itopic.com.cn/%E5%BE%AE%E4%BF%A1%E5%9B%BE%E7%89%87_20260726154132_37_2125.jpg" width="280" />
</p>

<p align="center">
  <img src="http://qiniu.itopic.com.cn/httpqiniu.itopic.com.cnapp-flutter-release.apk.png" width="200" />
</p>

一个偏真实业务的 Flutter 社交客户端示例：动态、视频、聊天、登录注册都有，但**重点不是业务本身，而是怎么把 Flutter 工程搭清楚**。

---

## 本工程 AI 规范

项目里有一份 Cursor 规则：`.cursor/rules/flutter_coding_rules.mdc`，几个容易注意到的点：

- Model 变量名以 `Model` 结尾，比如 `TopicModel topicModel`
- Class / public 方法尽量写中文文档注释
- 页面拆成 `page` + `widgets/` + `helpers/`，主文件只做编排

---

## 技术选型

| 角色 | 选型 | 说明 |
|------|------|------|
| 状态 | `riverpod` | 登录态、路由、推送、会话等全局能力 |
| 路由 | `go_router` | 路径常量 + Shell Tab + redirect |
| 网络 | `dio` | 单例 `HttpClient` + 解析json封装 |
| 本地存储 | `shared_preferences` / `sqflite` | 账号缓存 / 聊天本地库 |
| 列表刷新 | `easy_refresh` | 下拉刷新、上拉加载 |
| 视频 | `video_player` + `chewie` | 详情播放 |
| IM聊天 | `getuiflut` | 底层用个推，自己sql存储message |
| 上传 | `qiniu_flutter_sdk` | 头像等资源上传 |

---

## 目录怎么读

```text
lib/
├── main.dart                 # 启动：SharedPreferences + ProviderScope
├── app/                      # App 壳：主题、路由、根 Widget
│   ├── app.dart
│   ├── router/
│   └── theme/
├── core/                     # 跨业务基础设施（和具体页面无关）
│   ├── account/              # 登录态、本地账号、登录 Guard
│   ├── network/              # Dio、ApiResponse、分页、环境
│   ├── push/                 # 个推
│   ├── qiniu/                # 七牛上传
│   ├── bridge/               # 原生 MethodChannel / EventChannel
│   └── utils/
├── features/                 # 业务功能（按模块拆）
│   ├── auth/                 # 登录 / 注册 / 完善资料
│   ├── home/                 # 主 Tab 壳
│   ├── topic/                # 动态
│   ├── video/                # 视频
│   ├── comment/              # 评论（可被话题/视频复用）
│   ├── conversation/         # IM
│   ├── user/                 # 用户主页
│   ├── me/                   # 我的
│   └── common/               # 小而杂的通用 UI
└── shared/                   # 跨 feature 的通用组件（AppBar、空态等）
```

## 分层长什么样

```text
UI (Page / Widget)
        │  ref.watch / setState / ListenableBuilder
        ▼
Notifier / Controller          ← 全局态用 Riverpod；列表页常见本地 State
        │
        ▼
Repository                     ← 对上提供业务语义，对下屏蔽接口细节
        │
   ┌────┴────┐
   ▼         ▼
Network    Local DB            ← Dio / SharedPreferences / sqflite
```

---

## 启动流程

```text
main()
  → SharedPreferences
  → ProviderScope（注入 prefs）
  → SocialApp
       ├─ 启动原生事件监听（NativeEvents）
       ├─ 初始化个推
       └─ MaterialApp.router
            └─ 默认进 /topic
                 └─ AccountNotifier 从本地恢复登录态，同步 HttpClient.userid
```

关键文件：

- `lib/main.dart`
- `lib/app/app.dart`
- `lib/core/account/account_provider.dart`
- `lib/app/router/app_router.dart`

---

## 建议的阅读顺序

按这个顺序看，比从 `main.dart` 一路翻到聊天更清晰：

1. **`app/` + `core/network/`**  
   先搞清 App 怎么起来、请求怎么发、分页结构长什么样

2. **`core/account/`**  
   看 Riverpod Notifier 怎么管登录态，以及 Guard 怎么拦截需要登录的动作

3. **`features/topic/`**  
   最典型的列表 Feature：Repository、Model、列表基类、详情、点赞/分享

4. **`features/comment/`**  
   看「可复用子模块」怎么拆：数据在 comment，UI 被 topic/video 引用

5. **`features/video/`**  
   瀑布流 + 播放器，presentation/widgets 拆分比较直观

6. **`features/conversation/`**  
   最复杂的一块：远程拉消息 + sqflite 本地库 + Controller 管未读 + 推送进来

7. **`core/push/`、`core/bridge/`**  
   推送跳转、原生通道。Bridge 方案还可看 `docs/native_flutter_bridge_plan.md`

---

## 几个值得留意的设计点

### 1. Riverpod 用在「全局」，不是处处 Provider

登录、路由、推送、会话控制器这类跨页面能力走 Riverpod；  
话题/视频列表的翻页、加载态，很多仍是页面内 `setState`。

学习时别急着「全部全局化」——该本地就本地。

### 2. HttpClient 单例 + 自动 userid

登录成功后，`AccountNotifier` 会更新 `HttpClient.instance` 的 userid，拦截器统一塞进请求。  
业务 Repository 一般不用自己关心鉴权头。

### 3. 列表基类复用

`TopicListBaseState` 把 EasyRefresh、空态/错误态、点赞等公共能力抽出来，动态流和用户主页都能复用。  
这种「基类复用」和「组合复用」各有利弊，这里偏务实。

### 4. 聊天是双数据源

会话不只是调接口：

- 远端：拉历史、发消息
- 本地：`sqflite` 落库，冷启动能先出内容
- 推送：个推进来后拉增量、更新未读

想理解「Flutter 里 IM 页面怎么组织」，从 `ConversationController` 往下看就行。

### 5. 原生 Bridge 分层

不是把 MethodChannel 散落在页面里，而是拆成 Channel / Methods / Bridge / Events。  
当前工程是纯 Flutter App，Bridge 更偏演示和调试（「我的」页里有面板）。

---

## 跑起来

```bash
flutter pub get
flutter run
```

需要真机/模拟器环境；推送、七牛上传这类能力依赖对应平台配置，本地纯看 UI 和架构不一定全开。

---
