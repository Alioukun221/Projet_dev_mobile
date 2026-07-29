import 'package:flutter/material.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:spendwise/config/ai_config.dart';
import 'package:spendwise/constants/app_colors.dart';
import 'package:spendwise/services/finance_ai_service.dart';
import 'package:spendwise/theme/app_theme.dart';
import 'package:spendwise/utils/app_format.dart';

class AiFinancePage extends StatefulWidget {
  const AiFinancePage({super.key});

  @override
  State<AiFinancePage> createState() => _AiFinancePageState();
}

class _AiFinancePageState extends State<AiFinancePage> {
  final _service = FinanceAiService();
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_AiMessage> _messages = [
    const _AiMessage(
      role: _AiRole.assistant,
      text:
          'Pose-moi une question sur tes finances. Je peux resumer ta semaine, ton mois, tes categories de depenses, tes budgets ou tes transactions planifiees.',
    ),
  ];
  bool _isLoading = false;

  static const _suggestions = [
    'Resume ma semaine',
    'Resume mon mois',
    'Quelles sont mes plus grosses depenses ?',
    'Est-ce que je respecte mes budgets ?',
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send([String? preset]) async {
    final question = (preset ?? _controller.text).trim();
    if (question.isEmpty || _isLoading) return;

    _controller.clear();
    setState(() {
      _messages.add(_AiMessage(role: _AiRole.user, text: question));
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final answer = await _service.ask(
        question: question,
        currency: appCurrency(context, listen: false),
        localeName: appLocaleName(context),
      );
      if (!mounted) return;
      setState(() {
        _messages.add(_AiMessage(role: _AiRole.assistant, text: answer));
      });
    } on FinanceAiConfigurationException {
      if (!mounted) return;
      setState(() {
        _messages.add(
          const _AiMessage(
            role: _AiRole.assistant,
            text:
                'La cle IA n est pas configuree. Lance l app avec --dart-define=GROQ_API_KEY=ta_cle, ou definis GROQ_API_KEY avant les commandes make.',
          ),
        );
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          const _AiMessage(
            role: _AiRole.assistant,
            text:
                'Je n ai pas pu contacter le service IA. Verifie ta connexion et la configuration de la cle API.',
          ),
        );
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          icon:
              Icon(Icons.arrow_back_ios_rounded, color: context.appTextPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Assistant finances',
          style: TextStyle(
            color: context.appTextPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (!AiConfig.isConfigured) _buildConfigWarning(),
            _buildSuggestions(),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                itemCount: _messages.length + (_isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (_isLoading && index == _messages.length) {
                    return _buildTypingBubble();
                  }
                  return _buildMessageBubble(_messages[index]);
                },
              ),
            ),
            _buildInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigWarning() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF97316).withOpacity(0.25)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.key_rounded, color: Color(0xFFF97316), size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Cle IA absente. Definis GROQ_API_KEY via --dart-define ou variable d environnement avant de lancer l app.',
              style: TextStyle(
                color: Color(0xFF9A3412),
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestions() {
    return SizedBox(
      height: 46,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: _suggestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final suggestion = _suggestions[index];
          return ActionChip(
            avatar: const Icon(Icons.auto_awesome_rounded, size: 16),
            label: Text(suggestion),
            onPressed: _isLoading ? null : () => _send(suggestion),
            side: BorderSide(color: context.appBorderColor),
            backgroundColor: context.appCardColor,
            labelStyle: TextStyle(
              color: context.appTextPrimary,
              fontWeight: FontWeight.w600,
            ),
          );
        },
      ),
    );
  }

  Widget _buildMessageBubble(_AiMessage message) {
    final isUser = message.role == _AiRole.user;
    final bg = isUser ? AppTheme.primaryColor : context.appCardColor;
    final fg = isUser ? Colors.white : context.appTextPrimary;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.82,
        ),
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 6),
            bottomRight: Radius.circular(isUser ? 6 : 18),
          ),
          border: isUser ? null : Border.all(color: context.appBorderColor),
        ),
        child: isUser
            ? SelectableText(
                message.text,
                style: TextStyle(
                  color: fg,
                  fontSize: 14,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                ),
              )
            : GptMarkdown(
                message.text,
                style: TextStyle(
                  color: fg,
                  fontSize: 14,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
              ),
      ),
    );
  }

  Widget _buildTypingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: context.appCardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: context.appBorderColor),
        ),
        child: SizedBox(
          width: 42,
          child: LinearProgressIndicator(
            minHeight: 3,
            color: AppTheme.primaryColor,
            backgroundColor: AppTheme.primaryColor.withOpacity(0.12),
          ),
        ),
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: BoxDecoration(
        color: context.appBgColor,
        border: Border(top: BorderSide(color: context.appBorderColor)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.newline,
              style: TextStyle(color: context.appTextPrimary),
              decoration: InputDecoration(
                hintText: 'Pose une question sur tes finances...',
                hintStyle: TextStyle(color: context.appTextSecondary),
                filled: true,
                fillColor: context.appInputFill,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 48,
            height: 48,
            child: IconButton.filled(
              onPressed: _isLoading ? null : () => _send(),
              icon: const Icon(Icons.send_rounded),
              style: IconButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    context.appTextSecondary.withOpacity(0.2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _AiRole { user, assistant }

class _AiMessage {
  final _AiRole role;
  final String text;

  const _AiMessage({
    required this.role,
    required this.text,
  });
}
