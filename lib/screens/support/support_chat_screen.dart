import 'package:flutter/material.dart';
import 'package:sendbird_chat_sdk/sendbird_chat_sdk.dart';
import '../../core/api/api_endpoints.dart';
import '../../utils/app_colors.dart';

class SupportChatScreen extends StatefulWidget {
  final String channelUrl;
  final String ticketId;
  final String sendbirdUserId;
  final String sessionToken;
  final String issueLabel;
  final String? orderLabel;

  const SupportChatScreen({
    super.key,
    required this.channelUrl,
    required this.ticketId,
    required this.sendbirdUserId,
    required this.sessionToken,
    required this.issueLabel,
    this.orderLabel,
  });

  @override
  State<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends State<SupportChatScreen> {
  static const _handlerId = 'support_chat_handler';

  final _scrollCtrl = ScrollController();
  final _textCtrl   = TextEditingController();
  final _focusNode  = FocusNode();

  GroupChannel?       _channel;
  List<BaseMessage>   _messages   = [];
  bool                _connecting = true;
  bool                _sending    = false;
  String?             _error;

  @override
  void initState() {
    super.initState();
    _connect();
  }

  @override
  void dispose() {
    SendbirdChat.removeChannelHandler(_handlerId);
    _scrollCtrl.dispose();
    _textCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    try {
      await SendbirdChat.init(appId: ApiEndpoints.sendbirdAppId);
      await SendbirdChat.connect(
        widget.sendbirdUserId,
        accessToken: widget.sessionToken,
      );

      final channel = await GroupChannel.getChannel(widget.channelUrl);
      await channel.markAsRead();

      final params = MessageListParams()
        ..previousResultSize = 50
        ..inclusive          = true;
      final msgs = await channel.getMessagesByTimestamp(
        DateTime.now().millisecondsSinceEpoch,
        params,
      );

      SendbirdChat.addChannelHandler(
        _handlerId,
        _SupportChannelHandler(
          onMessageReceived: (ch, msg) {
            if (ch.channelUrl == widget.channelUrl && mounted) {
              setState(() => _messages = [..._messages, msg]);
              _scrollToBottom();
            }
          },
        ),
      );

      if (mounted) {
        setState(() {
          _channel    = channel;
          _messages   = msgs.whereType<BaseMessage>().toList();
          _connecting = false;
        });
        _scrollToBottom(jump: true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _connecting = false;
          _error      = 'Could not connect.\nPlease check your connection and retry.';
        });
      }
    }
  }

