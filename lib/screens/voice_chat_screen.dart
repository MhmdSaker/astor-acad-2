import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../config/api_config.dart';
import '../services/speech_service.dart';
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
  final SpeechService _speechService = SpeechService();
  bool _isListening = false;
  bool _isProcessing = false;
  bool _isInitialized = false;
  bool _isSpeaking = false;

  // Update the navigation commands map to include both English and Arabic commands
  final Map<String, String> _navigationCommands = {
    // English commands
    'go to practice': '/practice',
    'open practice': '/practice',
    'take me to practice': '/practice',
    'start practice': '/practice',
    'let\'s practice': '/practice',
    'show me training': '/practice',
    'training': '/practice',

    // Arabic commands for practice
    'اذهب إلى التدريب': '/practice',
    'افتح التدريب': '/practice',
    'دعنا نتدرب': '/practice',
    'ابدأ التدريب': '/practice',

    // English game commands
    'go to games': '/games',
    'open games': '/games',
    'let\'s play games': '/games',
    'show me games': '/games',
    'play games': '/games',

    // Arabic game commands
    'اذهب إلى الألعاب': '/games',
    'افتح الألعاب': '/games',
    'دعنا نلعب': '/games',

    // English chat commands
    'go to chat': '/chat',
    'open chat': '/chat',
    'start chat': '/chat',
    'let\'s chat': '/chat',

    // Arabic chat commands
    'افتح المحادثة': '/chat',
    'دعنا نتحدث': '/chat',

    // English profile commands
    'go to profile': '/profile',
    'open profile': '/profile',
    'show my profile': '/profile',
    'view profile': '/profile',

    // Arabic profile commands
    'افتح الملف الشخصي': '/profile',
    'اظهر ملفي': '/profile',

    // Navigation commands in both languages
    'go back': 'back',
    'return': 'back',
    'previous screen': 'back',
    'رجوع': 'back',
    'عودة': 'back',
  };

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
              "مرحباً! Hello! I'm Linguini, your bilingual language learning companion. You can speak in Arabic or English, and I'll respond accordingly!",
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
    await _speechService.stop();

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

      await _speechService.listen(
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
            // Don't restart listening here as it may interfere with the speech
            setState(() => _isListening = false);
          }
        },
      );
    } catch (e) {
      debugPrint('Voice input error: $e');
      if (mounted) {
        setState(() => _isListening = false);
      }
    }
  }

  // Add this method to handle navigation
  void _handleNavigation(String command) {
    final normalizedCommand = command.toLowerCase().trim();

    for (var entry in _navigationCommands.entries) {
      if (normalizedCommand.contains(entry.key)) {
        if (entry.value == 'back') {
          Navigator.pop(context);
        } else {
          Navigator.pushNamed(context, entry.value);
        }
        break;
      }
    }
  }

  // Add this method to create suggestion buttons
  Widget _buildSuggestionButton(String text, String route) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ElevatedButton(
        onPressed: () {
          Navigator.pushNamed(context, route);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF5A1A),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Text(text),
      ),
    );
  }

  // Update the _handleMessage method to ensure mic reopens after speech
  Future<void> _handleMessage(String message) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _isListening = false;

      // Update the last message if it was from the user
      if (_messages.isNotEmpty && _messages.last.isUser) {
        _messages.last = ChatMessage(
          text: message,
          isUser: true,
          senderName: "You",
          isVoiceMessage: true,
        );
      } else {
        _messages.add(ChatMessage(
          text: message,
          isUser: true,
          senderName: "You",
          isVoiceMessage: true,
        ));
      }
    });
    _scrollToBottom();

    // Check for navigation commands first
    bool isNavigationCommand = false;
    for (var entry in _navigationCommands.entries) {
      if (message.toLowerCase().contains(entry.key.toLowerCase())) {
        isNavigationCommand = true;
        _handleNavigation(message);
        break;
      }
    }

    if (!isNavigationCommand) {
      try {
        final prompt =
            '''You are Linguini, an intelligent bilingual AI assistant.
Rules:
- If user speaks Arabic, respond in Arabic
- If user speaks English, respond in English
- Keep responses concise (2-4 lines)
- Detect user's proficiency level and adapt accordingly
- Correct language mistakes gently
- Provide examples when explaining
- Suggest relevant practice exercises
- Be encouraging and supportive
- If asked about app features, mention:
  * Practice section for structured learning
  * Games for fun practice
  * Chat for conversation practice
  * Profile to track progress

User message: $message''';

        final response = await _chat.sendMessage(Content.text(prompt));
        final responseText =
            response.text ?? "I didn't catch that. Could you please repeat?";

        setState(() {
          _messages.add(ChatMessage(
            text: responseText,
            isUser: false,
            senderName: "Linguini",
            suggestedActions: _getSuggestedActions(responseText),
          ));
        });
        _scrollToBottom();

        // Speak the response and ensure we wait for completion
        await _speakResponse(responseText);

        // Ensure we're not in a processing state before starting to listen
        if (mounted && !isNavigationCommand) {
          setState(() => _isProcessing = false);
          // Force a new listening session
          await _speechService.stop();
          await Future.delayed(const Duration(milliseconds: 100));
          await _startListening();
        }
      } catch (e) {
        debugPrint('Chat error: $e');
      }
    }

    if (mounted) {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  // Update the _speakResponse method to properly track speech completion
  Future<void> _speakResponse(String text) async {
    if (_speechService.isSpeaking) {
      await _speechService.stopSpeaking();
    }

    setState(() => _isSpeaking = true);

    try {
      final success = await _speechService.speakWithElevenLabs(text);
      if (!success) {
        debugPrint('Speech failed or was interrupted');
      }
    } finally {
      if (mounted) {
        setState(() => _isSpeaking = false);
      }
    }
  }

  // Add method to stop speaking
  Future<void> _stopSpeaking() async {
    if (_isSpeaking) {
      await _speechService.stopSpeaking();
      await _speechService.forceStopAudio();
      setState(() => _isSpeaking = false);
    }
  }

  // Add method to toggle listening
  Future<void> _toggleListening() async {
    if (_isListening) {
      await _speechService.stop();
      setState(() => _isListening = false);
    } else {
      _startListening();
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
              'Voice Chat Assistant',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
        actions: [
          if (_isSpeaking)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.stop_circle, color: Colors.white),
                onPressed: _stopSpeaking,
              ),
            ),
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
                PulsingMicButton(
                  isListening: _isListening,
                  onTap: _toggleListening,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to get suggested actions based on response
  List<Widget> _getSuggestedActions(String response) {
    final List<Widget> actions = [];
    final lowerResponse = response.toLowerCase();

    if (lowerResponse.contains('practice') || lowerResponse.contains('تدريب')) {
      actions.add(_buildSuggestionButton('Practice', '/practice'));
    }
    if (lowerResponse.contains('game') || lowerResponse.contains('لعب')) {
      actions.add(_buildSuggestionButton('Games', '/games'));
    }
    if (lowerResponse.contains('chat') || lowerResponse.contains('محادثة')) {
      actions.add(_buildSuggestionButton('Chat', '/chat'));
    }
    if (lowerResponse.contains('profile') ||
        lowerResponse.contains('ملف شخصي')) {
      actions.add(_buildSuggestionButton('Profile', '/profile'));
    }

    return actions;
  }

  // Add this method to handle clearing chat
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
              onPressed: () {
                setState(() {
                  _messages.clear();
                  _messages.add(ChatMessage(
                    text:
                        "مرحباً! I'm Linguini, your language learning companion. Just start speaking to practice with me!",
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
  final List<Widget> suggestedActions;

  const ChatMessage({
    super.key,
    required this.text,
    required this.isUser,
    required this.senderName,
    this.isVoiceMessage = false,
    this.isTyping = false,
    this.isListening = false,
    this.suggestedActions = const [],
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
          if (suggestedActions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: suggestedActions,
                ),
              ),
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

class PulsingMicButton extends StatefulWidget {
  final bool isListening;
  final VoidCallback onTap;

  const PulsingMicButton({
    super.key,
    required this.isListening,
    required this.onTap,
  });

  @override
  State<PulsingMicButton> createState() => _PulsingMicButtonState();
}

class _PulsingMicButtonState extends State<PulsingMicButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    if (widget.isListening) {
      _animationController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(PulsingMicButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isListening != oldWidget.isListening) {
      if (widget.isListening) {
        _animationController.repeat(reverse: true);
      } else {
        _animationController.stop();
        _animationController.reset();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: widget.isListening ? _scaleAnimation.value : 1.0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.isListening
                    ? const Color(0xFFFF5A1A)
                    : const Color(0xFFFF5A1A).withOpacity(0.1),
                boxShadow: widget.isListening
                    ? [
                        BoxShadow(
                          color: const Color(0xFFFF5A1A).withOpacity(0.3),
                          blurRadius: 24 * _scaleAnimation.value,
                          spreadRadius: 4 * _scaleAnimation.value,
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                widget.isListening ? Icons.mic : Icons.mic_none,
                color:
                    widget.isListening ? Colors.white : const Color(0xFFFF5A1A),
                size: 32,
              ),
            ),
          );
        },
      ),
    );
  }
}
