import 'package:all_flutter0709/app/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// 自定义 AI 表单提交值。
class AiCreationFormValue {
  const AiCreationFormValue({
    required this.name,
    required this.gender,
    required this.personality,
    required this.outfit,
    required this.career,
    required this.personaInput,
  });

  final String name;
  final int gender;
  final String personality;
  final String outfit;
  final String career;
  final String personaInput;
}

/// 自定义 AI 的固定选项表单。
class AiCreationForm extends StatefulWidget {
  const AiCreationForm({super.key, required this.onSubmit, this.initialValue});

  final ValueChanged<AiCreationFormValue> onSubmit;
  final AiCreationFormValue? initialValue;

  @override
  State<AiCreationForm> createState() => _AiCreationFormState();
}

class _AiCreationFormState extends State<AiCreationForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _personaController = TextEditingController();

  int _gender = 2;
  String _personality = 'random';
  String _outfit = 'random';
  String _career = 'random';

  static const List<_Option<String>> _personalityOptionList = [
    _Option(value: 'random', label: '随机'),
    _Option(value: 'gentle', label: '温柔'),
    _Option(value: 'cheerful', label: '元气'),
    _Option(value: 'cool', label: '清冷'),
    _Option(value: 'mature', label: '成熟'),
    _Option(value: 'tsundere', label: '傲娇'),
    _Option(value: 'sweet', label: '甜美'),
    _Option(value: 'humorous', label: '幽默'),
    _Option(value: 'slow_warm', label: '慢热'),
  ];
  static const List<_Option<String>> _outfitOptionList = [
    _Option(value: 'random', label: '随机'),
    _Option(value: 'casual', label: '清新休闲'),
    _Option(value: 'business', label: '都市通勤'),
    _Option(value: 'sporty', label: '活力运动'),
    _Option(value: 'elegant', label: '优雅精致'),
    _Option(value: 'sweet', label: '甜美清新'),
    _Option(value: 'street', label: '潮流街头'),
    _Option(value: 'vintage', label: '复古文艺'),
    _Option(value: 'home', label: '简约居家'),
    _Option(value: 'luxury', label: '轻奢时尚'),
    _Option(value: 'androgynous', label: '酷飒中性'),
    _Option(value: 'romantic', label: '浪漫约会'),
  ];
  static const List<_Option<String>> _careerOptionList = [
    _Option(value: 'random', label: '随机'),
    _Option(value: 'designer', label: '设计师'),
    _Option(value: 'teacher', label: '教师'),
    _Option(value: 'doctor', label: '医生'),
    _Option(value: 'programmer', label: '程序员'),
    _Option(value: 'entrepreneur', label: '创业者'),
    _Option(value: 'lawyer', label: '律师'),
    _Option(value: 'musician', label: '音乐人'),
    _Option(value: 'barista', label: '咖啡师'),
    _Option(value: 'freelancer', label: '自由职业者'),
  ];

  @override
  void initState() {
    super.initState();
    final initialValue = widget.initialValue;
    if (initialValue == null) return;
    _nameController.text = initialValue.name;
    _personaController.text = initialValue.personaInput;
    _gender = initialValue.gender;
    _personality = initialValue.personality;
    _outfit = initialValue.outfit;
    _career = initialValue.career;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _personaController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    widget.onSubmit(
      AiCreationFormValue(
        name: _nameController.text.trim(),
        gender: _gender,
        personality: _personality,
        outfit: _outfit,
        career: _career,
        personaInput: _personaController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 36),
        children: [
          const Text(
            '创造专属于你的 AI 伙伴',
            style: TextStyle(
              color: AppColors.titleText,
              fontSize: 23,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            '选择角色设定后，我们会依次生成头像和全身形象。',
            style: TextStyle(color: Color(0xFF777777), fontSize: 14),
          ),
          const SizedBox(height: 24),
          const _SectionTitle(title: '名字'),
          const SizedBox(height: 9),
          TextFormField(
            controller: _nameController,
            maxLength: 12,
            decoration: InputDecoration(
              hintText: '输入 2～12 个字',
              counterText: '',
              filled: true,
              fillColor: AppColors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            validator: (value) {
              final name = value?.trim() ?? '';
              if (!RegExp(
                r'^[\u4e00-\u9fa5A-Za-z0-9_]{2,12}$',
              ).hasMatch(name)) {
                return '请输入 2～12 个中文、字母或数字';
              }
              return null;
            },
          ),
          const SizedBox(height: 22),
          const _SectionTitle(title: '性别'),
          const SizedBox(height: 9),
          _choiceWrap<int>(
            optionList: const [
              _Option(value: 2, label: '女生'),
              _Option(value: 1, label: '男生'),
            ],
            selected: _gender,
            onSelected: (value) => setState(() => _gender = value),
          ),
          const SizedBox(height: 22),
          const _SectionTitle(title: '性格'),
          const SizedBox(height: 9),
          _choiceWrap<String>(
            optionList: _personalityOptionList,
            selected: _personality,
            onSelected: (value) => setState(() => _personality = value),
          ),
          const SizedBox(height: 22),
          const _SectionTitle(title: '职业'),
          const SizedBox(height: 9),
          _choiceWrap<String>(
            optionList: _careerOptionList,
            selected: _career,
            onSelected: (value) => setState(() => _career = value),
          ),
          const SizedBox(height: 22),
          const _SectionTitle(title: '穿搭'),
          const SizedBox(height: 9),
          _choiceWrap<String>(
            optionList: _outfitOptionList,
            selected: _outfit,
            onSelected: (value) => setState(() => _outfit = value),
          ),
          const SizedBox(height: 22),
          const _SectionTitle(title: '补充人设（选填）'),
          const SizedBox(height: 7),
          const Text(
            '可以补充性格、爱好、经历和说话方式。若写了衣服、鞋子、配饰或发型，会用于生成头像和全身图。内容会经过 AI 自动审核与整理。',
            style: TextStyle(
              color: Color(0xFF888888),
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 9),
          TextFormField(
            controller: _personaController,
            maxLength: 300,
            minLines: 3,
            maxLines: 5,
            textInputAction: TextInputAction.newline,
            decoration: InputDecoration(
              hintText:
                  '例如：喜欢摄影，刚认识时有点高冷，熟悉后会变得很健谈。\n穿搭提示：白衬衫、牛仔裤和白色运动鞋。',
              filled: true,
              fillColor: AppColors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 48,
            child: FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.auto_awesome_rounded),
              label: const Text('开始创造'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '生成过程可能需要 1～3 分钟，请保持页面开启。',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF999999), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _choiceWrap<T>({
    required List<_Option<T>> optionList,
    required T selected,
    required ValueChanged<T> onSelected,
  }) {
    return Wrap(
      spacing: 9,
      runSpacing: 9,
      children: optionList.map((option) {
        final isSelected = option.value == selected;
        return ChoiceChip(
          label: Text(option.label),
          selected: isSelected,
          showCheckmark: false,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          side: BorderSide.none,
          backgroundColor: AppColors.white,
          selectedColor: AppColors.primary.withValues(alpha: 0.14),
          labelStyle: TextStyle(
            color: isSelected ? AppColors.primary : AppColors.titleText,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
          onSelected: (_) => onSelected(option.value),
        );
      }).toList(),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.titleText,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _Option<T> {
  const _Option({required this.value, required this.label});

  final T value;
  final String label;
}
