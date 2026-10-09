import 'package:all_flutter0709/features/me/presentation/profile_edit_page.dart';
import 'package:all_flutter0709/shared/widgets/common_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:all_flutter0709/shared/widgets/app_toast.dart';

/// 修改昵称或自我介绍。
class ProfileTextEditPage extends StatefulWidget {
  const ProfileTextEditPage({super.key, required this.args});

  final ProfileTextEditArgs args;

  @override
  State<ProfileTextEditPage> createState() => _ProfileTextEditPageState();
}

class _ProfileTextEditPageState extends State<ProfileTextEditPage> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.args.initial,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty && !widget.args.canEmpty) {
      AppToast.show(context, '内容不能为空');
      return;
    }
    context.pop(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: widget.args.title,
        actions: [TextButton(onPressed: _submit, child: const Text('完成'))],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          controller: _controller,
          autofocus: true,
          maxLength: widget.args.maxLength,
          maxLines: widget.args.multiline ? 8 : 1,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
      ),
    );
  }
}
