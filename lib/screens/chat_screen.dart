import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

/*
  NOTE: To make this work, you need to run the following SQL in your Supabase SQL Editor:

  -- 1. Create messages table
  create table public.messages (
    id uuid default gen_random_uuid() primary key,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    sender_id uuid references auth.users not null,
    content text,
    image_url text,
    receiver_name text
  );

  -- 2. Enable Realtime for messages table
  alter publication supabase_realtime add table messages;

  -- 3. Create a Storage bucket named 'chat_media' in the Supabase Dashboard.
  -- Make sure to set the bucket to 'Public' or add appropriate RLS policies.
*/

class ChatScreen extends StatefulWidget {
  final String userName;
  const ChatScreen({super.key, required this.userName});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final SupabaseClient _supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  final List<Map<String, dynamic>> _localMessages = [];

  late final Stream<List<Map<String, dynamic>>> _messagesStream;

  @override
  void initState() {
    super.initState();
    // Listening to messages table for real-time updates
    _messagesStream = _supabase
        .from('messages')
        .stream(primaryKey: ['id']).order('created_at', ascending: false);
  }

  Future<void> _sendMessage({String? imageUrl}) async {
    final text = _messageController.text.trim();
    if (text.isEmpty && imageUrl == null) return;

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _supabase.from('messages').insert({
        'sender_id': userId,
        'content': text,
        'image_url': imageUrl,
        'receiver_name': widget.userName,
      });
      _messageController.clear();
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST205') {
        setState(() {
          _localMessages.insert(0, {
            'sender_id': userId,
            'content': text,
            'image_url': imageUrl,
            'created_at': DateTime.now().toIso8601String(),
          });
        });
        _messageController.clear();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Message saved for this session. Run the Supabase setup SQL to sync it.'),
          ));
        }
        return;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending message: $e')),
        );
      }
    }
  }

  Future<void> _pickAndUploadImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final file = File(image.path);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = 'chat_media/$fileName';

      await _supabase.storage.from('chat_media').upload(path, file);
      final imageUrl = _supabase.storage.from('chat_media').getPublicUrl(path);

      await _sendMessage(imageUrl: imageUrl);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.userName),
        backgroundColor: const Color(0xff075e54),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _messagesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final tableUnavailable = snapshot.hasError;
                final messages = [
                  ..._localMessages,
                  if (!tableUnavailable) ...(snapshot.data ?? []),
                ];
                if (messages.isEmpty) {
                  return _EmptyChat(tableUnavailable: tableUnavailable);
                }

                return Column(
                  children: [
                    if (tableUnavailable)
                      const MaterialBanner(
                        padding: EdgeInsets.all(12),
                        content: Text(
                            'Supabase messages table is not set up. Messages are local until setup is complete.'),
                        leading: Icon(Icons.cloud_off),
                        actions: [SizedBox.shrink()],
                      ),
                    Expanded(
                      child: ListView.builder(
                        reverse: true,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          final isMe = message['sender_id'] ==
                              _supabase.auth.currentUser?.id;
                          return Align(
                            alignment: isMe
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 300),
                              margin: const EdgeInsets.symmetric(
                                  vertical: 4, horizontal: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? const Color(0xffdcf8c6)
                                    : Colors.white,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(16),
                                  topRight: const Radius.circular(16),
                                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                                  bottomRight: Radius.circular(isMe ? 4 : 16),
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                      color: Color(0x12000000), blurRadius: 5)
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (message['image_url'] != null)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.network(
                                          message['image_url'],
                                          width: 240,
                                          height: 180,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  if (message['content'] != null &&
                                      message['content'].toString().isNotEmpty)
                                    Text(message['content'],
                                        style: const TextStyle(fontSize: 15)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          if (_isUploading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: LinearProgressIndicator(),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.photo),
                  onPressed: _isUploading ? null : _pickAndUploadImage,
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(24)),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () => _sendMessage(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyChat extends StatelessWidget {
  final bool tableUnavailable;

  const _EmptyChat({required this.tableUnavailable});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(tableUnavailable ? Icons.cloud_off : Icons.chat_bubble_outline,
                size: 52, color: Colors.teal),
            const SizedBox(height: 12),
            Text(
                tableUnavailable
                    ? 'Connect messages to Supabase'
                    : 'No messages yet',
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(
                tableUnavailable
                    ? 'You can still type a message now. Run supabase_setup.sql for realtime sync.'
                    : 'Start the conversation below.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}
