import 'package:all_flutter0709/app/theme/app_colors.dart';
import 'package:all_flutter0709/core/account/account_provider.dart';
import 'package:all_flutter0709/core/qiniu/qiniu_upload_service.dart';
import 'package:all_flutter0709/core/utils/value_util.dart';
import 'package:all_flutter0709/features/auth/presentation/helpers/signup_avatar_helper.dart';
import 'package:all_flutter0709/features/me/presentation/helpers/me_account_helper.dart';
import 'package:all_flutter0709/features/user/data/user_repository.dart';
import 'package:all_flutter0709/shared/widgets/common_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// 编辑资料，对齐 Android「我的资料」页。
class ProfileEditPage extends ConsumerStatefulWidget {
  const ProfileEditPage({super.key});

  @override
  ConsumerState<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends ConsumerState<ProfileEditPage> {
  final UserRepository _userRepository = const UserRepository();
  bool _saving = false;

  Future<void> _save(Map<String, String> fields) async {
    final current = ref.read(accountProvider);
    if (current == null || _saving) {
      return;
    }
    setState(() => _saving = true);
    try {
      final serverJson = await _userRepository.modifyProfile(fields);
      await ref
          .read(accountProvider.notifier)
          .setAccount(mergeModifiedAccount(current, serverJson));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$error')));
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _changeAvatar() async {
    final helper = SignupAvatarHelper(
      qiniuUploadService: ref.read(qiniuUploadServiceProvider),
    );
    final file = await helper.pickAndCropAvatar(context);
    if (file == null) {
      return;
    }
    try {
      final key = await helper.uploadAvatar(file);
      await _save(<String, String>{'avatar': key});
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }

  Future<void> _editText({
    required String title,
    required String field,
    required String initial,
    required int maxLength,
    bool canEmpty = false,
    bool multiline = false,
  }) async {
    final result = await context.push<String>(
      '/me/text-edit',
      extra: ProfileTextEditArgs(
        title: title,
        initial: initial,
        maxLength: maxLength,
        canEmpty: canEmpty,
        multiline: multiline,
      ),
    );
    if (result == null) {
      return;
    }
    await _save(<String, String>{field: result});
  }

  Future<void> _pickAge(int currentAge) async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      builder: (context) {
        return ListView.builder(
          itemCount: 35,
          itemBuilder: (context, index) {
            final age = 15 + index;
            return ListTile(
              title: Text('$age'),
              selected: age == currentAge,
              onTap: () => Navigator.pop(context, age),
            );
          },
        );
      },
    );
    if (selected == null) {
      return;
    }
    await _save(<String, String>{'age': '$selected'});
  }

  Future<void> _pickCity() async {
    List<CityNodeModel> provinceList;
    try {
      provinceList = await _userRepository.getCityList();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$error')));
      }
      return;
    }
    if (!mounted || provinceList.isEmpty) {
      return;
    }
    final picked = await showModalBottomSheet<_CityPick>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _CityPicker(provinceList: provinceList),
    );
    if (picked == null) {
      return;
    }
    await _save(<String, String>{
      'cityname': picked.name,
      'cityid': cityIdFromAdCode(picked.code),
      'adid': picked.code,
    });
  }

