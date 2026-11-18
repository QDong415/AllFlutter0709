import 'package:all_flutter0709/app/theme/app_palette.dart';
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
    final palette = context.palette;
    final border = OutlineInputBorder(
      borderSide: BorderSide(color: palette.divider),
    );
    return Scaffold(
      backgroundColor: palette.bodyBackground,
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
          style: TextStyle(fontSize: 16, color: palette.ink),
          cursorColor: palette.ink,
          decoration: InputDecoration(
            filled: true,
            fillColor: palette.card,
            counterStyle: TextStyle(color: palette.secondaryText),
            border: border,
            enabledBorder: border,
            focusedBorder: border.copyWith(
              borderSide: BorderSide(color: palette.primary),
            ),
          ),
        ),
      ),
    );
  }
}
