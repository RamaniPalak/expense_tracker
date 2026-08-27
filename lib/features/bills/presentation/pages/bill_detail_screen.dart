import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_tracker/core/constants/app_colors.dart';
import 'package:expense_tracker/core/constants/app_text_styles.dart';
import 'package:expense_tracker/core/di/injection_container.dart';
import 'package:expense_tracker/core/theme/dynamic_colors.dart';
import 'package:expense_tracker/features/bills/data/models/bill_model.dart';
import 'package:expense_tracker/features/transactions/data/models/transaction_model.dart';
import 'package:expense_tracker/services/database_helper.dart';
import 'package:expense_tracker/routing/app_router.dart';

class BillDetailScreen extends StatefulWidget {
  final BillModel bill;

  const BillDetailScreen({super.key, required this.bill});

  @override
  State<BillDetailScreen> createState() => _BillDetailScreenState();
}

class _BillDetailScreenState extends State<BillDetailScreen> {
  late BillModel _bill;
  bool _isMarkingPaid = false;

  @override
  void initState() {
    super.initState();
    _bill = widget.bill;
  }

  int get _diffDays {
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final due = DateTime(_bill.dueDate.year, _bill.dueDate.month, _bill.dueDate.day);
    return due.difference(today).inDays;
  }

  bool get _isOverdue => !_bill.isPaid && _diffDays < 0;

  bool get _isUrgent => !_bill.isPaid && _diffDays <= 3 && _diffDays >= 0;

  Color get _statusColor {
    if (_bill.isPaid) return AppColors.incomeGreen;
    if (_isOverdue) return AppColors.expenseRed;
    if (_isUrgent) return Colors.orange;
    return AppColors.primary;
  }

  String get _statusLabel {
    if (_bill.isPaid) return 'Paid';
    if (_isOverdue) {
      return 'Overdue by ${_diffDays.abs()} day${_diffDays.abs() == 1 ? '' : 's'}';
    }
    if (_diffDays == 0) return 'Due today';
    return 'Due in $_diffDays day${_diffDays == 1 ? '' : 's'}';
  }

  List<_TimelineEntry> _buildTimeline() {
    final entries = <_TimelineEntry>[];

    if (!_bill.isRecurring) {
      entries.add(_TimelineEntry(
        date: _bill.dueDate,
        amount: _bill.amount,
        isCurrent: true,
        isPast: _bill.isPaid,
        isFuture: false,
      ));
      return entries;
    }

    const pastCount = 3;
    const futureCount = 3;

    for (int i = pastCount; i >= 1; i--) {
      final pastDate = _shiftMonth(_bill.dueDate, -i);
      entries.add(_TimelineEntry(
        date: pastDate,
        amount: _bill.amount,
        isCurrent: false,
        isPast: true,
        isFuture: false,
      ));
    }

    entries.add(_TimelineEntry(
      date: _bill.dueDate,
      amount: _bill.amount,
      isCurrent: true,
      isPast: false,
      isFuture: false,
    ));

    for (int i = 1; i <= futureCount; i++) {
      final futureDate = _shiftMonth(_bill.dueDate, i);
      entries.add(_TimelineEntry(
        date: futureDate,
        amount: _bill.amount,
        isCurrent: false,
        isPast: false,
        isFuture: true,
      ));
    }

    return entries;
  }

  DateTime _shiftMonth(DateTime base, int monthOffset) {
    int newMonth = base.month + monthOffset;
    int newYear = base.year;
    while (newMonth > 12) {
      newMonth -= 12;
      newYear++;
    }
    while (newMonth < 1) {
      newMonth += 12;
      newYear--;
    }
    final lastDay = DateTime(newYear, newMonth + 1, 0).day;
    return DateTime(newYear, newMonth, base.day.clamp(1, lastDay));
  }

