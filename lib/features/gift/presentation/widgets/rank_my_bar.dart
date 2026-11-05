import 'package:all_flutter0709/app/theme/app_colors.dart';
import 'package:all_flutter0709/features/gift/data/gift_model.dart';
import 'package:all_flutter0709/features/gift/presentation/widgets/gift_user_avatar.dart';
import 'package:flutter/material.dart';

/// 榜单列表底部「我的」一行，样式与 [第 4 名起] 的 cell 一致。
class RankMyBar extends StatelessWidget {
  const RankMyBar({
    super.key,
    required this.charm,
    required this.self,
    this.loading = false,
    this.onTap,
    this.scrollEmbedded = false,
  });

  final bool charm;
  final RankSelfResult? self;
  final bool loading;
  final VoidCallback? onTap;

  /// 作为 ListView footer 内嵌时不再叠加底部安全区（由列表 padding 留出 Tab 栏）。
  final bool scrollEmbedded;

  static const _rankColumnWidth = 48.0;

  @override
  Widget build(BuildContext context) {
    final bottom = scrollEmbedded ? 0.0 : MediaQuery.paddingOf(context).bottom;
    final score = self == null
        ? 0
        : (charm ? self!.vcharm : self!.vsend);
    final rankLabel = self == null || self!.rank <= 0 ? '未上榜' : '${self!.rank}';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.fromLTRB(14, 11, 14, 11 + bottom),
          child: loading
              ? const SizedBox(
                  height: 44,
                  child: Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                )
              : Row(
                  children: [
                    SizedBox(
                      width: _rankColumnWidth,
                      child: Text(
                        rankLabel,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.fade,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF666666),
                        ),
                      ),
                    ),
                    GiftUserAvatar(url: self?.avatarUrl, size: 44),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        self?.name.isNotEmpty == true ? self!.name : '我',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.titleText,
                        ),
                      ),
                    ),
                    Text(
                      '$score',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.link,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