  @override
  Widget build(BuildContext context) {
    final account = ref.watch(accountProvider);
    final avatarUrl =
        ValueUtil.getQiniuUrlByFileName(account?.avatar, thumbnail: true) ?? '';
    final genderText = switch (account?.gender) {
      1 => '男',
      2 => '女',
      _ => '未填',
    };
    final age = account?.age ?? 0;
    final intro = account?.intro ?? '';

    return Scaffold(
      backgroundColor: AppColors.bodyBackground,
      appBar: const CommonAppBar(title: '我的资料'),
      body: Stack(
        children: [
          ListView(
            children: [
              const _SectionLabel('基本资料'),
              _EditRow(
                label: '头像',
                onTap: _changeAvatar,
                trailing: CircleAvatar(
                  radius: 16,
                  backgroundColor: const Color(0xFFE6E6E6),
                  backgroundImage: avatarUrl.isEmpty
                      ? null
                      : NetworkImage(avatarUrl),
                  child: avatarUrl.isEmpty
                      ? const Icon(Icons.person, size: 18, color: Colors.white)
                      : null,
                ),
              ),
              _EditRow(
                label: '昵称',
                value: account?.name ?? '',
                onTap: () => _editText(
                  title: '昵称',
                  field: 'name',
                  initial: account?.name ?? '',
                  maxLength: 12,
                ),
              ),
              _EditRow(
                label: '年龄',
                value: age == 0 ? '' : '$age岁',
                onTap: () => _pickAge(age),
              ),
              _EditRow(label: '性别', value: genderText),
              _EditRow(
                label: '城市',
                value: account?.cityName ?? '',
                onTap: _pickCity,
              ),
              const _SectionLabel('自我介绍'),
              Material(
                color: AppColors.white,
                child: InkWell(
                  onTap: () => _editText(
                    title: '自我介绍',
                    field: 'intro',
                    initial: intro,
                    maxLength: 150,
                    canEmpty: true,
                    multiline: true,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    child: Text(
                      intro.isEmpty ? '未填写' : intro,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: intro.isEmpty
                            ? const Color(0xFFBBBBBB)
                            : AppColors.titleText,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_saving) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}

/// 灰底分组标题，对齐 Android 资料页的「基本资料 / 自我介绍」。
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13, color: Color(0xFF999999)),
      ),
    );
  }
}

/// 资料行：左侧标题，右侧数值或头像，最右箭头。
class _EditRow extends StatelessWidget {
  const _EditRow({
    required this.label,
    this.value = '',
    this.trailing,
    this.onTap,
    this.showArrow = true,
  });

  final String label;
  final String value;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showArrow;

  @override
  Widget build(BuildContext context) {
    final isPlaceholder = value.isEmpty && trailing == null;
    return Material(
      color: AppColors.white,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 50,
          padding: const EdgeInsets.only(left: 16),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Color(0xFFE6E6E6), width: 0.5),
            ),
          ),
          child: Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.titleText,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isPlaceholder ? '未填写' : value,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    color: isPlaceholder
                        ? const Color(0xFFBBBBBB)
                        : const Color(0xFF999999),
                  ),
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing!,
                const SizedBox(width: 2),
              ],
              if (showArrow)
                const Padding(
                  padding: EdgeInsets.only(right: 4),
                  child: Icon(Icons.chevron_right, color: Color(0xFFC8C8C8)),
                )
              else
                const SizedBox(width: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _CityPick {
  const _CityPick({required this.name, required this.code});

  final String name;
  final String code;
}

class _CityPicker extends StatefulWidget {
  const _CityPicker({required this.provinceList});

  final List<CityNodeModel> provinceList;

  @override
  State<_CityPicker> createState() => _CityPickerState();
}

class _CityPickerState extends State<_CityPicker> {
  int _provinceIndex = 0;
  int _cityIndex = 0;

  @override
  Widget build(BuildContext context) {
    final province = widget.provinceList[_provinceIndex];
    final cityList = province.children;
    final city = cityList.isEmpty
        ? null
        : cityList[_cityIndex.clamp(0, cityList.length - 1)];

    return SafeArea(
      child: SizedBox(
        height: 360,
        child: Column(
          children: [
            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
                const Expanded(
                  child: Text('城市选择', textAlign: TextAlign.center),
                ),
                TextButton(
                  onPressed: () {
                    final name = city?.name.isNotEmpty == true
                        ? city!.name
                        : province.name;
                    final code = city?.code.isNotEmpty == true
                        ? city!.code
                        : province.code;
                    Navigator.pop(context, _CityPick(name: name, code: code));
                  },
                  child: const Text('确定'),
                ),
              ],
            ),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: widget.provinceList.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          selected: index == _provinceIndex,
                          title: Text(widget.provinceList[index].name),
                          onTap: () => setState(() {
                            _provinceIndex = index;
                            _cityIndex = 0;
                          }),
                        );
                      },
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: cityList.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          selected: index == _cityIndex,
                          title: Text(cityList[index].name),
                          onTap: () => setState(() => _cityIndex = index),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 单行或简介编辑参数。
class ProfileTextEditArgs {
  const ProfileTextEditArgs({
    required this.title,
    required this.initial,
    required this.maxLength,
    this.canEmpty = false,
    this.multiline = false,
  });

  final String title;
  final String initial;
  final int maxLength;
  final bool canEmpty;
  final bool multiline;
}
