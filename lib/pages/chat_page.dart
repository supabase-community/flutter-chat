import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat/models/message.dart';
import 'package:flutter_chat/models/profile.dart';
import 'package:flutter_chat/utils/constants.dart';
import 'package:flutter_chat/utils/cover_resize_image.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart';
import 'package:url_launcher/url_launcher.dart';

const _attachmentsBucket = 'attachments';
const _maxAttachmentBytes = 10 * 1024 * 1024;
const _signedUrlLifetime = Duration(hours: 1);
const _imageSize = 200.0;

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
  static const _pageSize = 20;

  final Map<String, Message> _messages = {};
  final Map<String, Profile> _profiles = {};
  final Set<String> _requestedProfileIds = {};
  final Map<String, ({Future<String> url, DateTime expiresAt})> _signedUrls =
      {};

  /// The loaded messages, newest first.
  List<Message> _sortedMessages = [];

  /// The position of every message in [_sortedMessages], by message id.
  Map<String, int> _messageIndexes = {};
  final _scrollController = ScrollController();
  late final StreamSubscription<List<Message>> _subscription;
  late final String _myUserId;
  var _hasReceivedMessages = false;
  var _hasOlderMessages = true;
  var _isLoadingOlderMessages = false;
  var _hasOlderMessagesError = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _myUserId = supabase.auth.currentUser!.id;
    _scrollController.addListener(_loadOlderMessagesIfNeeded);
    _subscription = supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at')
        .limit(_pageSize)
        .map(
          (maps) => maps
              .map((map) => Message.fromMap(map: map, myUserId: _myUserId))
              .toList(),
        )
        .listen(_onLatestMessages, onError: _onError);
  }

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    _scrollController.dispose();
    super.dispose();
  }

  void _onLatestMessages(List<Message> messages) {
    // After a reconnect the latest page can skip past the loaded messages,
    // so start over from it instead of leaving a gap.
    final skipsLoadedMessages =
        messages.length == _pageSize &&
        !messages.any((message) => _messages.containsKey(message.id));
    setState(() {
      _error = null;
      if (!_hasReceivedMessages || skipsLoadedMessages) {
        _messages.clear();
        _sortedMessages = [];
        _hasOlderMessages = messages.length == _pageSize;
        _hasReceivedMessages = true;
      }
      _addMessages(messages);
    });
    _scheduleOlderMessagesCheck();
  }

  void _onError(Object error) {
    setState(() => _error = error);
  }

  void _addMessages(List<Message> messages) {
    for (final message in messages) {
      _messages[message.id] = message;
    }
    _sortedMessages = _messages.values.toList()
      ..sort(
        (a, b) => switch (b.createdAt.compareTo(a.createdAt)) {
          0 => b.id.compareTo(a.id),
          final order => order,
        },
      );
    _messageIndexes = {
      for (final (index, message) in _sortedMessages.indexed) message.id: index,
    };
    unawaited(_loadProfiles(messages));
  }

  /// Loads the page before the oldest loaded message once the list is
  /// scrolled close to its top, or when the loaded messages do not fill it.
  void _loadOlderMessagesIfNeeded() {
    if (!_scrollController.hasClients) {
      return;
    }
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      unawaited(_loadOlderMessages());
    }
  }

  void _scheduleOlderMessagesCheck() {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _loadOlderMessagesIfNeeded(),
    );
  }

  Future<void> _loadOlderMessages() async {
    if (_isLoadingOlderMessages ||
        _hasOlderMessagesError ||
        !_hasOlderMessages ||
        _messages.isEmpty) {
      return;
    }
    setState(() => _isLoadingOlderMessages = true);
    try {
      // Messages can share a timestamp, so the page continues with the ones at
      // the oldest loaded timestamp that are not loaded yet.
      final oldest = _sortedMessages.last.createdAt;
      final loadedAtOldest = _sortedMessages.reversed
          .takeWhile((message) => message.createdAt == oldest)
          .map((message) => message.id)
          .join(',');
      final createdAt = oldest.toUtc().toIso8601String();
      final data = await supabase
          .from('messages')
          .select()
          .or(
            'created_at.lt.$createdAt,'
            'and(created_at.eq.$createdAt,id.not.in.($loadedAtOldest))',
          )
          .order('created_at')
          .order('id')
          .limit(_pageSize);
      if (!mounted) return;
      setState(() {
        _addMessages([
          for (final map in data)
            Message.fromMap(map: map, myUserId: _myUserId),
        ]);
        _hasOlderMessages = data.length == _pageSize;
      });
      _scheduleOlderMessagesCheck();
    } catch (_) {
      if (!mounted) return;
      setState(() => _hasOlderMessagesError = true);
    } finally {
      if (mounted) {
        setState(() => _isLoadingOlderMessages = false);
      }
    }
  }

  void _retryOlderMessages() {
    setState(() => _hasOlderMessagesError = false);
    unawaited(_loadOlderMessages());
  }

  /// Fetches the profiles of the senders of [messages] that are not loaded
  /// or requested yet, in a single request.
  Future<void> _loadProfiles(List<Message> messages) async {
    final profileIds = {
      for (final message in messages) message.profileId,
    }.difference(_requestedProfileIds);
    if (profileIds.isEmpty) {
      return;
    }
    _requestedProfileIds.addAll(profileIds);
    try {
      final data = await supabase
          .from('profiles')
          .select()
          .inFilter('id', profileIds.toList());
      if (!mounted) return;
      setState(() {
        for (final map in data) {
          final profile = Profile.fromMap(map);
          _profiles[profile.id] = profile;
        }
      });
    } catch (_) {
      _requestedProfileIds.removeAll(profileIds);
    }
  }

  /// A signed URL for the attachment at [path], reused until shortly before
  /// it expires so that the image cache can hit.
  Future<String> _signedUrlFor(String path) {
    final cached = _signedUrls[path];
    if (cached != null && DateTime.now().isBefore(cached.expiresAt)) {
      return cached.url;
    }
    final url = supabase.storage
        .from(_attachmentsBucket)
        .createSignedUrl(path, _signedUrlLifetime.inSeconds);
    _signedUrls[path] = (
      url: url,
      expiresAt: DateTime.now().add(
        _signedUrlLifetime - const Duration(minutes: 5),
      ),
    );
    url.then<void>((_) {}, onError: (_) => _signedUrls.remove(path)).ignore();
    return url;
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
      body: switch ((_hasReceivedMessages, _error)) {
        (_, final error?) => Center(
          child: Padding(
            padding: formPadding,
            child: Text(
              'Could not load messages.\n$error',
              textAlign: .center,
            ),
          ),
        ),
        (false, _) => preloader,
        (true, _) => Column(
          children: [
            Expanded(
              child: _messages.isEmpty
                  ? const Center(
                      child: Text('Start your conversation now :)'),
                    )
                  : _MessageList(
                      messages: _sortedMessages,
                      messageIndexes: _messageIndexes,
                      profiles: _profiles,
                      hasOlderMessages: _hasOlderMessages,
                      onRetryOlderMessages: _hasOlderMessagesError
                          ? _retryOlderMessages
                          : null,
                      scrollController: _scrollController,
                      signedUrlFor: _signedUrlFor,
                    ),
            ),
            const _MessageBar(),
          ],
        ),
      },
    );
  }
}