  Future<void> _markAsPaid() async {
    setState(() => _isMarkingPaid = true);

    await sl<DatabaseHelper>().updateBill(_bill.copyWith(isPaid: true));

    final transaction = TransactionModel(
      title: 'Paid: ${_bill.title}',
      amount: _bill.amount,
      date: DateTime.now(),
      category: _bill.category,
      isIncome: false,
      userEmail: _bill.userEmail,
    );
    await sl<DatabaseHelper>().insertExpense(transaction);

    if (_bill.isRecurring) {
      final nextMonth = DateTime(_bill.dueDate.year, _bill.dueDate.month + 1, 1);
      final lastDay = DateTime(nextMonth.year, nextMonth.month + 1, 0).day;
      final nextDue = DateTime(
        nextMonth.year,
        nextMonth.month,
        _bill.dueDate.day.clamp(1, lastDay),
      );
      if (_bill.endDate == null ||
          nextDue.isBefore(_bill.endDate!) ||
          nextDue.isAtSameMomentAs(_bill.endDate!)) {
        final nextBill = BillModel(
          title: _bill.title,
          amount: _bill.amount,
          dueDate: nextDue,
          endDate: _bill.endDate,
          category: _bill.category,
          isPaid: false,
          isRecurring: _bill.isRecurring,
          userEmail: _bill.userEmail,
        );
        await sl<DatabaseHelper>().insertBill(nextBill);
      }
    }

    setState(() {
      _bill = _bill.copyWith(isPaid: true);
      _isMarkingPaid = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${_bill.title} marked as paid & added to expenses!'),
        backgroundColor: AppColors.incomeGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  Future<void> _showEditSheet() async {
    final result = await context.push(
      RoutePaths.addEditBill,
      extra: {'bill': _bill, 'userEmail': _bill.userEmail},
    );
    if (result == 'deleted' && mounted) {
      context.pop(true); // Signal bills list to refresh
    } else if (result is BillModel && mounted) {
      setState(() => _bill = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timeline = _buildTimeline();

    final bgColor = isDark ? const Color(0xFF0F121D) : c.background;
    final textColor = isDark ? Colors.white : c.textPrimary;
    final textSubColor = isDark ? Colors.white70 : c.textSecondary;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top Nav ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.black.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.arrow_back_ios_new_rounded,
                            color: textColor, size: 18),
                        onPressed: () => context.pop(),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Upcoming Bill Details',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.heading2
                            .copyWith(color: textColor, fontSize: 16),
                      ),
                    ),
                    if (!_bill.isPaid)
                      Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.05)
                              : Colors.black.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: Icon(Icons.edit_outlined, color: textColor, size: 18),
                          onPressed: _showEditSheet,
                        ),
                      )
                    else
                      const SizedBox(width: 48),
                  ],
                ),
              ),

              // ── Bill Header Info ──────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _statusColor.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Text('🧾', style: TextStyle(fontSize: 20)),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withOpacity(0.08)
                                : Colors.black.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _statusLabel,
                            style: AppTextStyles.bodySmall.copyWith(
                                color: textColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF151828) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border:
                            Border.all(color: isDark ? Colors.white12 : Colors.black12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _bill.title.toUpperCase(),
                            style: AppTextStyles.heading1.copyWith(
                                color: textColor, fontSize: 16, letterSpacing: -0.5),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _bill.category,
                            style: AppTextStyles.bodyMedium
                                .copyWith(color: textSubColor, fontSize: 13),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Next payment',
                                  style: AppTextStyles.bodyMedium
                                      .copyWith(color: textSubColor, fontSize: 13)),
                              Text('₹ ${_bill.amount.toStringAsFixed(0)}',
                                  style: AppTextStyles.heading2
                                      .copyWith(color: textColor, fontSize: 15)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Expected date',
                                  style: AppTextStyles.bodyMedium
                                      .copyWith(color: textSubColor, fontSize: 13)),
                              Text(DateFormat('MMM dd, yyyy').format(_bill.dueDate),
                                  style: AppTextStyles.heading2
                                      .copyWith(color: textColor, fontSize: 15)),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    Text('Payment details',
                        style: AppTextStyles.heading2
                            .copyWith(color: textColor, fontSize: 18)),
                    const SizedBox(height: 16),

                    // ── Timeline list ──────────────────────────────────────────
                    _buildTimelineList(
                        timeline, c, isDark, bgColor, textColor, textSubColor),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineList(List<_TimelineEntry> entries, dynamic c, bool isDark,
      Color bgColor, Color textColor, Color textSubColor) {
    return Stack(
      children: [
        // The continuous dashed line
        Positioned(
          left: 11,
          top: 24,
          bottom: 24,
          child: CustomPaint(
            painter: _DashedLinePainter(color: isDark ? Colors.white24 : Colors.black26),
          ),
        ),
        Column(
          children: entries.map((e) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // The dot container
                Container(
                  width: 24,
                  height: 24,
                  margin: const EdgeInsets.only(top: 20),
                  decoration: BoxDecoration(
                    color: bgColor,
                  ),
                  alignment: Alignment.center,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: bgColor,
                      border: Border.all(
                        color: e.isCurrent
                            ? _statusColor
                            : (isDark ? Colors.white54 : Colors.black54),
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // The card
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _TimelineCard(
                      entry: e,
                      billTitle: _bill.title,
                      statusColor: _statusColor,
                      c: c,
                      isDark: isDark,
                      textColor: textColor,
                      textSubColor: textSubColor,
                      onMarkPaid: (!_bill.isPaid && e.isCurrent) ? _markAsPaid : null,
                      isMarkingPaid: _isMarkingPaid,
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ─── Timeline data model ────────────────────────────────────────────────────
class _TimelineEntry {
  final DateTime date;
  final double amount;
  final bool isCurrent;
  final bool isPast;
  final bool isFuture;

  const _TimelineEntry({
    required this.date,
    required this.amount,
    required this.isCurrent,
    required this.isPast,
    required this.isFuture,
  });
}

// ─── Timeline Card ──────────────────────────────────────────────────────────
class _TimelineCard extends StatelessWidget {
  final _TimelineEntry entry;
  final String billTitle;
  final Color statusColor;
  final dynamic c;
  final bool isDark;
  final Color textColor;
  final Color textSubColor;
  final VoidCallback? onMarkPaid;
  final bool isMarkingPaid;

  const _TimelineCard({
    required this.entry,
    required this.billTitle,
    required this.statusColor,
    required this.c,
    required this.isDark,
    required this.textColor,
    required this.textSubColor,
    this.onMarkPaid,
    this.isMarkingPaid = false,
  });

  @override
  Widget build(BuildContext context) {
    final isFaded = entry.isFuture;
    final isPaid = entry.isPast;

    final cardBg = entry.isCurrent
        ? (isDark ? const Color(0xFF1B2236) : const Color(0xFFF0FAF9))
        : Colors.transparent;

    final borderColor =
        entry.isCurrent ? statusColor : (isDark ? Colors.white24 : Colors.black26);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: borderColor,
          width: entry.isCurrent ? 1.5 : 1,
        ),
        boxShadow: entry.isCurrent
            ? [
                BoxShadow(
                    color: statusColor.withOpacity(isDark ? 0.2 : 0.1),
                    blurRadius: 16,
                    offset: const Offset(0, 4)),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  billTitle,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isFaded ? textSubColor : textColor,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isPaid)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.incomeGreen.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Paid',
                      style: TextStyle(
                          fontSize: 10,
                          color: AppColors.incomeGreen,
                          fontWeight: FontWeight.bold)),
                )
              else if (entry.isCurrent)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('Current',
                      style: TextStyle(
                          fontSize: 10, color: statusColor, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('MMM dd, yyyy').format(entry.date),
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 12,
              color: isFaded ? textSubColor.withOpacity(0.6) : textSubColor,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '₹ ${entry.amount.toStringAsFixed(0)}',
                style: AppTextStyles.heading2.copyWith(
                  fontSize: 16,
                  color: isFaded ? textSubColor : textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (entry.isCurrent && onMarkPaid != null)
                ElevatedButton(
                  onPressed: isMarkingPaid ? null : onMarkPaid,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape:
                        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: isMarkingPaid
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Mark as paid',
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;

  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    double dashHeight = 5, dashSpace = 5, startY = 0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    while (startY < size.height) {
      canvas.drawLine(Offset(size.width / 2, startY),
          Offset(size.width / 2, startY + dashHeight), paint);
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
