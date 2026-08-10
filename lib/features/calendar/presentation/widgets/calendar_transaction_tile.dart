import 'package:flutter/material.dart';
import 'package:expense_tracker/core/constants/app_colors.dart';
import 'package:expense_tracker/core/theme/dynamic_colors.dart';
import 'package:expense_tracker/features/transactions/data/models/transaction_model.dart';
import 'package:expense_tracker/features/transactions/presentation/widgets/add_expense_helper.dart';

class CalendarTransactionTile extends StatefulWidget {
  final TransactionModel tx;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const CalendarTransactionTile({
    super.key,
    required this.tx,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<CalendarTransactionTile> createState() => _CalendarTransactionTileState();
}

class _CalendarTransactionTileState extends State<CalendarTransactionTile>
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final catColor = AddExpenseHelper.getCategoryColor(widget.tx.category, isIncome: widget.tx.isIncome);
    final icon = AddExpenseHelper.getCategoryIcon(widget.tx.category, isIncome: widget.tx.isIncome);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          // ── Background Actions (Revealed on left swipe) ────────────────────
          Positioned.fill(
            child: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF13172E) : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(16),
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
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.edit_outlined, color: Colors.white, size: 20),
                          SizedBox(height: 2),
                          Text(
                            'Edit',
                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
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
                      decoration: BoxDecoration(
                        color: AppColors.expenseRed,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.delete_outline_rounded, color: Colors.white, size: 20),
                          SizedBox(height: 2),
                          Text(
                            'Delete',
                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1B203E) : const Color(0xFFF1F3F6),
                  borderRadius: BorderRadius.circular(16),
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
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: catColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        color: catColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.tx.title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: c.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: catColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  widget.tx.category,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: catColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(Icons.swipe_left_rounded, size: 14, color: c.textSecondary.withAlpha(120)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      "${widget.tx.isIncome ? '+' : '-'} ₹${widget.tx.amount.toInt() == widget.tx.amount ? widget.tx.amount.toInt().toString() : widget.tx.amount.toStringAsFixed(2)}",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: widget.tx.isIncome ? AppColors.incomeGreen : c.textPrimary,
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
