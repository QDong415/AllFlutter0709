import 'package:all_flutter0709/app/router/app_routes.dart';
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
    return Scaffold(
      backgroundColor: Colors.white,
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
                        color: const Color(0xFFF2F2F2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Image.asset(
                            'assets/icons/me/searchbar_textfield_search_icon.png',
                            width: 16,
                            height: 16,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              focusNode: _focusNode,
                              autofocus: true,
                              textInputAction: TextInputAction.search,
                              style: const TextStyle(
                                fontSize: 15,
                                color: Color(0xFF333333),
                              ),
                              decoration: const InputDecoration(
                                isCollapsed: true,
                                border: InputBorder.none,
                                hintText: '输入关键词',
                                hintStyle: TextStyle(
                                  fontSize: 15,
                                  color: Color(0xFFB0B0B0),
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
                    child: const Text(
                      '取消',
                      style: TextStyle(fontSize: 16, color: Color(0xFF333333)),
                    ),
                  ),
                ],
              ),
            ),
            if (_historyList.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Text(
                  '搜索历史',
                  style: TextStyle(fontSize: 13, color: Color(0xFF979797)),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _historyList.length + 1,
                  itemBuilder: (context, index) {
                    if (index == _historyList.length) {
                      return TextButton(
                        onPressed: () => _saveHistory(<String>[]),
                        child: const Text(
                          '清空搜索历史',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFFB0B0B0),
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
                            Image.asset(
                              'assets/icons/me/search_left_history.png',
                              width: 18,
                              height: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                keyword,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF666666),
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                final next = List<String>.from(_historyList)
                                  ..removeAt(index);
                                _saveHistory(next);
                              },
                              icon: const Icon(
                                Icons.close,
                                size: 18,
                                color: Color(0xFFB0B0B0),
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
