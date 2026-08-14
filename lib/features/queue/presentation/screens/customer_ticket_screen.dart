import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/token_card.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../shop/domain/entities/shop_entity.dart';
import '../../../../core/services/notification_service.dart';
import '../bloc/queue_bloc.dart';
import '../bloc/queue_event.dart';
import '../bloc/queue_state.dart';

class CustomerTicketScreen extends StatefulWidget {
  final ShopEntity shop;
  final UserEntity user;

  const CustomerTicketScreen({
    super.key,
    required this.shop,
    required this.user,
  });

  @override
  State<CustomerTicketScreen> createState() => _CustomerTicketScreenState();
}

class _CustomerTicketScreenState extends State<CustomerTicketScreen> {
  String? _previousStatus;
  int? _previousPosition;
  bool _isGracePeriod = true;
  Timer? _graceTimer;

  @override
  void initState() {
    super.initState();
    context.read<QueueBloc>().setCurrentCustomerId(widget.user.id);
    context.read<QueueBloc>().add(WatchQueueRequested(widget.shop.id));

    // Allow 1.2s grace period for live stream to deliver the customer's newly created ticket
    _graceTimer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() => _isGracePeriod = false);
      }
    });
  }

  @override
  void dispose() {
    _graceTimer?.cancel();
    super.dispose();
  }

  void _onLeaveQueue(String ticketId) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final queueBloc = context.read<QueueBloc>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: isDark ? AppColors.darkCard : AppColors.white,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.warningUrgent.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.warningUrgent,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Leave live queue?',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkText : AppColors.neutralDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Are you sure you want to cancel your token? You will lose your current position in line.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.neutralMid,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDark ? AppColors.darkText : AppColors.neutralDark,
                        side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(
                        'Keep token',
                        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        queueBloc.add(
                          UpdateStatusRequested(
                            shopId: widget.shop.id,
                            ticketId: ticketId,
                            newStatus: 'cancelled',
                          ),
                        );
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Queue token cancelled successfully.'),
                            backgroundColor: AppColors.neutralDark,
                          ),
                        );
                        if (navigator.canPop()) {
                          navigator.pop();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.warningUrgent,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(
                        'Leave queue',
                        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.neutralLight,
      appBar: AppBar(
        title: Text(
          widget.shop.name,
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
      ),
      body: BlocConsumer<QueueBloc, QueueState>(
        listener: (context, state) {
          if (state is QueueError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.warningUrgent,
              ),
            );
          }
          if (state is QueueLoaded && state.currentCustomerTicket != null) {
            final t = state.currentCustomerTicket!;
            final currentPos = state.currentCustomerPosition;

            // Only trigger notifications on REAL state updates after joining (e.g. Shop owner clicks Next)!
            if (_previousStatus != null) {
              if (t.isInService && _previousStatus != 'in_service') {
                HapticFeedback.vibrate();
                NotificationService.instance.showSystemNotification(
                  title: '🚨 YOUR TURN NOW! (आपकी बारी!)',
                  body: 'Token #${t.tokenNumber} called at ${widget.shop.name}. Step up to counter!',
                  hindiVoiceText: 'ध्यान दीजिए! टोकन नंबर ${t.tokenNumber}, ${widget.shop.name} के काउंटर पर पधारें।',
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('🚨 Your turn now! (आपकी बारी आ गई है)'),
                    backgroundColor: AppColors.warningUrgent,
                    duration: Duration(seconds: 4),
                  ),
                );
              } else if (state.isNearTurn && currentPos != null && (_previousPosition == null || currentPos < _previousPosition!)) {
                HapticFeedback.mediumImpact();
                NotificationService.instance.showSystemNotification(
                  title: '🔔 YOUR TURN IS NEAR! (बारी आने वाली है)',
                  body: 'Only $currentPos ${currentPos == 1 ? "person" : "people"} ahead at ${widget.shop.name}.',
                  hindiVoiceText: 'ध्यान दीजिए! ${widget.shop.name} पर आपकी बारी आने वाली है। आपसे आगे केवल $currentPos लोग हैं।',
                );
              }
            }

            // Save tracking state
            _previousStatus = t.status;
            _previousPosition = currentPos;
          }
        },
        builder: (context, state) {
          if (state is QueueInitial || state is QueueLoading || (_isGracePeriod && state is QueueLoaded && state.currentCustomerTicket == null)) {
            return const SkeletonCardList(count: 1);
          }

          if (state is QueueLoaded) {
            final ticket = state.currentCustomerTicket;
            final position = state.currentCustomerPosition;
            final servingTicket = state.tickets.where((t) => t.isInService).firstOrNull;
            final currentlyServingNum = servingTicket?.tokenNumber;

            final completedTickets = state.tickets.where((t) => t.isCompleted).toList();
            completedTickets.sort((a, b) => b.tokenNumber.compareTo(a.tokenNumber));
            final lastCompletedNum = completedTickets.firstOrNull?.tokenNumber;

            final waitingTickets = state.tickets.where((t) => t.isWaiting).toList();
            waitingTickets.sort((a, b) => a.tokenNumber.compareTo(b.tokenNumber));
            final nextWaitingNum = waitingTickets.firstOrNull?.tokenNumber;

            if (ticket == null || ticket.isCancelled) {
              return EmptyStateWidget(
                icon: Icons.confirmation_number_outlined,
                title: ticket?.isCancelled ?? false ? 'Ticket cancelled' : 'Not in queue',
                subtitle: 'You are no longer waiting in this shop queue.',
                buttonLabel: 'Back to shops',
                onButtonPressed: () => Navigator.of(context).pop(),
              );
            }

            final estimatedMinutes = position != null ? position * widget.shop.avgServiceTimeMinutes : null;

            return SafeArea(
              child: Center(
                child: RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async {
                    context.read<QueueBloc>().add(WatchQueueRequested(widget.shop.id));
                    await Future.delayed(const Duration(milliseconds: 600));
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                    child: Column(
                    children: [
                      // Single Unified Hero Live Ticket Card with breathing pulse animation
                      TokenCard(
                        tokenNumber: ticket.tokenNumber,
                        status: ticket.status,
                        shopName: widget.shop.name,
                        position: position,
                        estimatedWaitMinutes: estimatedMinutes,
                        currentlyServingTokenNumber: currentlyServingNum,
                        lastCompletedTokenNumber: lastCompletedNum,
                        nextWaitingTokenNumber: nextWaitingNum,
                      ),
                      const SizedBox(height: 16),

                      // Secondary Info Card (Plain White Card, Bordered)
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isDark ? AppColors.darkBackground : AppColors.primaryLight,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.timer_outlined, color: AppColors.primary, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Estimated wait time',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: AppColors.neutralMid,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        estimatedMinutes != null && estimatedMinutes > 0
                                            ? '~ $estimatedMinutes mins'
                                            : 'Ready for service',
                                        style: GoogleFonts.inter(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? AppColors.darkText : AppColors.neutralDark,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Divider(height: 1, color: isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB)),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isDark ? AppColors.darkBackground : AppColors.primaryLight,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.storefront_outlined, color: AppColors.primary, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Shop details',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: AppColors.neutralMid,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${widget.shop.name} • ${widget.shop.category}',
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? AppColors.darkText : AppColors.neutralDark,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        widget.shop.address,
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: AppColors.neutralMid,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Full-Width Outlined Destructive Coral Red Action Button
                      if (ticket.isWaiting || ticket.isInService)
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _onLeaveQueue(ticket.id),
                            icon: const Icon(Icons.cancel_outlined, color: AppColors.warningUrgent, size: 20),
                            label: Text(
                              'Cancel and leave queue',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.warningUrgent,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: isDark ? AppColors.darkCard : Colors.white,
                              side: const BorderSide(color: AppColors.warningUrgent, width: 1.5),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
          }

          return const Center(child: Text('Connecting to live queue...'));
        },
      ),
    );
  }
}
