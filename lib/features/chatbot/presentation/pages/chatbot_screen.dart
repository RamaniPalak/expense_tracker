import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_tracker/core/constants/app_colors.dart';
import 'package:expense_tracker/core/constants/app_text_styles.dart';
import 'package:expense_tracker/features/chatbot/presentation/widgets/chat_bubble.dart';
import 'package:expense_tracker/features/chatbot/presentation/widgets/chat_input.dart';
import 'package:expense_tracker/features/chatbot/presentation/widgets/suggestion_chips.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final List<Map<String, dynamic>> _messages = [];
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    // Automatic greeting
    Timer(const Duration(milliseconds: 500), () {
      _addAiMessage('Hello! I am your AI Finance Assistant. How can I help you today?');
    });
  }

  void _addAiMessage(String text) {
    if (!mounted) return;
    _messages.add({
      'isUser': false,
      'text': text,
      'time': DateTime.now(),
    });
    _listKey.currentState?.insertItem(_messages.length - 1);
    _scrollToBottom();
  }

  void _addUserMessage(String text) {
    if (!mounted) return;
    _messages.add({
      'isUser': true,
      'text': text,
      'time': DateTime.now(),
    });
    _listKey.currentState?.insertItem(_messages.length - 1);
    _scrollToBottom();
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

    _addUserMessage(messageText);
    if (text == null) _controller.clear();

    setState(() {
      _isTyping = true;
    });

    // Simulate AI response
    Timer(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _isTyping = false;
        });
        _addAiMessage('I am currently in development mode. Soon I will be able to help you with your expenses and budget analysis!');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary.withAlpha(26), // 0.1 * 255
              AppColors.background,
            ],
          ),
        ),
        child: Column(
          children: [
            // Custom Header with Glassmorphism
            _buildHeader(context),

            // Message List
            Expanded(
              child: AnimatedList(
                key: _listKey,
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                initialItemCount: _messages.length,
                itemBuilder: (context, index, animation) {
                  final msg = _messages[index];
                  return SlideTransition(
                    position: animation.drive(
                      Tween<Offset>(
                        begin: const Offset(0, 0.2),
                        end: Offset.zero,
                      ).chain(CurveTween(curve: Curves.easeOutQuart)),
                    ),
                    child: FadeTransition(
                      opacity: animation,
                      child: ChatBubble(
                        isUser: msg['isUser'],
                        text: msg['text'],
                        time: msg['time'],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Typing Indicator
            if (_isTyping) _buildTypingIndicator(),

            // Suggestion Chips
            SuggestionChips(onChipTapped: _handleSend),

            const SizedBox(height: 12),

            // Input Area
            ChatInput(
              controller: _controller,
              onSend: () => _handleSend(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI Assistant',
                style: AppTextStyles.heading2.copyWith(color: Colors.white, fontSize: 18),
              ),
              Text(
                _isTyping ? 'Typing...' : 'Online',
                style: AppTextStyles.bodySmall.copyWith(color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(left: 24, bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(204),
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

class _TypingDotState extends State<_TypingDot> with SingleTickerProviderStateMixin {
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