  Future<void> _send() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty || _channel == null || _sending) return;

    _textCtrl.clear();
    setState(() => _sending = true);

    _channel!.sendUserMessage(
      UserMessageCreateParams(message: text),
      handler: (msg, error) {
        if (!mounted) return;
        if (error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Failed to send message',
                  style: TextStyle(color: AppColors.white, fontSize: 13)),
              backgroundColor: AppColors.surface2,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: Colors.white24)),
              margin: const EdgeInsets.all(16),
            ),
          );
        } else {
          setState(() => _messages = [..._messages, msg]);
          _scrollToBottom();
        }
        setState(() => _sending = false);
      },
    );
  }

  void _scrollToBottom({bool jump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        if (jump) {
          _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
        } else {
          _scrollCtrl.animateTo(
            _scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOut,
          );
        }
      }
    });
  }

  // ─────────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final subtitle = widget.orderLabel != null
        ? '${widget.issueLabel}  ·  ${widget.orderLabel}'
        : widget.issueLabel;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: AppColors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Support Team',
              style: TextStyle(
                  color:      AppColors.white,
                  fontSize:   15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.3),
            ),
            const SizedBox(height: 1),
            Row(
              children: [
                Container(
                  width: 6, height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _connecting
                        ? AppColors.greyDark
                        : AppColors.green,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  _connecting ? 'Connecting…' : 'Online',
                  style: const TextStyle(
                      color: AppColors.grey, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded,
                color: AppColors.grey, size: 20),
            onPressed: _showTicketInfo,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.divider),
        ),
      ),
      body: Column(
        children: [
          // ── Issue context strip ──────────────────────────────────────────
          _IssueStrip(subtitle: subtitle, ticketId: widget.ticketId),

          // ── Messages ────────────────────────────────────────────────────
          Expanded(child: _buildBody()),

          // ── Composer ────────────────────────────────────────────────────
          if (!_connecting && _error == null)
            _Composer(
              controller: _textCtrl,
              focusNode:  _focusNode,
              sending:    _sending,
              onSend:     _send,
            ),
        ],
      ),
    );
  }

  // ─── Message list / states ─────────────────────────────────────────────────

  Widget _buildBody() {
    if (_connecting) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 22, height: 22,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.white),
            ),
            SizedBox(height: 14),
            Text('Connecting…',
                style: TextStyle(color: AppColors.grey, fontSize: 13)),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded,
                  color: AppColors.greyDark, size: 44),
              const SizedBox(height: 14),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppColors.grey, fontSize: 13, height: 1.6)),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  setState(() { _connecting = true; _error = null; });
                  _connect();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 28, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('Retry',
                      style: TextStyle(
                          color:      AppColors.bg,
                          fontSize:   13,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_messages.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.support_agent_rounded,
                color: AppColors.greyDark, size: 48),
            SizedBox(height: 16),
            Text('Support Team',
                style: TextStyle(
                    color:      AppColors.white,
                    fontSize:   15,
                    fontWeight: FontWeight.w600)),
            SizedBox(height: 6),
            Text('An agent will respond shortly.\nType your message below.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppColors.grey, fontSize: 13, height: 1.6)),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      itemCount: _messages.length,
      itemBuilder: (_, i) {
        final msg          = _messages[i];
        final isMe         = msg.sender?.userId == widget.sendbirdUserId;
        final showDivider  = i == 0 ||
            !_sameDay(_messages[i - 1].createdAt, msg.createdAt);

        return Column(
          children: [
            if (showDivider) _DateDivider(ts: msg.createdAt),
            _MessageBubble(
              message: msg,
              isMe:    isMe,
            ),
          ],
        );
      },
    );
  }

  bool _sameDay(int ts1, int ts2) {
    final d1 = DateTime.fromMillisecondsSinceEpoch(ts1);
    final d2 = DateTime.fromMillisecondsSinceEpoch(ts2);
    return d1.year == d2.year &&
           d1.month == d2.month &&
           d1.day == d2.day;
  }

  void _showTicketInfo() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36, height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const Text('Ticket Info',
                style: TextStyle(
                    color:      AppColors.white,
                    fontSize:   16,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            Container(height: 1, color: AppColors.divider),
            const SizedBox(height: 16),
            _InfoRow(label: 'Issue',     value: widget.issueLabel),
            if (widget.orderLabel != null)
              _InfoRow(label: 'Order',   value: widget.orderLabel!),
            _InfoRow(
              label: 'Ticket ID',
              value: widget.ticketId.length > 20
                  ? '…${widget.ticketId.substring(widget.ticketId.length - 16)}'
                  : widget.ticketId,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ─── Issue strip ──────────────────────────────────────────────────────────────

class _IssueStrip extends StatelessWidget {
  final String subtitle;
  final String ticketId;
  const _IssueStrip({required this.subtitle, required this.ticketId});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.confirmation_number_outlined,
              color: AppColors.greyDark, size: 13),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              subtitle,
              style: const TextStyle(color: AppColors.grey, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.surface2,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              '#${ticketId.length > 10 ? ticketId.substring(ticketId.length - 10).toUpperCase() : ticketId.toUpperCase()}',
              style: const TextStyle(
                  color: AppColors.greyDark, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Date divider ─────────────────────────────────────────────────────────────

class _DateDivider extends StatelessWidget {
  final int ts;
  const _DateDivider({required this.ts});

  @override
  Widget build(BuildContext context) {
    final dt  = DateTime.fromMillisecondsSinceEpoch(ts).toLocal();
    final now = DateTime.now();
    final isToday = dt.year == now.year &&
                    dt.month == now.month &&
                    dt.day == now.day;
    final label = isToday
        ? 'Today'
        : '${dt.day} ${_month(dt.month)}${dt.year != now.year ? '  ${dt.year}' : ''}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          const Expanded(child: Divider(color: AppColors.divider)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label,
              style: const TextStyle(
                  color:        AppColors.greyDark,
                  fontSize:     11,
                  fontWeight:   FontWeight.w500,
                  letterSpacing: 0.4),
            ),
          ),
          const Expanded(child: Divider(color: AppColors.divider)),
        ],
      ),
    );
  }

  String _month(int m) => const [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][m];
}

