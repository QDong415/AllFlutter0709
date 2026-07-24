# 原生 ↔ Flutter 通信与界面跳转方案

> 基于对 `FutterLearn`（add-to-app 学习工程）的点评，结合本工程 `AllFlutter0709`（纯 Flutter App + go_router + Riverpod）现状给出落地建议。

---

## 1. 背景与目标

### 1.1 两个工程的本质差异

| | FutterLearn | AllFlutter0709（本工程） |
|---|---|---|
| 形态 | Android 宿主 + Flutter Module | **纯 Flutter App** |
| 引擎 | Application 预热单 Engine + Cache | 系统默认隐式 Engine |
| 路由 | `onGenerateRoute` + GetMaterialApp | **go_router** + Riverpod |
| iOS | 无独立宿主实现 | 标准 Runner（`AppDelegate`） |
| 已有「外部驱动跳转」 | MethodChannel `open` | **个推点击** → `router.go/push` + pending |

本工程不是 add-to-app。目标是：在**现有 Flutter 主工程**里，补齐原生与 Flutter 的双向通信，以及双向界面跳转（Flutter 打开原生页 / 原生唤起 Flutter 路由）。

若未来要做成「原生壳嵌 Flutter 模块」，可复用本文协议，但引擎生命周期要另做一版（见 §8）。

### 1.2 本方案要解决的事

1. Flutter → Native：打开原生页、调原生能力、带回结果关闭
2. Native → Flutter：打开/切换 Flutter 路由、推送业务事件
3. 与现有 `go_router`、登录态、推送 pending 导航统一，避免两套跳转逻辑

---

## 2. 对 FutterLearn 的点评

### 2.1 做得好的地方（值得保留）

1. **分层清晰**  
   Android：`FlutterBridge`（通道）+ `FlutterRouter`（业务 API）  
   Flutter：`NativeChannel` / `NativeMethods` / `NativeBridge` / `NativeEvents` / `AppRouter`  
   职责拆开，比「一个巨型 handler」好读。

2. **引擎预热 + Cache**（在 add-to-app 场景下）  
   首开 Flutter 页体验更好，方向正确。

3. **路由名与参数约定统一**  
   Native `open(route, args)` ↔ Flutter `pushNamed`，协议简单。

4. **事件与路由共用一套命名常量**  
   `NativeMethods` / `NativeEventNames` 集中管理，避免魔法字符串散落。

### 2.2 明显问题（本工程不要照搬）

| 问题 | 说明 | 本工程应对 |
|---|---|---|
| 单 Channel 塞路由 + 业务 + 伪事件 | 难演进、难测试、语义混杂 | **拆 Navigation / Biz / Event 三类协议**（可共用一个 channel name，但 method 分区） |
| `open` 用 `pushNamedAndRemoveUntil(..., false)` | 每次清空 Flutter 栈，多入口会丢状态 | 用 **go_router 的 `go` / `push`**，按场景选择 |
| `open` 与 `startActivity` 竞态 | 先发路由再 attach Activity，无就绪握手 | 纯 App 无此问题；add-to-app 再补 ready |
| `finish` 不关 Activity，真正关靠 `SystemNavigator.pop` | 职责分裂，易漏 | **`close` 统一：回传结果 + 关原生页** |
| `openNativePage` / share / openWeb 半成品 | Dart 有封装，Native 未实现或 stub | 协议先定、**按需实现，禁止空 stub 长期挂着** |
| 事件走 MethodChannel | 无订阅语义 | 高频推送用 **EventChannel**；低频指令继续 MethodChannel |
| 无 iOS 对称实现 | 只 Android | **Android / iOS 同一套 method 名与参数** |
| `ResultListener` 死代码 | 声明了未接线 | 结果回传用 **一次 MethodChannel Result** 或明确 callback method |
| 与 go_router 无关 | 学习工程用旧 Navigator API | 本工程 **Native→Flutter 一律走 `appRouterProvider`** |

### 2.3 一句话评价

> FutterLearn 是合格的「单 Engine + 自研 MethodChannel 路由」学习样板：结构清楚、能跑通 Native→Flutter 开页；但协议偏草稿、Flutter→Native 半成品、栈策略过激、无 iOS。适合借鉴分层，不适合原样移植到本工程。

---

## 3. 推荐架构（本工程）

### 3.1 总体结构

```
┌──────────────────────────────────────────────────────────┐
│  iOS AppDelegate / Android MainActivity                  │
│  NativeBridge.register(messenger)                        │
└────────────────────────────┬─────────────────────────────┘
                             │ MethodChannel
                             │ com.dq.allflutter0709/bridge
┌────────────────────────────▼─────────────────────────────┐
│  Dart: lib/core/bridge/                                  │
│  ├─ native_channel.dart      // Channel 单例             │
│  ├─ native_methods.dart      // method / event 常量      │
│  ├─ native_bridge.dart       // Flutter → Native API     │
│  ├─ native_events.dart       // Native → Flutter 事件流  │
│  └─ native_navigation.dart   // Native → go_router 跳转  │
└────────────────────────────┬─────────────────────────────┘
                             │
              ┌──────────────┴──────────────┐
              ▼                             ▼
     appRouterProvider              业务 Provider
     (go / push / pop)              (登录、会话等)
```

