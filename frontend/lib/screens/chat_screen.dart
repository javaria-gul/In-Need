import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../services/storage_service.dart';
import '../models/job_model.dart';
import '../utils/app_theme.dart';

class ChatScreen extends StatefulWidget {
  final int jobId;
  final int otherUserId;
  final String otherName;
  const ChatScreen(
      {super.key,
      required this.jobId,
      required this.otherUserId,
      required this.otherName});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _api = ApiService();
  final _msgCtrl = TextEditingController();
  final _scroll = ScrollController();
  List<ChatMessageModel> _msgs = [];
  bool _loading = true;
  bool _sending = false;
  int? _myId;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final uid = await StorageService.getUserId();
    _myId = int.tryParse(uid ?? '0');
    await _loadHistory();
    _listenSocket();
  }

  Future<void> _loadHistory() async {
    try {
      final raw = await _api.getChatMessages(widget.jobId);
      if (mounted) {
        setState(() {
          _msgs = raw.map((m) => ChatMessageModel.fromJson(m)).toList();
        });
      }
      SocketService().markRead(widget.jobId);
      _scrollToBottom();
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _listenSocket() {
    SocketService().on('message_received', (d) {
      if ((d['jobId'] as int?) == widget.jobId && mounted) {
        final msg = ChatMessageModel.fromJson(d);
        setState(() => _msgs.add(msg));
        _scrollToBottom();
        SocketService().markRead(widget.jobId);
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    _msgCtrl.clear();

    // Optimistic add
    final optimistic = ChatMessageModel(
      id: DateTime.now().millisecondsSinceEpoch,
      jobId: widget.jobId,
      senderId: _myId ?? 0,
      receiverId: widget.otherUserId,
      message: text,
      isRead: false,
      createdAt: DateTime.now(),
    );
    setState(() => _msgs.add(optimistic));
    _scrollToBottom();

    try {
      SocketService().sendMessage(
          jobId: widget.jobId, receiverId: widget.otherUserId, message: text);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    SocketService().off('message_received');
    _msgCtrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: kBg,
        appBar: AppBar(
          leading: const BackButton(color: kWhite),
          title: Row(children: [
            Container(
                width: 34,
                height: 34,
                decoration:
                    BoxDecoration(gradient: kBlueGrad, shape: BoxShape.circle),
                child: Center(
                    child: Text(widget.otherName[0].toUpperCase(),
                        style: const TextStyle(
                            color: kWhite,
                            fontWeight: FontWeight.w900,
                            fontSize: 14)))),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.otherName,
                  style: const TextStyle(
                      color: kWhite,
                      fontSize: 14,
                      fontWeight: FontWeight.w800)),
              const Text('Job Active',
                  style: TextStyle(
                      color: kTealGreen,
                      fontSize: 10,
                      fontWeight: FontWeight.w600)),
            ]),
          ]),
          actions: [
            IconButton(
              icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                      color: kWhite.withValues(alpha: 0.1),
                      shape: BoxShape.circle),
                  child:
                      const Icon(Icons.call_outlined, color: kWhite, size: 18)),
              onPressed: () =>
                  showSnack(context, '📞 Call feature coming soon!'),
              tooltip: 'Call',
            ),
          ],
        ),
        body: Column(children: [
          Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: kBlue))
                  : _msgs.isEmpty
                      ? _emptyChat()
                      : ListView.builder(
                          controller: _scroll,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          itemCount: _msgs.length,
                          itemBuilder: (_, i) => _bubble(_msgs[i]),
                        )),
          _inputBar(),
        ]),
      );

  Widget _bubble(ChatMessageModel msg) {
    final mine = msg.senderId == _myId;
    final time =
        '${msg.createdAt.hour.toString().padLeft(2, '0')}:${msg.createdAt.minute.toString().padLeft(2, '0')}';
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        child: Column(
            crossAxisAlignment:
                mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: mine ? kBlueGrad : null,
                  color: mine ? null : kWhite,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(mine ? 18 : 4),
                    bottomRight: Radius.circular(mine ? 4 : 18),
                  ),
                  boxShadow: kShadow,
                ),
                child: Text(msg.message,
                    style: TextStyle(
                        color: mine ? kWhite : kBlack,
                        fontSize: 14,
                        height: 1.4)),
              ),
              const SizedBox(height: 3),
              Text(time, style: const TextStyle(color: kGrey, fontSize: 10)),
            ]),
      ),
    );
  }

  Widget _inputBar() => Container(
        color: kWhite,
        padding: EdgeInsets.only(
            left: 16,
            right: 8,
            top: 10,
            bottom: MediaQuery.of(context).viewInsets.bottom + 12),
        child: Row(children: [
          Expanded(
              child: Container(
            decoration: BoxDecoration(
                color: kBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: kDivider)),
            child: TextField(
              controller: _msgCtrl,
              onSubmitted: (_) => _send(),
              style: const TextStyle(fontSize: 14, color: kBlack),
              decoration: const InputDecoration(
                  hintText: 'Type a message…',
                  border: InputBorder.none,
                  filled: false,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
            ),
          )),
          const SizedBox(width: 8),
          GestureDetector(
              onTap: _send,
              child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                      gradient: kBlueGrad,
                      shape: BoxShape.circle,
                      boxShadow: kBlueShadow),
                  child:
                      const Icon(Icons.send_rounded, color: kWhite, size: 20))),
        ]),
      );

  Widget _emptyChat() => Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
            width: 80,
            height: 80,
            decoration:
                BoxDecoration(gradient: kBlueGrad, shape: BoxShape.circle),
            child: const Icon(Icons.chat_bubble_outline_rounded,
                color: kWhite, size: 36)),
        const SizedBox(height: 16),
        const Text('Start the Conversation',
            style: TextStyle(
                fontWeight: FontWeight.w800, fontSize: 17, color: kBlack)),
        const SizedBox(height: 8),
        const Text('Say hello and coordinate the work!',
            style: TextStyle(color: kGrey, fontSize: 13)),
      ]));
}
