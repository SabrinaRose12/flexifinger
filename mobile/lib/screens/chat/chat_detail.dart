// lib/screens/chat/chat_detail.dart
import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class ChatDetail extends StatefulWidget {
  final int conversationId;
  final String participantName;
  final String userType;
  final int participantId;

  const ChatDetail({
    super.key,
    required this.conversationId,
    required this.participantName,
    required this.userType,
    required this.participantId,
  });

  @override
  State<ChatDetail> createState() => _ChatDetailState();
}

class _ChatDetailState extends State<ChatDetail> {
  List<dynamic> messages = [];
  final TextEditingController _messageController = TextEditingController();
  bool isLoading = true;
  bool isSending = false;
  final ScrollController _scrollController = ScrollController();
  int _currentConversationId = 0;

  @override
  void initState() {
    super.initState();
    print('🔍 CHAT DETAIL INITIALIZED');
    print('🔍 conversationId: ${widget.conversationId}');
    print('🔍 participantName: ${widget.participantName}');
    print('🔍 participantId: ${widget.participantId}');

    _currentConversationId = widget.conversationId;
    _fetchMessages();
    if (_currentConversationId > 0) {
      _markMessagesAsRead();
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _markMessagesAsRead() async {
    if (_currentConversationId == 0) return;

    try {
      final endpoint = widget.userType == 'patient'
          ? '/patient/mark_read.php'
          : '/therapist/mark_read.php';

      await ApiService.post(endpoint, {
        'conversation_id': _currentConversationId,
      });

      print('✅ Messages marked as read');
    } catch (e) {
      print('❌ Error marking messages as read: $e');
    }
  }

  Future<void> _fetchMessages() async {
    if (_currentConversationId == 0) {
      setState(() => isLoading = false);
      return;
    }

    setState(() => isLoading = true);
    try {
      final endpoint = widget.userType == 'patient'
          ? '/patient/get_messages.php?conversation_id=$_currentConversationId'
          : '/therapist/get_messages.php?conversation_id=$_currentConversationId';

      final response = await ApiService.get(endpoint);
      print('📥 Fetch messages response: $response');

      if (response['success'] == true) {
        setState(() {
          messages = response['data']['messages'] ?? [];
          isLoading = false;
        });
        _scrollToBottom();
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
      print('❌ Error fetching messages: $e');
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || isSending) return;

    _messageController.clear();
    setState(() => isSending = true);

    final tempMessage = {
      'message': message,
      'sender_type': widget.userType,
      'created_at': DateTime.now().toIso8601String(),
      'is_temp': true,
    };

    setState(() {
      messages.add(tempMessage);
    });
    _scrollToBottom();

    try {
      final endpoint = widget.userType == 'patient'
          ? '/patient/send_message.php'
          : '/therapist/send_message.php';

      Map<String, dynamic> body;
      if (widget.userType == 'patient') {
        body = {
          'therapist_id': widget.participantId.toString(),
          'message': message,
        };
      } else {
        body = {
          'patient_id': widget.participantId.toString(),
          'message': message,
          'conversation_id': _currentConversationId,
        };
      }

      print('📤 Sending message: $body');
      final response = await ApiService.post(endpoint, body);
      print('📤 Response: $response');

      if (response['success'] == true) {
        final newConversationId = response['data']['conversation_id'];
        if (_currentConversationId == 0 && newConversationId != null) {
          setState(() {
            _currentConversationId = newConversationId;
          });
        }
        await _fetchMessages();
      } else {
        setState(() {
          messages.removeWhere((msg) => msg['is_temp'] == true);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Failed to send message')),
        );
      }
    } catch (e) {
      setState(() {
        messages.removeWhere((msg) => msg['is_temp'] == true);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Network error. Please try again.')),
      );
    } finally {
      setState(() => isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: isLoading
                ? _buildLoadingState()
                : messages.isEmpty
                ? _buildEmptyState()
                : _buildMessageList(),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFF35A8E7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.participantName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1D1B4B),
                ),
              ),
              const Text(
                'Online',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1D1B4B)),
        onPressed: () {
          if (_currentConversationId > 0) {
            _markMessagesAsRead().then((_) {
              Navigator.pop(context, true);
            });
          } else {
            Navigator.pop(context, true);
          }
        },
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final msg = messages[messages.length - 1 - index];
        final isMe = msg['sender_type'] == widget.userType;
        final isTemp = msg['is_temp'] == true;
        return _buildMessageBubble(
          message: msg['message'],
          isMe: isMe,
          time: msg['created_at'],
          isTemp: isTemp,
        );
      },
    );
  }

  Widget _buildMessageBubble({
    required String message,
    required bool isMe,
    required String time,
    bool isTemp = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) _buildAvatar(),
          if (!isMe) const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: isMe
                        ? const LinearGradient(
                      colors: [Color(0xFF6C63FF), Color(0xFF8B5CF6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                        : null,
                    color: isMe ? null : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(4),
                      bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        message,
                        style: TextStyle(
                          color: isMe ? Colors.white : const Color(0xFF1D1B4B),
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isTemp)
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                              ),
                            ),
                          if (isTemp) const SizedBox(width: 6),
                          Text(
                            _formatTime(time),
                            style: TextStyle(
                              color: isMe ? Colors.white70 : Colors.grey.shade500,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (isMe && !isTemp)
                            const Icon(
                              Icons.done_all,
                              size: 14,
                              color: Colors.white70,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF35A8E7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.person, color: Colors.white, size: 20),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C63FF)),
          ),
          SizedBox(height: 16),
          Text(
            'Loading messages...',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFF35A8E7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.chat_bubble_outline, size: 40, color: Colors.white),
          ),
          const SizedBox(height: 24),
          const Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1D1B4B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start the conversation with ${widget.participantName}',
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: TextField(
                  controller: _messageController,
                  style: const TextStyle(fontSize: 15),
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF8B5CF6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6C63FF).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: isSending
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Icon(Icons.send, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(String datetime) {
    try {
      final date = DateTime.parse(datetime);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final msgDate = DateTime(date.year, date.month, date.day);

      if (msgDate == today) {
        return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      } else if (msgDate == today.subtract(const Duration(days: 1))) {
        return 'Yesterday';
      } else {
        return '${date.day}/${date.month}';
      }
    } catch (e) {
      return '';
    }
  }
}