class const _MessageList({
  required final List<Message> messages,
  required final Map<String, int> messageIndexes,
  required final Map<String, Profile> profiles,
  required final bool hasOlderMessages,
  required final VoidCallback? onRetryOlderMessages,
  required final ScrollController scrollController,
  required final Future<String> Function(String path) signedUrlFor,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      reverse: true,
      itemCount: messages.length + (hasOlderMessages ? 1 : 0),
      // Keeps the state of every bubble with its message when new messages
      // shift the positions in the list.
      findChildIndexCallback: (key) =>
          key is ValueKey<String> ? messageIndexes[key.value] : null,
      itemBuilder: (context, index) {
        if (index == messages.length) {
          return Padding(
            padding: const .all(16),
            child: onRetryOlderMessages == null
                ? preloader
                : Center(
                    child: TextButton.icon(
                      onPressed: onRetryOlderMessages,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Could not load older messages, retry'),
                    ),
                  ),
          );
        }
        final message = messages[index];
        final attachmentPath = message.attachmentPath;
        return _ChatBubble(
          key: ValueKey(message.id),
          message: message,
          profile: profiles[message.profileId],
          attachmentUrl: attachmentPath == null
              ? null
              : signedUrlFor(attachmentPath),
        );
      },
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
  super.key,
  required final Message message,
  required final Profile? profile,
  required final Future<String>? attachmentUrl,
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
              if (attachmentUrl case final url?)
                _Attachment(message: message, url: url),
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

class const _Attachment({
  required final Message message,
  required final Future<String> url,
}) extends StatelessWidget {
  Future<void> _open(BuildContext context) async {
    final opened = await url
        .then((url) => launchUrl(Uri.parse(url), mode: .externalApplication))
        .catchError((Object _) => false);
    if (!opened && context.mounted) {
      context.showErrorSnackBar(message: 'Could not open the file.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final pixelSize = (_imageSize * MediaQuery.devicePixelRatioOf(context))
        .round();
    // The ink is painted on this transparent material, above the colored
    // bubble instead of underneath it.
    return Material(
      type: .transparency,
      child: InkWell(
        onTap: () => _open(context),
        child: message.hasImageAttachment
            ? FutureBuilder(
                future: url,
                builder: (context, snapshot) => ClipRRect(
                  borderRadius: .circular(4),
                  child: SizedBox.square(
                    dimension: _imageSize,
                    child: switch (snapshot) {
                      AsyncSnapshot(hasData: true, :final data?) => Image(
                        image: CoverResizeImage(
                          NetworkImage(data),
                          width: pixelSize,
                          height: pixelSize,
                        ),
                        fit: .cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const _BrokenImage(),
                      ),
                      AsyncSnapshot(hasError: true) => const _BrokenImage(),
                      _ => preloader,
                    },
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
      ),
    );
  }
}

class const _BrokenImage() extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(child: Icon(Icons.broken_image_outlined, size: 48));
  }
}
