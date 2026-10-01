import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat/models/message.dart';
import 'package:flutter_chat/models/profile.dart';
import 'package:flutter_chat/utils/constants.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart';
import 'package:url_launcher/url_launcher.dart';

const _attachmentsBucket = 'attachments';
const _maxAttachmentBytes = 10 * 1024 * 1024;

/// Page to chat with someone.
///
/// Displays chat bubbles as a ListView and TextField to enter new chat.
class const ChatPage({super.key}) extends StatefulWidget {
  static Route<void> route() {
    return MaterialPageRoute(builder: (context) => const ChatPage());
  }

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late final Stream<List<Message>> _messagesStream;
  final Map<String, Profile> _profileCache = {};

  @override
  void initState() {
    final myUserId = supabase.auth.currentUser!.id;
    _messagesStream = supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at')
        .map(
          (maps) => maps
              .map((map) => Message.fromMap(map: map, myUserId: myUserId))
              .toList(),
        );
    super.initState();
  }

  Future<void> _loadProfileCache(String profileId) async {
    if (_profileCache[profileId] != null) {
      return;
    }
    final data = await supabase
        .from('profiles')
        .select()
        .eq('id', profileId)
        .single();
    final profile = Profile.fromMap(data);
    if (!mounted) return;
    setState(() {
      _profileCache[profileId] = profile;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () => supabase.auth.signOut(),
          ),
        ],
      ),
      body: StreamBuilder<List<Message>>(
        stream: _messagesStream,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final messages = snapshot.data!;
            return Column(
              children: [
                Expanded(
                  child: messages.isEmpty
                      ? const Center(
                          child: Text('Start your conversation now :)'),
                        )
                      : ListView.builder(
                          reverse: true,
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final message = messages[index];

                            /// I know it's not good to include code that is not related
                            /// to rendering the widget inside build method, but for
                            /// creating an app quick and dirty, it's fine 😂
                            _loadProfileCache(message.profileId);

                            return _ChatBubble(
                              message: message,
                              profile: _profileCache[message.profileId],
                            );
                          },
                        ),
                ),
                const _MessageBar(),
              ],
            );
          } else {
            return preloader;
          }
        },
      ),
    );
  }
}

/// Set of widget that contains TextField and Button to submit message
class const _MessageBar() extends StatefulWidget {
  @override
  State<_MessageBar> createState() => _MessageBarState();
}

class _MessageBarState extends State<_MessageBar> {
  final _textController = TextEditingController();
  var _isUploading = false;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.grey[200],
      child: SafeArea(
        child: Padding(
          padding: const .all(8),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Attach a file',
                icon: _isUploading
                    ? const SizedBox.square(dimension: 24, child: preloader)
                    : const Icon(Icons.attach_file),
                onPressed: _isUploading ? null : _sendAttachment,
              ),
              Expanded(
                child: TextFormField(
                  keyboardType: .text,
                  maxLines: null,
                  autofocus: true,
                  controller: _textController,
                  decoration: const InputDecoration(
                    hintText: 'Type a message',
                    border: .none,
                    focusedBorder: .none,
                    contentPadding: .all(8),
                  ),
                ),
              ),
              TextButton(
                onPressed: () => _submitMessage(),
                child: const Text('Send'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _submitMessage() async {
    final text = _textController.text;
    final myUserId = supabase.auth.currentUser!.id;
    if (text.isEmpty) {
      return;
    }
    _textController.clear();
    try {
      await supabase.from('messages').insert({
        'profile_id': myUserId,
        'content': text,
      });
    } on PostgrestException catch (error) {
      if (!mounted) return;
      context.showErrorSnackBar(message: error.message);
    } catch (_) {
      if (!mounted) return;
      context.showErrorSnackBar(message: unexpectedErrorMessage);
    }
  }

  Future<void> _sendAttachment() async {
    final file = await FilePicker.pickFile();
    if (file == null || !mounted) {
      return;
    }
    final length = file.lengthSync() ?? await file.length();
    if (length == null || length > _maxAttachmentBytes) {
      if (!mounted) return;
      context.showErrorSnackBar(message: 'Files can be at most 10 MiB.');
      return;
    }
    setState(() => _isUploading = true);
    final myUserId = supabase.auth.currentUser!.id;
    final extension = file.extension;
    final path = [
      '$myUserId/${DateTime.now().microsecondsSinceEpoch}',
      ?extension,
    ].join('.');
    final text = _textController.text;
    try {
      await supabase.storage
          .from(_attachmentsBucket)
          .uploadBinary(path, await file.readAsBytes());
      await supabase.from('messages').insert({
        'profile_id': myUserId,
        'content': text,
        'attachment_path': path,
        'attachment_name': file.name,
      });
      _textController.clear();
    } on StorageException catch (error) {
      if (!mounted) return;
      context.showErrorSnackBar(message: error.message);
    } on PostgrestException catch (error) {
      if (!mounted) return;
      context.showErrorSnackBar(message: error.message);
    } catch (_) {
      if (!mounted) return;
      context.showErrorSnackBar(message: unexpectedErrorMessage);
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }
}

class const _ChatBubble({
  required final Message message,
  required final Profile? profile,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final chatContents = <Widget>[
      if (!message.isMine)
        CircleAvatar(
          child: profile == null
              ? preloader
              : Text(profile!.username.substring(0, 2)),
        ),
      const SizedBox(width: 12),
      Flexible(
        child: Container(
          padding: const .symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: message.isMine
                ? Theme.of(context).primaryColor
                : Colors.grey[300],
            borderRadius: .circular(8),
          ),
          child: Column(
            crossAxisAlignment: .start,
            mainAxisSize: .min,
            spacing: 8,
            children: [
              if (message.attachmentPath != null) _Attachment(message: message),
              if (message.content.isNotEmpty) Text(message.content),
            ],
          ),
        ),
      ),
      const SizedBox(width: 12),
      Text(format(message.createdAt, locale: 'en_short')),
      const SizedBox(width: 60),
    ];
    return Padding(
      padding: const .symmetric(horizontal: 8, vertical: 18),
      child: Row(
        mainAxisAlignment: message.isMine ? .end : .start,
        children: message.isMine ? [...chatContents.reversed] : chatContents,
      ),
    );
  }
}

class const _Attachment({required final Message message})
    extends StatefulWidget {
  @override
  State<_Attachment> createState() => _AttachmentState();
}

class _AttachmentState extends State<_Attachment> {
  late final Future<String> _signedUrl = supabase.storage
      .from(_attachmentsBucket)
      .createSignedUrl(widget.message.attachmentPath!, 60 * 60);

  Future<void> _open() async {
    final opened = await launchUrl(
      Uri.parse(await _signedUrl),
      mode: .externalApplication,
    );
    if (!opened && mounted) {
      context.showErrorSnackBar(message: 'Could not open the file.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final message = widget.message;
    return InkWell(
      onTap: _open,
      child: message.hasImageAttachment
          ? FutureBuilder(
              future: _signedUrl,
              builder: (context, snapshot) => ClipRRect(
                borderRadius: .circular(4),
                child: SizedBox(
                  width: 200,
                  height: 200,
                  child: snapshot.hasData
                      ? Image.network(snapshot.data!, fit: .cover)
                      : preloader,
                ),
              ),
            )
          : Row(
              mainAxisSize: .min,
              spacing: 8,
              children: [
                const Icon(Icons.insert_drive_file_outlined),
                Flexible(child: Text(message.attachmentName ?? 'File')),
              ],
            ),
    );
  }
}
