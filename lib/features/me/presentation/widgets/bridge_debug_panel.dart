import 'dart:async';

import 'package:all_flutter0709/core/bridge/native_bridge.dart';
import 'package:all_flutter0709/core/bridge/native_event_model.dart';
import 'package:all_flutter0709/core/bridge/native_events.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 「我的」页原生 Bridge 联调面板：ping / 设备信息 / 请求原生推事件。
class BridgeDebugPanel extends StatefulWidget {
  const BridgeDebugPanel({super.key});

  @override
  State<BridgeDebugPanel> createState() => _BridgeDebugPanelState();
}

class _BridgeDebugPanelState extends State<BridgeDebugPanel> {
  static const _maxLogs = 40;

  final List<String> _logs = <String>[];
  StreamSubscription<NativeEventModel>? _eventSubscription;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    NativeEvents.instance.start();
    _eventSubscription = NativeEvents.instance.allEvents.listen((event) {
      _appendLog('← event [${event.source}] ${event.event} data=${event.data}');
    });
  }

  @override
  void dispose() {
    unawaited(_eventSubscription?.cancel() ?? Future<void>.value());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '原生 Bridge 联调',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'MethodChannel: com.dq.allflutter0709/bridge\n'
              'EventChannel: com.dq.allflutter0709/events',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonal(
                  onPressed: _busy ? null : _onPing,
                  child: const Text('Ping'),
                ),
                FilledButton.tonal(
                  onPressed: _busy ? null : _onGetDeviceInfo,
                  child: const Text('设备信息'),
                ),
                FilledButton.tonal(
                  onPressed: _busy ? null : _onRequestEmitDemo,
                  child: const Text('请求原生推事件'),
                ),
                FilledButton.tonal(
                  onPressed: _logs.isEmpty
                      ? null
                      : () => setState(_logs.clear),
                  child: const Text('清空日志'),
                ),
              ],
            ),
            if (_logs.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Bridge 日志',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxHeight: 220),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    _logs.join('\n'),
                    style: const TextStyle(fontSize: 12, height: 1.35),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _onPing() async {
    await _run('ping', () async {
      final pong = await NativeBridge.instance.ping();
      _appendLog('→ ping 返回: $pong');
      _snack('ping → $pong');
    });
  }

  Future<void> _onGetDeviceInfo() async {
    await _run('getDeviceInfo', () async {
      final info = await NativeBridge.instance.getDeviceInfo();
      _appendLog('→ getDeviceInfo: $info');
      _snack('已获取设备信息');
    });
  }

  Future<void> _onRequestEmitDemo() async {
    await _run('emitDemo', () async {
      final ok = await NativeBridge.instance.requestEmitDemo();
      _appendLog('→ emitDemo 已请求, ok=$ok（等待原生回推）');
      _snack(ok ? '已请求原生推事件' : 'emitDemo 返回 false');
    });
  }

  Future<void> _run(String label, Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } on MissingPluginException catch (error) {
      _appendLog('✗ $label MissingPluginException: $error');
      _snack('原生未注册 Bridge，请确认双端 NativeBridge');
    } on PlatformException catch (error) {
      _appendLog('✗ $label PlatformException: ${error.code} ${error.message}');
      _snack(error.message ?? error.code);
    } catch (error) {
      _appendLog('✗ $label 失败: $error');
      _snack('$error');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  void _appendLog(String line) {
    if (!mounted) {
      return;
    }
    final now = DateTime.now();
    final stamp =
        '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}';
    setState(() {
      _logs.insert(0, '[$stamp] $line');
      if (_logs.length > _maxLogs) {
        _logs.removeRange(_maxLogs, _logs.length);
      }
    });
  }

  void _snack(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
