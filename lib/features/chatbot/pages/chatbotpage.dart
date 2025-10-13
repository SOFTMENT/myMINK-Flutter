import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import 'package:mymink/core/constants/colors.dart';
import 'package:mymink/core/widgets/custom_app_bar.dart';
import 'package:mymink/core/widgets/chat_bubble.dart';
import 'package:mymink/core/widgets/dismiss_keyboard_ontap.dart';
import 'package:mymink/features/discussion/widgets/reply_input_bar.dart';

import 'package:mymink/features/onboarding/data/models/user_model.dart';
import 'package:mymink/core/services/chat_bot_service.dart';
import 'package:mymink/gen/assets.gen.dart';

class ChatBotPage extends StatefulWidget {
  const ChatBotPage({super.key});

  @override
  State<ChatBotPage> createState() => _ChatBotPageState();
}

class _ChatBotPageState extends State<ChatBotPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late final CollectionReference<Map<String, dynamic>> _messagesRef;
  bool _isLoading = false;
  String? lastAnimatedMessageId;

  @override
  void initState() {
    super.initState();
    final uid = UserModel.instance.uid!;
    _messagesRef = FirebaseFirestore.instance
        .collection('Chatbot')
        .doc(uid)
        .collection('messages');
  }

  Future<void> _sendMessage() async {
    final message = _controller.text.trim();
    if (message.isEmpty) return;

    // Add user message first
    await _messagesRef.add({
      'role': 'user',
      'content': message,
      'timestamp': FieldValue.serverTimestamp(),
    });

    _controller.clear();
    setState(() => _isLoading = true);

    try {
      final response = await ChatService.getChatResponse(message);

      final docRef = await _messagesRef.add({
        'role': 'assistant',
        'content': response.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      });

      setState(() {
        lastAnimatedMessageId = docRef.id;
        _isLoading = false;
      });

      _scrollToBottom();
    } catch (e) {
      await _messagesRef.add({
        'role': 'assistant',
        'content': 'Sorry, something went wrong. 😞',
        'timestamp': FieldValue.serverTimestamp(),
      });
      setState(() => _isLoading = false);
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0, // because reversed
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Widget _buildChatBubble(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final isUser = data['role'] == 'user';
    final content = data['content'] ?? '';
    final timestamp =
        (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
    final isAnimated = !isUser && doc.id == lastAnimatedMessageId;

    return ChatBubble(
      content: content,
      isUser: isUser,
      timestamp: timestamp,
      isAnimated: isAnimated,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: DismissKeyboardOnTap(
        child: Column(
          children: [
            CustomAppBar(
              leadingWidget: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadiusGeometry.circular(1000),
                    child: Assets.images.bot.image(width: 44, height: 44),
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  const Text(
                    'my MINK Chatbot',
                    style: const TextStyle(
                        color: Colors.black,
                        fontSize: 17,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              title: '',
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _messagesRef.orderBy('timestamp').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                        child: Text("Start the conversation 👋"));
                  }

                  final messages = snapshot.data!.docs;

                  _scrollToBottom();

                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.only(
                        top: 8, bottom: 0, left: 20, right: 20),
                    itemCount: messages.length,
                    itemBuilder: (_, index) {
                      return _buildChatBubble(
                          messages[messages.length - 1 - index]);
                    },
                  );
                },
              ),
            ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: SpinKitThreeBounce(
                  color: AppColors.primaryBlue,
                  size: 20,
                ),
              ),
            ReplyInputBar(
              replyController: _controller,
              postReply: _sendMessage,
              hint: 'Ask anything...',
            ),
          ],
        ),
      ),
    );
  }
}
