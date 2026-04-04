import 'package:flutter/material.dart';

import '../../../features/fan/fan_highlight_model.dart';

class HighlightCard extends StatefulWidget {
  const HighlightCard({
    super.key,
    required this.highlight,
    this.onTap,
  });

  final FanHighlightModel highlight;
  final VoidCallback? onTap;

  @override
  State<HighlightCard> createState() => _HighlightCardState();
}

class _HighlightCardState extends State<HighlightCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _hovered = true),
        onTapCancel: () => setState(() => _hovered = false),
        onTapUp: (_) => setState(() => _hovered = false),
        child: AnimatedScale(
          scale: _hovered ? 0.985 : 1,
          duration: const Duration(milliseconds: 160),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4DA1FF)
                      .withOpacity(_hovered ? 0.28 : 0.15),
                  blurRadius: _hovered ? 24 : 12,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.network(
                      widget.highlight.thumbnailUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: const Color(0xFF202742),
                          child: const Icon(
                            Icons.broken_image_outlined,
                            color: Color(0xFF8B98BF),
                          ),
                        );
                      },
                    ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            const Color(0x99000000),
                            const Color(0x22000000),
                            const Color(0xD9000000),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 10,
                    top: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xC2111426),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        widget.highlight.duration,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.highlight.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Text(
                              widget.highlight.league,
                              style: const TextStyle(
                                color: Color(0xFFB8C2E1),
                                fontSize: 11,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              widget.highlight.views,
                              style: const TextStyle(
                                color: Color(0xFF95A0C1),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
