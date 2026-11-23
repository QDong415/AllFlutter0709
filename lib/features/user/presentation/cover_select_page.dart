import 'package:all_flutter0709/app/theme/app_palette.dart';
import 'package:all_flutter0709/core/account/account_provider.dart';
import 'package:all_flutter0709/core/cloud_storage/cloud_storage_service.dart';
import 'package:all_flutter0709/features/me/presentation/helpers/me_account_helper.dart';
import 'package:all_flutter0709/features/user/data/profile_cover_catalog.dart';
import 'package:all_flutter0709/features/user/data/user_repository.dart';
import 'package:all_flutter0709/features/user/presentation/helpers/cover_upload_helper.dart';
import 'package:all_flutter0709/shared/widgets/app_toast.dart';
import 'package:all_flutter0709/shared/widgets/common_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// 更换个人主页封面。内置图只提交 key；相册图先上传再提交。
class CoverSelectPage extends ConsumerStatefulWidget {
  const CoverSelectPage({super.key});

  @override
  ConsumerState<CoverSelectPage> createState() => _CoverSelectPageState();
}

class _CoverSelectPageState extends ConsumerState<CoverSelectPage> {
  final UserRepository _userRepository = const UserRepository();
  bool _saving = false;

  Future<void> _selectPreset(ProfileCoverPreset preset) {
    return _commit(() async => preset.picture);
  }

  Future<void> _pickCustom() async {
    if (_saving) {
      return;
    }
    final helper = CoverUploadHelper(
      cloudStorageService: ref.read(cloudStorageServiceProvider),
    );
    final file = await helper.pickAndCrop(context);
    if (file == null || !mounted) {
      return;
    }
    await _commit(() => helper.upload(file));
  }

  Future<void> _commit(Future<String> Function() produceKey) async {
    final current = ref.read(accountProvider);
    if (current == null || _saving) {
      return;
    }
    setState(() => _saving = true);
    try {
      final picture = (await produceKey()).trim();
      if (picture.isEmpty) {
        throw Exception('封面保存失败');
      }
      final serverJson = await _userRepository.modifyProfile(<String, String>{
        'cover': picture,
      });
      final merged = mergeModifiedAccount(current, serverJson);
      final notifier = ref.read(accountProvider.notifier);
      await notifier.setAccount(merged);
      if (!mounted) {
        return;
      }
      context.pop(picture);
    } catch (error) {
      if (mounted) {
        AppToast.show(context, '$error');
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final cover = ref.watch(accountProvider)?.cover ?? '';
    final presetList = ProfileCoverCatalog.presetList;

    return Scaffold(
      backgroundColor: palette.bodyBackground,
      appBar: const CommonAppBar(title: '更换封面'),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              _CustomCoverEntry(onTap: _saving ? null : _pickCustom),
              const SizedBox(height: 16),
              for (var index = 0; index < presetList.length; index++) ...[
                if (index > 0) const SizedBox(height: 12),
                _PresetCoverTile(
                  preset: presetList[index],
                  selected:
                      ProfileCoverCatalog.assetFor(cover) ==
                      presetList[index].asset,
                  onTap: _saving
                      ? null
                      : () => _selectPreset(presetList[index]),
                ),
              ],
            ],
          ),
          if (_saving)
            const ColoredBox(
              color: Color(0x66000000),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}

/// 更换封面页顶部的相册入口。
class _CustomCoverEntry extends StatelessWidget {
  const _CustomCoverEntry({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      color: palette.card,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          height: 90,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '+',
                style: TextStyle(
                  fontSize: 34,
                  height: 1,
                  color: palette.titleText,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '添加自定义背景',
                style: TextStyle(fontSize: 15, color: palette.titleText),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 一张内置封面。选中时描边。
class _PresetCoverTile extends StatelessWidget {
  const _PresetCoverTile({
    required this.preset,
    required this.selected,
    required this.onTap,
  });

  final ProfileCoverPreset preset;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width - 40;
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: width,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(preset.asset, fit: BoxFit.cover),
            if (selected)
              DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: context.palette.primary, width: 3),
                ),
                child: const Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
