import 'package:all_flutter0709/app/router/app_routes.dart';
import 'package:all_flutter0709/app/theme/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 搜索入口，对齐 Android 搜索页：关键词输入、搜索历史、取消返回。
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  static const _historyKey = 'search_history';
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<String> _historyList = <String>[];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _historyList = prefs.getStringList(_historyKey) ?? <String>[];
    });
  }

  Future<void> _saveHistory(List<String> historyList) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_historyKey, historyList);
    if (!mounted) return;
    setState(() => _historyList = historyList);
  }

  Future<void> _search(String raw) async {
    final keyword = raw.trim();
    if (keyword.isEmpty) {
      return;
    }
    final next = <String>[
      keyword,
      ..._historyList.where((item) => item != keyword),
    ].take(12).toList();
    await _saveHistory(next);
    if (!mounted) return;
    await context.push(AppRoutes.meSearchResult, extra: keyword);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      backgroundColor: palette.plainBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: palette.pressed,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          _tintedIcon(
                            'assets/icons/me/searchbar_textfield_search_icon.png',
                            16,
                            palette,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              focusNode: _focusNode,
                              autofocus: true,
                              textInputAction: TextInputAction.search,
                              style: TextStyle(
                                fontSize: 15,
                                color: palette.titleText,
                              ),
                              cursorColor: palette.ink,
                              decoration: InputDecoration(
                                isCollapsed: true,
                                border: InputBorder.none,
                                hintText: '输入关键词',
                                hintStyle: TextStyle(
                                  fontSize: 15,
                                  color: palette.secondaryText,
                                ),
                              ),
                              onSubmitted: _search,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.pop(),
                    child: Text(
                      '取消',
                      style: TextStyle(fontSize: 16, color: palette.titleText),
                    ),
                  ),
                ],
              ),
            ),
            if (_historyList.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Text(
                  '搜索历史',
                  style: TextStyle(fontSize: 13, color: palette.secondaryText),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _historyList.length + 1,
                  itemBuilder: (context, index) {
                    if (index == _historyList.length) {
                      return TextButton(
                        onPressed: () => _saveHistory(<String>[]),
                        child: Text(
                          '清空搜索历史',
                          style: TextStyle(
                            fontSize: 14,
                            color: palette.secondaryText,
                          ),
                        ),
                      );
                    }
                    final keyword = _historyList[index];
                    return InkWell(
                      onTap: () => _search(keyword),
                      child: SizedBox(
                        height: 48,
                        child: Row(
                          children: [
                            const SizedBox(width: 16),
                            _tintedIcon(
                              'assets/icons/me/search_left_history.png',
                              18,
                              palette,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                keyword,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: palette.bodyText,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                final next = List<String>.from(_historyList)
                                  ..removeAt(index);
                                _saveHistory(next);
                              },
                              icon: Icon(
                                Icons.close,
                                size: 18,
                                color: palette.secondaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 浅色保留原图。深色把单色图标染成次要文字色，避免灰图标沉进深色底。
Widget _tintedIcon(String asset, double size, AppPalette palette) {
  final image = Image.asset(asset, width: size, height: size);
  if (palette.brightness != Brightness.dark) {
    return image;
  }
  return ColorFiltered(
    colorFilter: ColorFilter.mode(palette.secondaryText, BlendMode.srcIn),
    child: image,
  );
}
