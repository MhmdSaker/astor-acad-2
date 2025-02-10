import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../config/api_config.dart';
import 'voice_chat_screen.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  late GenerativeModel _model;
  late ChatSession _chat;
  bool _isTyping = false;
  bool _isProcessing = false;
  static const String _chatHistoryKey = 'chat_history';

  @override
  void initState() {
    super.initState();
    _initializeChat();
    _loadChatHistory();
  }

  void _initializeChat() {
    _model = GenerativeModel(
      model: 'gemini-pro',
      apiKey: ApiConfig.apiKey,
    );
    _chat = _model.startChat();

    setState(() {
      _messages.add(
        ChatMessage(
          text:
              "مرحباً! I'm Linguini, your language learning companion. How can I help you practice today?",
          isUser: false,
          senderName: "Linguini",
        ),
      );
    });
  }

  Future<void> _handleSubmitted(String text) async {
    if (text.trim().isEmpty) return;

    final userMessage = text;
    _messageController.clear();

    setState(() {
      _messages.add(ChatMessage(
        text: userMessage,
        isUser: true,
        senderName: "You",
      ));
      _messages.add(ChatMessage(
        text: "",
        isUser: false,
        senderName: "Linguini",
        isTyping: true,
      ));
      _isTyping = true;
    });

    await _saveChatHistory();
    _scrollToBottom();

    try {
      setState(() => _isProcessing = true);

      final prompt =
          '''You are Linguini, a friendly AI tutor for language learners. Always respond in the user's language (Arabic/English), keeping answers concise (1-4 lines). Correct mistakes gently, provide simple explanations, practical examples, and mini-exercises (e.g., 'Try repeating:', 'Translate this:'). Focus on vocabulary, grammar, and pronunciation. Use encouraging phrases like 'Great effort!' or 'Let's practice together!' to motivate learners. Stay patient, clear, and adapt to their proficiency level.

User message: $userMessage''';

      final response = await _chat.sendMessage(Content.text(prompt));
      final aiMessage = response.text ?? 'Sorry, I couldn\'t understand that.';

      setState(() {
        _isTyping = false;
        _isProcessing = false;
        _messages.removeLast();
        _messages.add(ChatMessage(
          text: aiMessage,
          isUser: false,
          senderName: "Linguini",
        ));
      });

      await _saveChatHistory();
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _isTyping = false;
        _isProcessing = false;
        _messages.removeLast();
        _messages.add(ChatMessage(
          text: "An error occurred. Please try again.",
          isUser: false,
          senderName: "Linguini",
        ));
      });
      await _saveChatHistory();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Widget _buildSendButton() {
    return Container(
      decoration: BoxDecoration(
        color: _isProcessing ? Colors.grey : const Color(0xFFFF5A1A),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: _isProcessing
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.send, color: Colors.white),
        onPressed: _isProcessing
            ? null
            : () => _handleSubmitted(_messageController.text),
      ),
    );
  }

  Widget _buildVoiceControls() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const VoiceChatScreen(),
              ),
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFF7F0EB),
            ),
            child: const Icon(
              Icons.mic_none,
              color: Color(0xFF141414),
              size: 24,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F0EB), // bgColor
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF5A1A),
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
              ),
            ),
            child: const Icon(
              Icons.arrow_back,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Astor Multiagent',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'AI Language Assistant',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.more_vert,
                color: Colors.white,
              ),
            ),
            offset: const Offset(0, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: Colors.white,
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_outline,
                      color: const Color(0xFFFF5A1A),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Clear Chat',
                      style: TextStyle(
                        color: const Color(0xFF141414),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            onSelected: (String value) {
              if (value == 'clear') {
                _showClearChatDialog(context);
              }
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF7F0EB), // bgColor for chat area
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
              ),
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length + 1,
                itemBuilder: (context, index) {
                  if (index < _messages.length) {
                    return _messages[index];
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFFF5A1A).withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            enabled: !_isProcessing,
                            style: const TextStyle(
                              color: Color(0xFF141414),
                              fontSize: 16,
                            ),
                            decoration: InputDecoration(
                              hintText:
                                  'Type your message or press the mic to speak...',
                              hintStyle: TextStyle(
                                color: const Color(0xFF141414).withOpacity(0.5),
                                fontSize: 16,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.all(16),
                            ),
                            onSubmitted:
                                _isProcessing ? null : _handleSubmitted,
                          ),
                        ),
                        _buildVoiceControls(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: _isProcessing
                          ? [Colors.grey, Colors.grey]
                          : [
                              const Color(0xFFFF5A1A),
                              const Color(0xFFFF5A1A).withOpacity(0.8),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: IconButton(
                      icon: _isProcessing
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.send, color: Colors.white),
                      onPressed: _isProcessing
                          ? null
                          : () => _handleSubmitted(_messageController.text),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showClearChatDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Clear Chat',
            style: TextStyle(
              color: Color(0xFF141414),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Are you sure you want to clear all messages?',
            style: TextStyle(
              color: Color(0xFF141414),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: const Color(0xFF141414).withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove(_chatHistoryKey);
                setState(() {
                  _messages.clear();
                  _messages.add(ChatMessage(
                    text:
                        "مرحباً! I'm Linguini, your language learning companion. How can I help you practice today?",
                    isUser: false,
                    senderName: "Linguini",
                  ));
                });
                Navigator.pop(context);
              },
              child: const Text(
                'Clear',
                style: TextStyle(
                  color: Color(0xFFFF5A1A),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final messagesJson = _messages
        .map((msg) => {
              'text': msg.text,
              'isUser': msg.isUser,
              'senderName': msg.senderName,
              'isTyping': msg.isTyping,
            })
        .toList();
    await prefs.setString(_chatHistoryKey, jsonEncode(messagesJson));
  }

  Future<void> _loadChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final chatHistoryJson = prefs.getString(_chatHistoryKey);

    if (chatHistoryJson != null) {
      final List<dynamic> messagesJson = jsonDecode(chatHistoryJson);
      setState(() {
        _messages.clear();
        _messages.addAll(
          messagesJson.map((msgJson) => ChatMessage(
                text: msgJson['text'],
                isUser: msgJson['isUser'],
                senderName: msgJson['senderName'],
                isTyping: msgJson['isTyping'] ?? false,
              )),
        );
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class ChatMessage extends StatelessWidget {
  final String text;
  final bool isUser;
  final String senderName;
  final bool isTyping;

  const ChatMessage({
    super.key,
    required this.text,
    required this.isUser,
    required this.senderName,
    this.isTyping = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5A1A).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  senderName,
                  style: const TextStyle(
                    color: Color(0xFFFF5A1A),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isUser ? const Color(0xFFFF5A1A) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF5A1A).withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
              border: !isUser
                  ? Border.all(
                      color: const Color(0xFFFF5A1A).withOpacity(0.3),
                      width: 2,
                    )
                  : null,
            ),
            child: isTyping ? const TypingIndicator() : _buildText(text),
          ),
        ],
      ),
    );
  }

  String _formatText(String text) {
    // Handle bold text between asterisks
    final boldPattern = RegExp(r'\*(.*?)\*');
    return text.replaceAllMapped(boldPattern, (match) {
      return '${match[1]}'.replaceAll('*', '');
    });
  }

  Widget _buildText(String text) {
    final List<TextSpan> spans = [];
    final boldPattern = RegExp(r'\*(.*?)\*');
    int currentIndex = 0;

    // Find all bold patterns
    for (final match in boldPattern.allMatches(text)) {
      // Add text before the bold part
      if (match.start > currentIndex) {
        spans.add(TextSpan(
          text: text.substring(currentIndex, match.start),
        ));
      }
      // Add the bold text
      spans.add(TextSpan(
        text: match.group(1),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ));
      currentIndex = match.end;
    }

    // Add any remaining text
    if (currentIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(currentIndex),
      ));
    }

    return RichText(
      text: TextSpan(
        style: TextStyle(
          color: isUser ? Colors.white : const Color(0xFF141414),
          fontSize: 16,
          height: 1.5,
        ),
        children: spans,
      ),
    );
  }
}

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _appearanceController;
  late Animation<double> _indicatorSpaceAnimation;
  late List<AnimationController> _dotControllers;
  final int _numDots = 3;
  final double _dotSize = 8;
  final double _dotSpacing = 4;

  @override
  void initState() {
    super.initState();
    _appearanceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _indicatorSpaceAnimation = CurvedAnimation(
      parent: _appearanceController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      reverseCurve: const Interval(0.0, 1.0, curve: Curves.easeOut),
    ).drive(Tween<double>(begin: 0.0, end: 1.0));

    _dotControllers = List<AnimationController>.generate(
      _numDots,
      (index) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      ),
    );

    // تشغيل الأنيميشن
    _appearanceController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      for (var i = 0; i < _numDots; i++) {
        Future.delayed(Duration(milliseconds: i * 200), () {
          if (mounted) {
            _dotControllers[i].repeat(reverse: true);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _appearanceController.dispose();
    for (var controller in _dotControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizeTransition(
            sizeFactor: _indicatorSpaceAnimation,
            axis: Axis.horizontal,
            child: Row(
              children: List<Widget>.generate(_numDots, (index) {
                return Padding(
                  padding: EdgeInsets.only(
                      right: index < _numDots - 1 ? _dotSpacing : 0),
                  child: AnimatedBuilder(
                    animation: _dotControllers[index],
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, -4 * _dotControllers[index].value),
                        child: Container(
                          width: _dotSize,
                          height: _dotSize,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF5A1A).withOpacity(0.7),
                            borderRadius: BorderRadius.circular(_dotSize / 2),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF5A1A).withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
