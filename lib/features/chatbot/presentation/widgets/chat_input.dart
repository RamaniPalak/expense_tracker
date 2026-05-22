import 'package:flutter/material.dart';
import 'package:expense_tracker/core/constants/app_colors.dart';
import 'package:expense_tracker/core/theme/dynamic_colors.dart';

class ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback? onSend;

  const ChatInput({
    super.key,
    required this.controller,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = onSend != null;
    final c = context.appColors;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isEnabled ? c.card : c.inputFill.withAlpha(200),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: c.shadow.withAlpha(20),
            blurRadius: 15,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: isEnabled ? c.inputFill : c.inputFill.withAlpha(120),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: c.border),
                ),
                child: TextField(
                  controller: controller,
                  enabled: isEnabled,
                  style: TextStyle(color: c.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Type your message...',
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: c.textSecondary, fontSize: 14),
                  ),
                  onSubmitted: isEnabled ? (_) => onSend!() : null,
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: onSend,
              child: Opacity(
                opacity: isEnabled ? 1.0 : 0.5,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: isEnabled 
                      ? const LinearGradient(
                          colors: [AppColors.secondary, AppColors.primary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : const LinearGradient(
                          colors: [Colors.grey, Colors.blueGrey],
                        ),
                    shape: BoxShape.circle,
                    boxShadow: isEnabled ? [
                      const BoxShadow(
                        color: AppColors.primary,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ] : [],
                  ),
                  child: const Icon(Icons.send_rounded, color: Colors.white, size: 24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
