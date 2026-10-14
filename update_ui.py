import sys

with open(r'd:\Palak_Data\expense_tracker\lib\features\bills\presentation\pages\bill_detail_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

start_marker = "  @override\n  Widget build(BuildContext context) {"
end_marker = "}\n\n// ------------------------------------------------------------------------------\n// Supporting widgets"

new_methods = " " "  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timeline = _buildTimeline();

    // Use a very dark background to match the reference if in dark mode, or use standard card color.
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
              // -- Top Nav ---------------------------------------------
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 18),
                        onPressed: () => context.pop(),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Upcoming Bill Details',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.heading2.copyWith(color: textColor, fontSize: 16),
                      ),
                    ),
                    if (!_bill.isPaid)
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
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

              // -- Bill Header Info --------------------------------------
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
                          child: const Text('??', style: TextStyle(fontSize: 20)), 
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
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
                    const SizedBox(height: 24),
                    Text(
                      _bill.title.toUpperCase(),
                      style: AppTextStyles.heading1.copyWith(color: textColor, fontSize: 28, letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _bill.category,
                      style: AppTextStyles.bodyMedium.copyWith(color: textSubColor, fontSize: 16),
                    ),
                    const SizedBox(height: 32),
                    
                    // Stats Row 1
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Next payment', style: AppTextStyles.bodyMedium.copyWith(color: textSubColor)),
                        Text('? ', style: AppTextStyles.heading2.copyWith(color: textColor, fontSize: 18)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Stats Row 2
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Expected date', style: AppTextStyles.bodyMedium.copyWith(color: textSubColor)),
                        Text(DateFormat('MMM dd, yyyy').format(_bill.dueDate), style: AppTextStyles.heading2.copyWith(color: textColor, fontSize: 16)),
                      ],
                    ),
                    
                    const SizedBox(height: 32),
                    Divider(color: isDark ? Colors.white12 : Colors.black12, height: 1),
                    const SizedBox(height: 32),
                    
                    Text('Payment details', style: AppTextStyles.heading2.copyWith(color: textColor, fontSize: 20)),
                    const SizedBox(height: 24),
                    
                    // -- Timeline list ------------------------------------------
                    _buildTimelineList(timeline, c, isDark, bgColor, textColor, textSubColor),
                    
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

  // --- Timeline list widget ---------------------------------------------------
  Widget _buildTimelineList(
      List<_TimelineEntry> entries, dynamic c, bool isDark, Color bgColor, Color textColor, Color textSubColor) {
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
                        color: e.isCurrent ? _statusColor : (isDark ? Colors.white54 : Colors.black54),
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
" " "

start_idx = content.find(start_marker)
end_idx = content.find(end_marker)
if start_idx != -1 and end_idx != -1:
    content = content[:start_idx] + new_methods + content[end_idx:]
else:
    print('Build method markers not found')

info_start = content.find("class _InfoPill extends StatelessWidget {")
info_end = content.find("// --- Timeline data model", info_start)
if info_start != -1 and info_end != -1:
    content = content[:info_start] + content[info_end:]
else:
    print('InfoPill markers not found')

tc_start = content.find("class _TimelineCard extends StatelessWidget {")
tc_end = content.find("// ------------------------------------------------------------------------------\n// Edit Bill Bottom Sheet")

new_tc = " " "class _TimelineCard extends StatelessWidget {
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

    final borderColor = entry.isCurrent
        ? statusColor
        : (isDark ? Colors.white24 : Colors.black26);

    return Container(
      padding: const EdgeInsets.all(16),
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
                      style: TextStyle(fontSize: 10, color: AppColors.incomeGreen, fontWeight: FontWeight.bold)),
                )
              else if (entry.isCurrent)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('Current',
                      style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            DateFormat('MMM dd, yyyy').format(entry.date),
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 12,
              color: isFaded ? textSubColor.withOpacity(0.6) : textSubColor,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                '? ',
                style: AppTextStyles.heading2.copyWith(
                  fontSize: 18,
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: isMarkingPaid
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Mark as paid', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

" " "
if tc_start != -1 and tc_end != -1:
    content = content[:tc_start] + new_tc + content[tc_end:]
else:
    print('TimelineCard markers not found')

dashed_painter = " " "
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
      canvas.drawLine(Offset(size.width / 2, startY), Offset(size.width / 2, startY + dashHeight), paint);
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
" " "
content += dashed_painter

with open(r'd:\Palak_Data\expense_tracker\lib\features\bills\presentation\pages\bill_detail_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print('Updated UI successfully.')