### 3.2 设计原则

1. **Flutter 内跳转只认 go_router**（复用 `AppRoutes`、与个推同一套）
2. **原生页用原生导航栈**（UIViewController / Activity），不假装成 Flutter 路由
3. **协议版本化**：payload 带 `v: 1`，便于以后加字段
4. **双端对称**：Android / iOS 同一 method 表，禁止一端有一端没有
5. **冷启动 / 未登录**：复用个推的 **pending 再 flush** 模式，不要另起一套

### 3.3 不建议一上来用的方案

| 方案 | 原因 |
|---|---|
| FlutterBoost | 偏 add-to-app 多容器；本工程仍是单 FlutterActivity/FlutterViewController，过重 |
| 每个业务一个 Channel | 维护成本高；先一个 bridge channel + method 分区即可 |
| 把所有原生能力塞进 navigation channel | 和 FutterLearn 同一坑；业务方法与导航方法分开命名空间 |

---

## 4. 通信协议设计

### 4.1 Channel

```text
name: com.dq.allflutter0709/bridge
类型: MethodChannel（主）
可选: EventChannel com.dq.allflutter0709/events（仅高频/长连接类事件）
```

前期可全部走 MethodChannel；当事件频率高或需要「订阅/取消」时再拆 EventChannel。

### 4.2 Method 分区（建议常量）

#### A. Native → Flutter（原生 `invokeMethod`）

| method | 参数 | 行为 |
|---|---|---|
| `navigate` | `{ v, action: "go"\|"push", location, extra? }` | 调 go_router |
| `pop` | `{ v, result? }` | Flutter 栈 `pop`（若可 pop） |
| `emit` | `{ v, event, data? }` | 转发给 `NativeEvents` |

`location` 直接用 go_router 路径，例如：

- `/topic/detail/628`
- `/conversation/chat/abc`
- `/user/123`
- `/me`

与现有 `AppRoutes` / 个推跳转保持一致，避免再维护一套「内部 route 别名」。

#### B. Flutter → Native（Dart `invokeMethod`）

| method | 参数 | 行为 |
|---|---|---|
| `openNative` | `{ v, page, args?, requestId? }` | 打开原生页；可异步回结果 |
| `closeNative` | `{ v, result? }` | 关闭当前原生页（若 Flutter 嵌在原生容器内） |
| `call` | `{ v, api, args? }` | 通用原生能力（分享、浏览器、取 token…） |

`page` 用稳定字符串，例如：`native.web` / `native.media_picker` / `native.settings`，两端枚举对齐。

#### C. 结果回传两种模式（二选一，推荐先用 1）

1. **同步/一次 Result**：适合立刻能返回的（如 mock login、是否成功打开）
2. **异步 callback method**：原生稍后 `invokeMethod("nativeResult", { requestId, data })`  
   适合相册、登录页等「用户操作后才有结果」

### 4.3 示例 Payload

Native 打开话题详情：

```json
{
  "v": 1,
  "action": "go",
  "location": "/topic/detail/628"
}
```

Flutter 打开原生 Web：

```json
{
  "v": 1,
  "page": "native.web",
  "args": { "url": "https://example.com" },
  "requestId": "uuid-..."
}
```

---

## 5. 界面跳转流程

### 5.1 Native → Flutter

```
原生按钮 / 推送 / Deep Link
  → NativeBridge.navigate(go|push, location, extra?)
  → Dart NativeNavigationHandler
  → 若未登录：写入 pending（对齐 GetuiPushService）
  → 已登录：ref.read(appRouterProvider).go / .push(location)
```

要点：

- **不要**像 FutterLearn 那样每次 `pushNamedAndRemoveUntil` 清栈
- Tab 内页面用 `go`；详情盖在 Tab 上用 `push`（与现有 `parentNavigatorKey` 策略一致）
- 登录门禁：复用 `accountProvider` + pending flush，与个推共用工具更好（抽 `PendingNavigation`）

### 5.2 Flutter → Native

```
Flutter 业务代码
  → NativeBridge.openNative(page, args)
  → Android: startActivity / iOS: present|push UIViewController
  → 用户操作结束
  → 回传 result（Result 或 nativeResult）
  → Dart await / Stream 收到结果后继续业务
```

要点：

- 原生页生命周期由原生管；Flutter 不要假设自己能 `Navigator.pop` 关掉原生页
- 若将来是「原生页里再嵌 Flutter」，才需要 `closeNative` / `SystemNavigator.pop` 一类关容器 API

### 5.3 Flutter 内部仍走 go_router

Bridge **不替代** `context.push` / `context.go`。只有「跨边界」才走 Channel。

---

## 6. 代码落点（建议目录）

### 6.1 Dart

