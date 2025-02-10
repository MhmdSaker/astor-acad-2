import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../config/api_config.dart';
import '../services/voice_chat_speech_service.dart';
import 'dart:async';

class VoiceChatScreen extends StatefulWidget {
  const VoiceChatScreen({super.key});

  @override
  State<VoiceChatScreen> createState() => _VoiceChatScreenState();
}

class _VoiceChatScreenState extends State<VoiceChatScreen> {
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  late GenerativeModel _model;
  late ChatSession _chat;
  final VoiceChatSpeechService _speechService = VoiceChatSpeechService();
  bool _isListening = false;
  bool _isProcessing = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    _model = GenerativeModel(
      model: 'gemini-pro',
      apiKey: ApiConfig.apiKey,
    );
    _chat = _model.startChat();

    setState(() {
      _messages.add(
        ChatMessage(
          text:
              "مرحباً! I'm Linguini, your language learning companion. Just start speaking to practice with me!",
          isUser: false,
          senderName: "Linguini",
        ),
      );
    });

    await _speechService.initialize();
    setState(() => _isInitialized = true);

    // Automatically start listening after initialization
    _startListening();
  }

  Future<void> _startListening() async {
    if (_isProcessing || !_isInitialized) return;

    // Ensure clean state before starting
    await _speechService.stopListening();

    setState(() {
      _isListening = true;
      _messages.add(ChatMessage(
        text: "Listening...",
        isUser: true,
        senderName: "You",
        isVoiceMessage: true,
        isListening: true,
      ));
    });
    _scrollToBottom();

    try {
      String lastRecognizedText = '';
      Timer? silenceTimer;

      await _speechService.startListening(
        onTextRecognized: (text) async {
          if (!_isProcessing && text.isNotEmpty) {
            setState(() {
              _messages.last = ChatMessage(
                text: text,
                isUser: true,
                senderName: "You",
                isVoiceMessage: true,
              );
            });
            _scrollToBottom();
            lastRecognizedText = text;

            // Use shorter silence detection
            silenceTimer?.cancel();
            silenceTimer = Timer(const Duration(seconds: 1), () async {
              if (lastRecognizedText.isNotEmpty) {
                await _handleMessage(lastRecognizedText);
              }
            });
          }
        },
        onSilence: () async {
          silenceTimer?.cancel();
          if (lastRecognizedText.isNotEmpty) {
            await _handleMessage(lastRecognizedText);
          } else {
            // Restart listening immediately if no text was recognized
            _startListening();
          }
        },
        silenceThreshold: const Duration(seconds: 1),
      );
    } catch (e) {
      debugPrint('Voice input error: $e');
      if (mounted) {
        _startListening();
      }
    }
  }

  Future<void> _handleMessage(String message) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _isListening = false;
      _messages.add(ChatMessage(
        text: "",
        isUser: false,
        senderName: "Linguini",
        isTyping: true,
      ));
    });
    _scrollToBottom();

    try {
      final prompt =
          '''You are Linguini, a friendly AI tutor for language learners. Always respond in the user's language (Arabic/English), keeping answers concise (1-4 lines). Correct mistakes gently, provide simple explanations, practical examples, and mini-exercises (e.g., 'Try repeating:', 'Translate this:'). Focus on vocabulary, grammar, and pronunciation. Use encouraging phrases like 'Great effort!' or 'Let's practice together!' to motivate learners. Stay patient, clear, and adapt to their proficiency level.

User message: $message''';

      final response = await _chat.sendMessage(Content.text(prompt));
      final aiMessage = response.text ?? 'Sorry, I couldn\'t understand that.';

      setState(() {
        _messages.removeLast();
        _messages.add(ChatMessage(
          text: aiMessage,
          isUser: false,
          senderName: "Linguini",
        ));
      });
      _scrollToBottom();

      // Play audio response and ensure mic opens immediately after
      if (!_speechService.isSpeaking) {
        // First, ensure any previous listening session is stopped
        await _speechService.stopListening();

        // Play the AI response
        final audioCompleted = await _speechService.speak(aiMessage);

        if (audioCompleted && mounted) {
          // Reset states immediately
          setState(() {
            _isProcessing = false;
            _isListening = false;
          });

          // Start listening immediately without delay
          if (mounted) {
            _startListening();
          }
        }
      }
    } catch (e) {
      debugPrint('Error: $e');
      setState(() {
        _messages.removeLast();
        _messages.add(ChatMessage(
          text: "An error occurred. Please try again.",
          isUser: false,
          senderName: "Linguini",
        ));
        _isProcessing = false;
      });

      // Start listening immediately after error
      if (mounted) {
        _startListening();
      }
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F0EB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF5A1A),
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.only(left: 16),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
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
              'Voice Chat',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Continuous Voice Conversation',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF7F0EB),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
              ),
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) => _messages[index],
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
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isListening
                        ? const Color(0xFFFF5A1A)
                        : const Color(0xFFFF5A1A).withOpacity(0.1),
                  ),
                  child: Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    color:
                        _isListening ? Colors.white : const Color(0xFFFF5A1A),
                    size: 32,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _speechService.dispose();
    super.dispose();
  }
}

class ChatMessage extends StatelessWidget {
  final String text;
  final bool isUser;
  final String senderName;
  final bool isVoiceMessage;
  final bool isTyping;
  final bool isListening;

  const ChatMessage({
    super.key,
    required this.text,
    required this.isUser,
    required this.senderName,
    this.isVoiceMessage = false,
    this.isTyping = false,
    this.isListening = false,
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
                child: Row(
                  children: [
                    Text(
                      senderName,
                      style: const TextStyle(
                        color: Color(0xFFFF5A1A),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (isVoiceMessage) ...[
                      const SizedBox(width: 8),
                      Icon(
                        isUser ? Icons.mic : Icons.volume_up,
                        color: const Color(0xFFFF5A1A),
                        size: 16,
                      ),
                    ],
                  ],
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
            child: isTyping
                ? const TypingIndicator()
                : isListening
                    ? _buildListeningIndicator()
                    : _buildText(text),
          ),
        ],
      ),
    );
  }

  Widget _buildListeningIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.mic,
          color: Color(0xFFFF5A1A),
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          'Listening...',
          style: TextStyle(
            color: const Color(0xFFFF5A1A).withOpacity(0.8),
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  String _formatText(String text) {
    final boldPattern = RegExp(r'\*(.*?)\*');
    return text.replaceAllMapped(boldPattern, (match) {
      return '${match[1]}'.replaceAll('*', '');
    });
  }

  Widget _buildText(String text) {
    final List<TextSpan> spans = [];
    final boldPattern = RegExp(r'\*(.*?)\*');
    int currentIndex = 0;

    for (final match in boldPattern.allMatches(text)) {
      if (match.start > currentIndex) {
        spans.add(TextSpan(
          text: text.substring(currentIndex, match.start),
        ));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ));
      currentIndex = match.end;
    }

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
