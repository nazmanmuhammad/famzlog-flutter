import 'package:flutter/material.dart';

OverlayEntry? _currentSnackBarOverlay;

void showModernSnackBar(
  BuildContext context, {
  required String title,
  required String message,
  required bool success,
}) {
  // Remove any existing overlay
  _currentSnackBarOverlay?.remove();
  _currentSnackBarOverlay = null;

  final color = success ? const Color(0xFF00A86B) : const Color(0xFFE53935);
  final icon = success ? Icons.check_circle_rounded : Icons.error_rounded;

  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) {
      final topPadding = MediaQuery.of(context).padding.top;
      return Positioned(
        top: topPadding + 12,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: _TopSnackBarWidget(
            title: title,
            message: message,
            color: color,
            icon: icon,
            onDismiss: () {
              entry.remove();
              if (_currentSnackBarOverlay == entry) {
                _currentSnackBarOverlay = null;
              }
            },
          ),
        ),
      );
    },
  );

  _currentSnackBarOverlay = entry;
  Overlay.of(context).insert(entry);

  // Auto-dismiss after 3 seconds
  Future.delayed(const Duration(seconds: 3), () {
    if (_currentSnackBarOverlay == entry) {
      entry.remove();
      _currentSnackBarOverlay = null;
    }
  });
}

class _TopSnackBarWidget extends StatefulWidget {
  final String title;
  final String message;
  final Color color;
  final IconData icon;
  final VoidCallback onDismiss;

  const _TopSnackBarWidget({
    required this.title,
    required this.message,
    required this.color,
    required this.icon,
    required this.onDismiss,
  });

  @override
  State<_TopSnackBarWidget> createState() => _TopSnackBarWidgetState();
}

class _TopSnackBarWidgetState extends State<_TopSnackBarWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(_controller);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: GestureDetector(
          onVerticalDragEnd: (details) {
            if (details.primaryVelocity != null && details.primaryVelocity! < 0) {
              widget.onDismiss();
            }
          },
          onTap: widget.onDismiss,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.color.withOpacity(0.12),
                  ),
                  child: Icon(widget.icon, color: widget.color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.message,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.close, size: 18, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