```text
lib/core/bridge/
  native_channel.dart
  native_methods.dart
  native_bridge.dart
  native_events.dart
  native_navigation.dart      # MethodCallHandler → go_router
  pending_navigation.dart     # 可选：与个推共用的 pending 抽离
```

初始化：在 `main.dart` / `SocialApp` 启动后、与 `GetuiPushService.initialize` 同级注册 handler（需要 `ProviderContainer` / `Ref` 才能读 `appRouterProvider`）。

### 6.2 Android

```text
android/app/src/main/kotlin/.../
  MainActivity.kt                 # configureFlutterEngine 里 register
  bridge/NativeBridge.kt          # Channel 注册与分发
  bridge/NativeNavigator.kt       # openNative 具体页面
```

### 6.3 iOS

```text
ios/Runner/
  AppDelegate.swift               # didInitializeImplicitFlutterEngine 里 register
  Bridge/NativeBridge.swift
  Bridge/NativeNavigator.swift
```

当前 `AppDelegate` 已有 `FlutterImplicitEngineDelegate`，在 `didInitializeImplicitFlutterEngine` 用 `engineBridge.binaryMessenger` 挂 Channel 即可，不必自建 Engine。

---

## 7. 分阶段落地（建议）

### Phase 0 — 协议与空壳（0.5～1 天）

- 建 `lib/core/bridge/` + 双端 `NativeBridge` 注册
- 打通 ping：`call(api: "ping")` → `"pong"`
- 双端 method 常量表对齐

### Phase 1 — Native → Flutter 跳转（优先）

- 实现 `navigate` → `appRouterProvider.go/push`
- 接上登录 pending（可先复用个推字段，或抽公共类）
- 用 Android/iOS 各做一个调试入口按钮验证 `/topic/detail/xxx`

### Phase 2 — Flutter → Native 开页 + 回结果

- 先实现 1～2 个真实页面（例如 `native.web`、系统分享）
- `openNative` + 异步 `nativeResult`
- 业务侧用 `NativeBridge`，禁止页面直接 `MethodChannel`

### Phase 3 — 事件与业务 API

- `emit` → `NativeEvents.stream`（登录成功、主题切换等）
- 按需加 `call`：`share` / `getDeviceInfo` 等
- 高频再拆 EventChannel

### Phase 4 —（可选）抽公共 Pending、Deep Link 统一入口

- 个推 / Bridge / Universal Link 都进同一 `AppNavigator.fromExternal(location)`

---

## 8. 若未来改成 add-to-app

在现有协议之上额外补：

1. **Application / AppDelegate 预热 Engine** + `FlutterEngineCache`（可参考 FutterLearn）
2. **就绪握手**：Dart `main` 末尾 `invokeMethod("flutterReady")`，原生队列缓存 `navigate` 直到 ready
3. 栈策略改为：**每次打开 Flutter 容器对应一条初始 route**，慎用「全局清栈」
4. 多 Flutter 容器并行时考虑 `FlutterEngineGroup`
5. `close` 必须真正 `finish` Activity / `dismiss` VC，并带回 `result`

在未切 add-to-app 前，**不要**在本工程引入 Engine Cache / FlutterActivity 二次启动，以免和默认 Runner 冲突。

---

## 9. 与 FutterLearn 的映射（迁移对照）

| FutterLearn | 本工程建议 |
|---|---|
| `com.dq.touchlearn/navigation` | `com.dq.allflutter0709/bridge` |
| `open` + route 别名 | `navigate` + **go_router location** |
| `event` | `emit`（或 EventChannel） |
| `finish` + `SystemNavigator.pop` | 纯 App：多数情况不需要；嵌原生容器时用 `closeNative` |
| `openNativePage`（未实现） | `openNative`（双端必须实现才暴露 API） |
| `AppRouter` + GetX routes | `NativeNavigation` + `appRouterProvider` |
| `FlutterRouter.open` + `FlutterActivity` | 纯 App：只 `invokeMethod`；add-to-app 再加容器启动 |

---

## 10. 验收清单

- [ ] Android / iOS 均可 `ping` ↔ `pong`
- [ ] 原生可 `navigate` 到话题详情、会话详情、个人页
- [ ] 未登录时 navigate 会 pending，登录后自动跳转
- [ ] Flutter 可打开至少一个原生页并拿到结果
- [ ] 业务代码不直接碰 `MethodChannel`，只走 `NativeBridge`
- [ ] 与个推跳转不冲突、不重复维护第二套 path
- [ ] method / page 常量双端一致，无「Dart 有、Native notImplemented」长期悬空

---

## 11. 结论

- **借鉴** FutterLearn 的分层（Channel / Methods / Bridge / Events / Router），不要借鉴它的清栈策略、半成品 Native API、单通道杂糅、以及无 iOS。
- **本工程正确姿势**：单 bridge Channel + 与 **go_router / 个推 pending** 对齐的 `navigate`，Flutter→Native 用 `openNative`/`call`，双端对称、分阶段实现。
- 先打通 **Native→Flutter 跳转**（与推送同一套路由），再补 **Flutter→Native 真实页面**，最后才扩展事件与通用 API。
