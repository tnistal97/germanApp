import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../state/feed_state.dart';

class CreatePostScreen extends StatefulWidget {
  final VoidCallback? onPosted;

  const CreatePostScreen({
    super.key,
    this.onPosted,
  });

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _ctrl = TextEditingController();
  bool _sending = false;

  static const int _maxChars = 280;
  static const int _maxWords = 60;

  late final AnimationController _buttonController;
  late final Animation<double> _buttonScale;

  @override
  void initState() {
    super.initState();

    // ✅ Controller normal 0..1
    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    // ✅ Tween para escalar 0.96 → 1.02 con curva
    _buttonScale = Tween<double>(
      begin: 0.96,
      end: 1.02,
    ).animate(
      CurvedAnimation(
        parent: _buttonController,
        curve: Curves.easeOut,
      ),
    );

    _ctrl.addListener(() {
      setState(() {});
      if (_canPost) {
        _buttonController.forward();
      } else {
        _buttonController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  bool get _canPost {
    final text = _ctrl.text.trim();
    final charCount = text.length;
    final wordCount = _countWords(text);

    final remainingChars = _maxChars - charCount;
    final remainingWords = _maxWords - wordCount;

    final isOverLimit = remainingChars < 0 || remainingWords < 0;

    return text.isNotEmpty && !_sending && !isOverLimit;
  }

  int _countWords(String text) {
    if (text.trim().isEmpty) return 0;
    return text.trim().split(RegExp(r'\s+')).length;
  }

  Future<void> _submit() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending || !_canPost) return;

    setState(() => _sending = true);

    try {
      await context.read<FeedState>().addPost(text);
      _ctrl.clear();
      if (!mounted) return;

      _showSuccessAnimation();

      await Future.delayed(const Duration(milliseconds: 1500));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade400),
              const SizedBox(width: 8),
              const Text('Post published successfully!'),
            ],
          ),
          backgroundColor: Colors.green.shade800.withOpacity(0.9),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

      widget.onPosted?.call();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade400),
                const SizedBox(width: 8),
                const Text('Failed to publish post'),
              ],
            ),
            backgroundColor: Colors.red.shade800.withOpacity(0.9),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  void _showSuccessAnimation() {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      barrierDismissible: false,
      builder: (context) => const SuccessAnimationDialog(),
    );

    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final text = _ctrl.text;
    final charCount = text.length;
    final wordCount = _countWords(text);

    final remainingChars = _maxChars - charCount;
    final remainingWords = _maxWords - wordCount;

    final isOverLimit = remainingChars < 0 || remainingWords < 0;
    final isNearLimitChars = remainingChars <= 20 && remainingChars >= 0;
    final isNearLimitWords = remainingWords <= 10 && remainingWords >= 0;

    Color counterColor;
    if (isOverLimit) {
      counterColor = Colors.red.shade400;
    } else if (isNearLimitChars || isNearLimitWords) {
      counterColor = Colors.orange.shade400;
    } else {
      counterColor = Colors.green.shade400;
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF020617),
            Color(0xFF020617),
            Color(0xFF020B28),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'New Post',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Header con avatar + nombre
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF6366F1),
                            Color(0xFF22D3EE),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'You',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Public post',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Card principal con el campo de texto
              Expanded(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF020617).withOpacity(0.98),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: const Color(0xFF1E293B),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.45),
                              blurRadius: 24,
                              offset: const Offset(0, 16),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(18, 18, 18, 6),
                              child: Text(
                                "What's on your mind?",
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.white.withOpacity(0.6),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(18, 0, 18, 18),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  minHeight: 140,
                                  maxHeight: 260,
                                ),
                                child: Scrollbar(
                                  thumbVisibility: false,
                                  child: TextField(
                                    controller: _ctrl,
                                    maxLines: null,
                                    style:
                                        theme.textTheme.bodyLarge?.copyWith(
                                      color: Colors.white,
                                      height: 1.4,
                                    ),
                                    cursorColor: const Color(0xFF6366F1),
                                    decoration: const InputDecoration(
                                      isCollapsed: true,
                                      border: InputBorder.none,
                                      hintText: 'Write something...',
                                      hintStyle: TextStyle(
                                        color: Color(0xFF64748B),
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // Barra inferior: contador + botón
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    // Panel de contador
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: counterColor.withOpacity(0.6),
                          ),
                          gradient: LinearGradient(
                            colors: [
                              counterColor.withOpacity(0.08),
                              counterColor.withOpacity(0.02),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  isOverLimit
                                      ? Icons.error_outline
                                      : Icons.timer_outlined,
                                  size: 16,
                                  color: counterColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isOverLimit
                                      ? 'Limit exceeded'
                                      : 'You\'re good to go',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: counterColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Chars left: ${remainingChars.clamp(-999, 999)}   •   Words left: ${remainingWords.clamp(-999, 999)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$charCount / $_maxChars chars   •   $wordCount / $_maxWords words',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Botón de publicar con animación
                    ScaleTransition(
                      scale: _buttonScale,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF6366F1),
                              Color(0xFF22C1C3),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: _canPost
                              ? [
                                  BoxShadow(
                                    color:
                                        const Color(0xFF6366F1).withOpacity(0.6),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ]
                              : [],
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(999),
                          onTap: _canPost ? _submit : null,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            child: _sending
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(
                                        Icons.send_rounded,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        'Post',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SuccessAnimationDialog extends StatelessWidget {
  const SuccessAnimationDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.8, end: 1.0),
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutBack,
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: child,
          );
        },
        child: Container(
          width: 130,
          height: 130,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.85),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: Colors.greenAccent.withOpacity(0.4),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.7),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF22C55E),
                size: 42,
              ),
              SizedBox(height: 10),
              Text(
                'Posted!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
