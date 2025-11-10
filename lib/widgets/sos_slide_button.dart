import 'package:flutter/material.dart';

/// SOS Slide Button Widget
///
/// A custom slide-to-send button for emergency SOS feature.
/// User must slide the button to the right to trigger SOS.
class SOSSlideButton extends StatefulWidget {
  final VoidCallback onSlideComplete;
  final bool isLoading;

  const SOSSlideButton({
    super.key,
    required this.onSlideComplete,
    this.isLoading = false,
  });

  @override
  State<SOSSlideButton> createState() => _SOSSlideButtonState();
}

class _SOSSlideButtonState extends State<SOSSlideButton>
    with SingleTickerProviderStateMixin {
  double _dragPosition = 0.0;
  bool _isDragging = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Create pulse animation for the button
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details, double maxDrag) {
    setState(() {
      _dragPosition = (_dragPosition + details.delta.dx).clamp(0.0, maxDrag);
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details, double maxDrag) {
    setState(() {
      _isDragging = false;
    });

    // If dragged more than 80% of the way, trigger the action
    if (_dragPosition > maxDrag * 0.8) {
      widget.onSlideComplete();
      // Keep the button at the end position
      setState(() {
        _dragPosition = maxDrag;
      });
    } else {
      // Reset position with animation
      setState(() {
        _dragPosition = 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const double buttonHeight = 70.0;
    const double buttonPadding = 4.0;
    const double thumbSize = buttonHeight - (buttonPadding * 2);

    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxDrag = constraints.maxWidth - thumbSize - (buttonPadding * 2);

        return Container(
          height: buttonHeight,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF3B30), Color(0xFFFF6B60)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(35),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF3B30).withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background text
              AnimatedOpacity(
                opacity: _dragPosition < maxDrag * 0.5 ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.arrow_forward,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.isLoading ? 'Sending SOS...' : 'Slide to send SOS',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // Success text when slid
              AnimatedOpacity(
                opacity: _dragPosition >= maxDrag * 0.8 ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: const Text(
                  'SOS Terkirim!',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),

              // Draggable thumb
              AnimatedPositioned(
                duration: _isDragging
                    ? Duration.zero
                    : const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                left: _dragPosition + buttonPadding,
                child: GestureDetector(
                  onHorizontalDragStart: (_) {
                    if (!widget.isLoading) {
                      setState(() {
                        _isDragging = true;
                      });
                    }
                  },
                  onHorizontalDragUpdate: (details) {
                    if (!widget.isLoading) {
                      _onHorizontalDragUpdate(details, maxDrag);
                    }
                  },
                  onHorizontalDragEnd: (details) {
                    if (!widget.isLoading) {
                      _onHorizontalDragEnd(details, maxDrag);
                    }
                  },
                  child: ScaleTransition(
                    scale: _pulseAnimation,
                    child: Container(
                      width: thumbSize,
                      height: thumbSize,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: widget.isLoading
                          ? const Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFFFF3B30),
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.warning_rounded,
                              color: Color(0xFFFF3B30),
                              size: 32,
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
