import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_tracker/core/constants/app_colors.dart';
import 'package:expense_tracker/core/constants/app_text_styles.dart';
import 'package:expense_tracker/core/constants/app_strings.dart';
import 'package:expense_tracker/features/chatbot/presentation/widgets/chat_bubble.dart';
import 'package:expense_tracker/features/chatbot/presentation/widgets/chat_input.dart';
import 'package:expense_tracker/features/chatbot/presentation/widgets/suggestion_chips.dart';
import 'package:expense_tracker/features/chatbot/presentation/bloc/chatbot_bloc.dart';
import 'package:expense_tracker/features/chatbot/presentation/bloc/chatbot_event.dart';
import 'package:expense_tracker/features/chatbot/presentation/bloc/chatbot_state.dart';
import 'package:expense_tracker/core/di/injection_container.dart';

import 'package:expense_tracker/core/theme/dynamic_colors.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final ChatbotBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = sl<ChatbotBloc>()..add(LoadHistoryEvent());
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleSend([String? text]) {
    final messageText = text ?? _controller.text.trim();
    if (messageText.isEmpty) return;

    _bloc.add(SendMessageEvent(messageText));
    if (text == null) _controller.clear();
    _scrollToBottom();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        backgroundColor: c.background,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.primary.withAlpha(26),
                c.background,
              ],
            ),
          ),
          child: BlocConsumer<ChatbotBloc, ChatbotState>(
            listener: (context, state) {
              if (state.status == ChatStatus.success ||
                  state.status == ChatStatus.loading) {
                _scrollToBottom();
              }
              if (state.status == ChatStatus.limitReached) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(AppStrings.freeLimitReached),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
              if (state.status == ChatStatus.failure) {
                log("Chatbot error:${state.errorMessage}");
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text(state.errorMessage ?? AppStrings.errorGeneric),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            builder: (context, state) {
              return Column(
                children: [
                  _buildHeader(context, state.status == ChatStatus.loading,
                      state.messageCount),
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 20),
                      itemCount: state.messages.length +
                          (state.messages.isEmpty ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (state.messages.isEmpty) {
                          return ChatBubble(
                            isUser: false,
                            text:
                                'Hello! I am your AI Finance Assistant. How can I help you today?',
                            time: DateTime.now(),
                          );
                        }
                        final msg = state.messages[index];
                        return ChatBubble(
                          isUser: msg.isUser,
                          text: msg.text,
                          time: msg.time,
                        );
                      },
                    ),
                  ),
                  if (state.status == ChatStatus.loading)
                    _buildTypingIndicator(),
                  if (state.status == ChatStatus.limitReached)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withAlpha(51),
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: Colors.orange.withAlpha(127)),
                        ),
                        child: Text(
                          AppStrings.freeLimitReached,
                          style: AppTextStyles.bodySmall
                              .copyWith(color: Colors.orange.shade800),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  if (state.status != ChatStatus.limitReached)
                    SuggestionChips(onChipTapped: _handleSend),
                  const SizedBox(height: 12),
                  ChatInput(
                    controller: _controller,
                    onSend: state.status == ChatStatus.limitReached
                      ? null
                      : () => _handleSend(),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isTyping, int count) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        bottom: 20,
        left: 16,
        right: 16,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(127),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          Stack(
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white24,
                child: Icon(Icons.smart_toy, color: Colors.white),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Assistant',
                  style: AppTextStyles.heading2
                      .copyWith(color: Colors.white, fontSize: 18),
                ),
                Text(
                  isTyping ? 'Typing...' : 'Online',
                  style:
                      AppTextStyles.bodySmall.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${5 - count} free left',
              style: AppTextStyles.bodySmall
                  .copyWith(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    final c = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(left: 24, bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _TypingDot(delay: 0),
              SizedBox(width: 4),
              _TypingDot(delay: 200),
              SizedBox(width: 4),
              _TypingDot(delay: 400),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypingDot extends StatefulWidget {
  final int delay;
  const _TypingDot({required this.delay});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animation = Tween<double>(begin: -5, end: 5).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    Timer(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _animController.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _animation.value),
          child: Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}
