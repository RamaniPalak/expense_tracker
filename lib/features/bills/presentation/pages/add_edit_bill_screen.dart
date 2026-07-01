import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_tracker/core/constants/app_colors.dart';
import 'package:expense_tracker/core/constants/app_text_styles.dart';
import 'package:expense_tracker/core/di/injection_container.dart';
import 'package:expense_tracker/features/bills/data/models/bill_model.dart';
import 'package:expense_tracker/services/database_helper.dart';
import 'package:expense_tracker/core/theme/dynamic_colors.dart';

class AddEditBillScreen extends StatefulWidget {
  final BillModel? bill;
  final String userEmail;

  const AddEditBillScreen({super.key, this.bill, required this.userEmail});

  @override
  State<AddEditBillScreen> createState() => _AddEditBillScreenState();
}

class _AddEditBillScreenState extends State<AddEditBillScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _titleCtrl;
  late TextEditingController _amountCtrl;
  late DateTime _startDate;
  late DateTime _endDate;
  late bool _isRecurring;

  bool _isSaving = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.bill?.title ?? '');
    _amountCtrl = TextEditingController(
      text: widget.bill != null ? widget.bill!.amount.toStringAsFixed(2) : '',
    );
    _endDate = widget.bill?.dueDate ?? DateTime.now().add(const Duration(days: 7));
    _startDate = _endDate.subtract(const Duration(days: 7));
    _isRecurring = widget.bill?.isRecurring ?? true;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveBill() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '')) ?? 0.0;
    final bill = BillModel(
      id: widget.bill?.id,
      title: _titleCtrl.text.trim(),
      amount: amount,
      dueDate: _startDate,
      endDate: _endDate,
      category: 'Other Expense',
      isRecurring: _isRecurring,
      isPaid: widget.bill?.isPaid ?? false,
      userEmail: widget.userEmail,
    );

    final db = sl<DatabaseHelper>();
    if (widget.bill == null) {
      await db.insertBill(bill);
    } else {
      await db.updateBill(bill);
    }

    if (mounted) {
      setState(() => _isSaving = false);
      context.pop(bill); // Return updated bill to signal refresh
    }
  }

  Future<void> _deleteBill() async {
    if (widget.bill?.id == null) return;
    
    setState(() => _isDeleting = true);
    await sl<DatabaseHelper>().deleteBill(widget.bill!.id!, widget.userEmail);
    
    if (mounted) {
      setState(() => _isDeleting = false);

      context.pop('deleted');
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF0B0D17) : c.background;
    final cardColor = isDark ? const Color(0xFF151828) : c.card;
    final textColor = isDark ? Colors.white : c.textPrimary;
    final hintColor = isDark ? Colors.white54 : c.textSecondary;
    final borderColor = isDark ? cardColor : c.border;
    final isEditing = widget.bill != null;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // ── App Bar ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 18),
                        onPressed: () => context.pop(),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Upcoming Bill',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.heading2.copyWith(color: textColor, fontSize: 18),
                      ),
                    ),
                    const SizedBox(width: 48), // Balance for centering
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Amount to', style: AppTextStyles.bodyMedium.copyWith(color: textColor)),
                      const SizedBox(height: 8),
                      
                      // Huge Amount Input
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: TextFormField(
                          controller: _amountCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: AppTextStyles.heading1.copyWith(
                            color: textColor,
                            fontSize: 22,
                            fontWeight: FontWeight.w500,
                            letterSpacing: -1,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: '0.00',
                            hintStyle: AppTextStyles.heading1.copyWith(
                              color: hintColor.withOpacity(0.3),
                              fontSize: 22,
                              fontWeight: FontWeight.w500,
                              letterSpacing: -1,
                            ),
                          ),
                          validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Bill Name
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderColor, width: 2),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Bill name', style: AppTextStyles.bodySmall.copyWith(color: hintColor, fontSize: 12)),
                            TextFormField(
                              controller: _titleCtrl,
                              style: AppTextStyles.bodyMedium.copyWith(color: textColor, fontSize: 16),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.only(top: 4, bottom: 4),
                              ),
                              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Frequency Row
                      _buildSettingsRow(
                        context: context,
                        label: 'Frequency',
                        value: _isRecurring ? 'Monthly' : 'One-time',
                        onTap: () {
                          setState(() => _isRecurring = !_isRecurring);
                        },
                        textColor: textColor,
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Select Period Row
                      _buildSettingsRow(
                        context: context,
                        label: 'Select Period',
                        value: '${DateFormat('yyyy-MM-dd').format(_startDate)} - ${DateFormat('yyyy-MM-dd').format(_endDate)}',
                        onTap: () async {
                          final result = await _showPeriodPicker(context, cardColor, textColor, isDark);
                          if (result != null) {
                            setState(() {
                              _startDate = result['start']!;
                              _endDate = result['end']!;
                            });
                          }
                        },
                        textColor: textColor,
                      ),
                      
                      const SizedBox(height: 48),
                      
                      // Buttons
                      ElevatedButton(
                        onPressed: _isSaving ? null : _saveBill,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? const Color(0xFFD4D4DB) : AppColors.primary, // Light grey matching design for dark mode
                          foregroundColor: isDark ? Colors.black87 : Colors.white,
                          minimumSize: const Size(double.infinity, 60),
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: _isSaving
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Save', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                      
                      if (isEditing) ...[
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _isDeleting ? null : _deleteBill,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.expenseRed, // Red matching design
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 60),
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: _isDeleting
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Delete upcoming bill', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ],
                      
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsRow({
    required BuildContext context,
    required String label,
    required String value,
    required VoidCallback onTap,
    required Color textColor,
    bool isValueHighlighted = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final highlightBg = isDark ? const Color(0xFFF1F5CD) : AppColors.primary.withOpacity(0.15);
    final highlightText = isDark ? Colors.black87 : AppColors.primary;
    final arrowColor = isDark ? Colors.white54 : context.appColors.textSecondary.withOpacity(0.5);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodyMedium.copyWith(color: textColor, fontSize: 16)),
          const SizedBox(width: 16),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isValueHighlighted)
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: highlightBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        value,
                        style: TextStyle(color: highlightText, fontSize: 14, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: Text(
                      value,
                      style: AppTextStyles.bodyMedium.copyWith(color: textColor, fontSize: 14), // Smaller text
                      textAlign: TextAlign.right,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                const SizedBox(width: 12),
                Icon(Icons.arrow_forward_ios_rounded, color: arrowColor, size: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<Map<String, DateTime>?> _showPeriodPicker(BuildContext context, Color bgColor, Color textColor, bool isDark) {
    DateTime tempStart = _startDate;
    DateTime tempEnd = _endDate;
    bool pickingStart = true;
    
    return showModalBottomSheet<Map<String, DateTime>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: bgColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final activeColor = isDark ? Colors.white : AppColors.primary;
            final inactiveColor = isDark ? Colors.white24 : Colors.black12;
            
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 40, height: 4, decoration: BoxDecoration(color: inactiveColor, borderRadius: BorderRadius.circular(2))),
                    const SizedBox(height: 16),
                    Text('Choose Period', style: AppTextStyles.heading2.copyWith(color: textColor, fontSize: 16)),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setModalState(() => pickingStart = true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                              decoration: BoxDecoration(
                                color: bgColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: pickingStart ? activeColor : inactiveColor, width: 2),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Start date', style: AppTextStyles.bodySmall.copyWith(color: textColor.withOpacity(0.7))),
                                  const SizedBox(height: 4),
                                  Text(DateFormat('yyyy-MM-dd').format(tempStart), style: AppTextStyles.bodyMedium.copyWith(color: textColor)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text('-', style: AppTextStyles.heading2.copyWith(color: textColor)),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setModalState(() => pickingStart = false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                              decoration: BoxDecoration(
                                color: bgColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: !pickingStart ? activeColor : inactiveColor, width: 2),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('End date', style: AppTextStyles.bodySmall.copyWith(color: textColor.withOpacity(0.7))),
                                  const SizedBox(height: 4),
                                  Text(DateFormat('yyyy-MM-dd').format(tempEnd), style: AppTextStyles.bodyMedium.copyWith(color: textColor)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Theme(
                      data: isDark ? ThemeData.dark().copyWith(
                        colorScheme: ColorScheme.dark(primary: AppColors.primary, onPrimary: Colors.white, surface: bgColor, onSurface: textColor),
                      ) : ThemeData.light().copyWith(
                        colorScheme: ColorScheme.light(primary: AppColors.primary, onPrimary: Colors.white, surface: bgColor, onSurface: textColor),
                      ),
                      child: CalendarDatePicker(
                        initialDate: pickingStart ? tempStart : tempEnd,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                        onDateChanged: (date) {
                          setModalState(() {
                            if (pickingStart) {
                              tempStart = date;
                              if (tempStart.isAfter(tempEnd)) tempEnd = tempStart;
                            } else {
                              tempEnd = date;
                              if (tempEnd.isBefore(tempStart)) tempStart = tempEnd;
                            }
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, {'start': tempStart, 'end': tempEnd}),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Save', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