// ─── Message bubble ───────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final BaseMessage message;
  final bool        isMe;
  const _MessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final text = message is UserMessage
        ? (message as UserMessage).message
        : message is AdminMessage
            ? (message as AdminMessage).message
            : '';

    final time = _formatTime(message.createdAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Agent avatar
          if (!isMe)
            Container(
              width:  30,
              height: 30,
              margin: const EdgeInsets.only(right: 8, bottom: 2),
              decoration: BoxDecoration(
                color:  AppColors.surface2,
                shape:  BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(Icons.support_agent_rounded,
                  color: AppColors.grey, size: 15),
            ),

          // Bubble
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.72),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                // "my" bubble: white bg (matches edit_profile filled buttons)
                // agent bubble: surface card (matches payment/profile cards)
                color: isMe ? AppColors.white : AppColors.surface,
                borderRadius: BorderRadius.only(
                  topLeft:     const Radius.circular(16),
                  topRight:    const Radius.circular(16),
                  bottomLeft:  Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                border: isMe
                    ? null
                    : Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Sender name for agent messages
                  if (!isMe &&
                      (message.sender?.nickname.isNotEmpty ?? false))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        message.sender!.nickname,
                        style: const TextStyle(
                            color:      AppColors.grey,
                            fontSize:   11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2),
                      ),
                    ),
                  Text(
                    text,
                    style: TextStyle(
                        color:    isMe ? AppColors.bg : AppColors.white,
                        fontSize: 14,
                        height:   1.45),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    time,
                    style: TextStyle(
                        color: isMe
                            ? AppColors.bg.withOpacity(0.45)
                            : AppColors.greyDark,
                        fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int ms) {
    final dt = DateTime.fromMillisecondsSinceEpoch(ms).toLocal();
    final h  = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m  = dt.minute.toString().padLeft(2, '0');
    return '$h:$m ${dt.hour >= 12 ? 'PM' : 'AM'}';
  }
}

// ─── Message composer ─────────────────────────────────────────────────────────

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode             focusNode;
  final bool                  sending;
  final VoidCallback          onSend;

  const _Composer({
    required this.controller,
    required this.focusNode,
    required this.sending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: EdgeInsets.only(
        left:   16,
        right:  16,
        top:    10,
        bottom: MediaQuery.of(context).padding.bottom + 10,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Text input — matches edit_profile _Field style exactly
          Expanded(
            child: TextField(
              controller:            controller,
              focusNode:             focusNode,
              maxLines:              4,
              minLines:              1,
              textCapitalization:    TextCapitalization.sentences,
              style: const TextStyle(
                  color: AppColors.white, fontSize: 14),
              cursorColor: AppColors.white,
              decoration: InputDecoration(
                hintText:  'Type a message…',
                hintStyle: const TextStyle(
                    color: AppColors.greyDark, fontSize: 14),
                filled:      true,
                fillColor:   AppColors.surface2,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: AppColors.border)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: AppColors.border)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: AppColors.white, width: 1.5)),
              ),
              onSubmitted: (_) => onSend(),
            ),
          ),

          const SizedBox(width: 10),

          // Send button — white filled circle (matches app "Save" pill style)
          GestureDetector(
            onTap: sending ? null : onSend,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width:  44,
              height: 44,
              decoration: BoxDecoration(
                color:  sending
                    ? AppColors.surface2
                    : AppColors.white,
                shape:  BoxShape.circle,
                border: Border.all(
                    color: sending
                        ? AppColors.border
                        : AppColors.white),
              ),
              child: sending
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.grey),
                    )
                  : const Icon(Icons.arrow_upward_rounded,
                      color: AppColors.bg, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Channel handler ──────────────────────────────────────────────────────────

class _SupportChannelHandler extends GroupChannelHandler {
  final void Function(BaseChannel, BaseMessage) _onMessage;

  _SupportChannelHandler({
    required void Function(BaseChannel, BaseMessage) onMessageReceived,
  }) : _onMessage = onMessageReceived;

  @override
  void onMessageReceived(BaseChannel channel, BaseMessage message) {
    _onMessage(channel, message);
  }
}

// ─── Info row (ticket info sheet) ─────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: const TextStyle(
                  color:        AppColors.grey,
                  fontSize:     11,
                  fontWeight:   FontWeight.w500,
                  letterSpacing: 0.4),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                  color: AppColors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
