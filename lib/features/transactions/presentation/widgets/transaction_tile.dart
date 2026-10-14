import 'package:flutter/material.dart';
import 'package:expense_tracker/core/constants/app_colors.dart';
import 'package:expense_tracker/core/constants/app_text_styles.dart';
import 'package:expense_tracker/core/constants/category_config.dart';
import 'package:expense_tracker/core/theme/dynamic_colors.dart';

class TransactionTile extends StatefulWidget {
  final String title;
  final String date;
  final String amount;
  final bool isIncome;
  final String category;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const TransactionTile({
    super.key,
    required this.title,
    required this.date,
    required this.amount,
    required this.isIncome,
    required this.category,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<TransactionTile> createState() => _TransactionTileState();
}

class _TransactionTileState extends State<TransactionTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _dragExtent = 0.0;
  static const double _maxSlide = -135.0; // Negative for left swipe

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _open() {
    _controller.animateTo(1.0, curve: Curves.easeOutCubic);
  }

  void _close() {
    _controller.animateTo(0.0, curve: Curves.easeInCubic);
  }

  void _handleHorizontalDragUpdate(DragUpdateDetails details) {
    _dragExtent += details.primaryDelta!;
    if (_dragExtent > 0) _dragExtent = 0;
    if (_dragExtent < _maxSlide) _dragExtent = _maxSlide;
    _controller.value = (_dragExtent / _maxSlide).clamp(0.0, 1.0);
  }

  void _handleHorizontalDragEnd(DragEndDetails details) {
    if (_controller.value > 0.4 || details.velocity.pixelsPerSecond.dx < -300) {
      _open();
      _dragExtent = _maxSlide;
    } else {
      _close();
      _dragExtent = 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final catColor =
        CategoryConfig.getColor(widget.category, isIncome: widget.isIncome);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      child: Stack(
        children: [
          // ── Background Action Buttons (Revealed on left swipe) ─────────────
          Positioned.fill(
            child: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF13172E) : const Color(0xFFE2E8F0),
                borderRadius: const BorderRadius.all(Radius.circular(20)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // ✏️ Edit Action Button
                  GestureDetector(
                    onTap: () {
                      _close();
                      _dragExtent = 0.0;
                      widget.onEdit?.call();
                    },
                    child: Container(
                      width: 58,
                      height: 52,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.all(Radius.circular(14)),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.edit_outlined,
                              color: Colors.white, size: 20),
                          SizedBox(height: 2),
                          Text(
                            'Edit',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 🗑️ Delete Action Button
                  GestureDetector(
                    onTap: () {
                      _close();
                      _dragExtent = 0.0;
                      widget.onDelete?.call();
                    },
                    child: Container(
                      width: 58,
                      height: 52,
                      decoration: const BoxDecoration(
                        color: AppColors.expenseRed,
                        borderRadius: BorderRadius.all(Radius.circular(14)),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.delete_outline_rounded,
                              color: Colors.white, size: 20),
                          SizedBox(height: 2),
                          Text(
                            'Delete',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Foreground Slidable Card ──────────────────────────────────────
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final double dx = _controller.value * _maxSlide;
              return Transform.translate(
                offset: Offset(dx, 0),
                child: child,
              );
            },
            child: GestureDetector(
              onHorizontalDragUpdate: _handleHorizontalDragUpdate,
              onHorizontalDragEnd: _handleHorizontalDragEnd,
              onTap: () {
                if (_controller.value > 0.1) {
                  _close();
                  _dragExtent = 0.0;
                } else {
                  widget.onEdit?.call();
                }
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: c.card,
                  borderRadius: const BorderRadius.all(Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                      color: c.shadow,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Icon Section (Tighter 44x44 container)
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: catColor.withOpacity(0.15),
                        borderRadius:
                            const BorderRadius.all(Radius.circular(12)),
                      ),
                      child: Icon(
                          CategoryConfig.getIcon(widget.category,
                              isIncome: widget.isIncome),
                          color: catColor,
                          size: 20),
                    ),
                    const SizedBox(width: 14),

                    // Title & Date Section
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: AppTextStyles.bodyLarge.copyWith(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              color: c.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Text(
                                widget.date,
                                style: AppTextStyles.bodySmall.copyWith(
                                    fontSize: 12, color: c.textSecondary),
                              ),
                              const SizedBox(width: 6),
                              Icon(Icons.swipe_left_rounded,
                                  size: 12,
                                  color: c.textSecondary.withAlpha(120)),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Amount
                    Text(
                      "${widget.isIncome ? "+" : "-"} ₹${widget.amount}",
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: widget.isIncome
                            ? AppColors.incomeGreen
                            : AppColors.expenseRed,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
