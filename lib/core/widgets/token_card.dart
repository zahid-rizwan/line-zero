import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import 'status_badge.dart';

class TokenCard extends StatefulWidget {
  final int tokenNumber;
  final String status;
  final int? position;
  final String shopName;
  final int? estimatedWaitMinutes;
  final int? currentlyServingTokenNumber;
  final int? lastCompletedTokenNumber;
  final int? nextWaitingTokenNumber;
  final VoidCallback? onCancel;

  const TokenCard({
    super.key,
    required this.tokenNumber,
    required this.status,
    required this.shopName,
    this.position,
    this.estimatedWaitMinutes,
    this.currentlyServingTokenNumber,
    this.lastCompletedTokenNumber,
    this.nextWaitingTokenNumber,
    this.onCancel,
  });

  @override
  State<TokenCard> createState() => _TokenCardState();
}

class _TokenCardState extends State<TokenCard> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _scaleAnimation = Tween<double>(begin: 0.985, end: 1.015).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.status == 'waiting') {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant TokenCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.status == 'waiting') {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  String get _servingPillText {
    if (widget.currentlyServingTokenNumber != null) {
      return 'Now serving: #${widget.currentlyServingTokenNumber!.toString().padLeft(3, '0')}';
    } else if (widget.lastCompletedTokenNumber != null) {
      final lastNum = widget.lastCompletedTokenNumber!.toString().padLeft(3, '0');
      if (widget.nextWaitingTokenNumber != null) {
        final nextNum = widget.nextWaitingTokenNumber!.toString().padLeft(3, '0');
        return 'Last served: #$lastNum (Next: #$nextNum)';
      }
      return 'Last served: #$lastNum';
    } else if (widget.nextWaitingTokenNumber != null) {
      final nextNum = widget.nextWaitingTokenNumber!.toString().padLeft(3, '0');
      return 'Next to be served: #$nextNum';
    } else {
      return 'Now serving: Queue starting';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isYourTurn = widget.status == 'in_service';
    final isWaiting = widget.status == 'waiting';

    Color cardBgColor = AppColors.primary;
    if (isYourTurn) {
      cardBgColor = AppColors.warningUrgent;
    } else if (widget.status == 'completed') {
      cardBgColor = AppColors.success;
    } else if (widget.status == 'skipped' || widget.status == 'cancelled') {
      cardBgColor = AppColors.skipped;
    }

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: isWaiting ? _scaleAnimation.value : 1.0,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: cardBgColor,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: cardBgColor.withValues(alpha: isWaiting ? 0.35 : 0.2),
                  blurRadius: isWaiting ? 24 : 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 26.0),
              child: Column(
                children: [
                  // Shop Name & Status Header Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.shopName,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.white.withValues(alpha: 0.9),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      StatusBadge(status: widget.status, isLarge: true),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Currently Serving / Next Serving Token Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.white.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: widget.currentlyServingTokenNumber != null
                                ? AppColors.amber
                                : AppColors.white.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            _servingPillText,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  // Dominant Token Label & Big Token Number
                  Text(
                    'Your token number',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '#${widget.tokenNumber.toString().padLeft(3, '0')}',
                    style: GoogleFonts.inter(
                      fontSize: 56,
                      fontWeight: FontWeight.w900,
                      color: AppColors.white,
                      height: 1.0,
                    ),
                  ),

                  const SizedBox(height: 22),

                  // Live Position & Est. Wait Time Pill inside card
                  if (isWaiting && widget.position != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.white.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.people_alt_rounded, color: AppColors.white, size: 20),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              widget.position == 0
                                  ? 'You are next in line!'
                                  : '${widget.position} ${widget.position == 1 ? 'person' : 'people'} ahead of you${widget.estimatedWaitMinutes != null && widget.estimatedWaitMinutes! > 0 ? " • ~${widget.estimatedWaitMinutes} mins wait" : ""}',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (isYourTurn) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.white.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.notifications_active, color: AppColors.white, size: 22),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              "Your turn now! Step up to counter",
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
