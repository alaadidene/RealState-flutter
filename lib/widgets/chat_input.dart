import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/appwrite_service.dart';
import '../models/messaging_models.dart';

class ChatInput extends StatefulWidget {
  final String conversationId;
  final String currentUserId;
  final String receiverId;
  final VoidCallback? onMessageSent;
  final void Function(String)? onMessageStart;
  final void Function(bool)? onTyping;

  const ChatInput({
    required this.conversationId,
    required this.currentUserId,
    required this.receiverId,
    super.key,
    this.onMessageSent,
    this.onMessageStart,
    this.onTyping,
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final TextEditingController _controller = TextEditingController();
  final AppwriteService _appwrite = AppwriteService();
  final ImagePicker _imagePicker = ImagePicker();
  
  bool _sending = false;
  DateTime? _lastTypingNotification;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTyping(String text) {
    if (widget.onTyping == null) return;

    final now = DateTime.now();
    
    // Send typing indicator every 2 seconds
    if (_lastTypingNotification == null ||
        now.difference(_lastTypingNotification!) > const Duration(seconds: 2)) {
      widget.onTyping!(text.isNotEmpty);
      _lastTypingNotification = now;
    }

    // Stop typing indicator after 2 seconds of inactivity
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && _controller.text.isEmpty) {
        widget.onTyping!(false);
      }
    });
  }

  Future<void> _handleSendMessage() async {
    if (_controller.text.trim().isEmpty || _sending) return;

    final messageText = _controller.text.trim();
    setState(() {
      _controller.clear();
      _sending = true;
    });

    // Stop typing indicator
    widget.onTyping?.call(false);

    // Optimistic update
    widget.onMessageStart?.call(messageText);

    try {
      final message = MessageDocument(
        id: '',
        conversationId: widget.conversationId,
        senderId: widget.currentUserId,
        receiverId: widget.receiverId,
        content: messageText,
        contentType: 'text',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      final result = await _appwrite.sendMessage(message: message);

      if (result != null) {
        widget.onMessageSent?.call();
      } else {
        // Restore message on failure
        _controller.text = messageText;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to send message')),
          );
        }
      }
    } catch (error) {
      _controller.text = messageText;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${error.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  Future<void> _handleImagePick() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image == null) return;

      setState(() => _sending = true);

      try {
        // TODO: Implement image upload to Appwrite storage first
        // Then send message with imageUrl
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image upload not yet implemented')),
          );
        }
        return;
        
        /* Future implementation:
        final imageUrl = await _appwrite.uploadImage(image.path);
        final message = MessageDocument(
          id: '',
          conversationId: widget.conversationId,
          senderId: widget.currentUserId,
          receiverId: widget.receiverId,
          content: '📷 Image',
          contentType: 'image',
          imageUrl: imageUrl,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final result = await _appwrite.sendMessage(message: message);
        */
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error sending image: ${error.toString()}')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _sending = false);
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to access gallery')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Image button
          IconButton(
            onPressed: _sending ? null : _handleImagePick,
            icon: Icon(
              Icons.image,
              color: _sending ? Colors.grey : const Color(0xFF007AFF),
            ),
          ),
          const SizedBox(width: 8),

          // Input field
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F8F8),
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _controller,
                enabled: !_sending,
                onChanged: _handleTyping,
                maxLines: null,
                maxLength: 1000,
                decoration: const InputDecoration(
                  hintText: 'Type your message...',
                  border: InputBorder.none,
                  counterText: '',
                ),
                style: const TextStyle(fontSize: 16),
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Send button
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _controller.text.trim().isEmpty || _sending
                  ? Colors.grey
                  : const Color(0xFF007AFF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              onPressed: _controller.text.trim().isEmpty || _sending
                  ? null
                  : _handleSendMessage,
              icon: _sending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(
                      Icons.send,
                      size: 20,
                      color: Colors.white,
                    ),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }
}
