import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../queue/presentation/bloc/queue_bloc.dart';
import '../../../queue/presentation/bloc/queue_event.dart';
import '../../../queue/presentation/bloc/queue_state.dart';
import '../../domain/entities/shop_entity.dart';

class PublicQueueDisplayScreen extends StatefulWidget {
  final ShopEntity shop;

  const PublicQueueDisplayScreen({
    super.key,
    required this.shop,
  });

  @override
  State<PublicQueueDisplayScreen> createState() => _PublicQueueDisplayScreenState();
}

class _PublicQueueDisplayScreenState extends State<PublicQueueDisplayScreen> {
  late Timer _clockTimer;
  DateTime _currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Request live queue updates for shop
    context.read<QueueBloc>().add(WatchQueueRequested(widget.shop.id));

    // Digital Clock Ticker
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _currentTime = DateTime.now());
      }
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }

  String _formatClock(DateTime time) {
    final local = time.toLocal();
    final hour = local.hour == 0 ? 12 : (local.hour > 12 ? local.hour - 12 : local.hour);
    final minute = local.minute.toString().padLeft(2, '0');
    final second = local.second.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute:$second $period';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 2,
        title: Row(
          children: [
            const Icon(Icons.tv_rounded, color: AppColors.primary, size: 26),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.shop.name,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.neutralDark,
                  ),
                ),
                Text(
                  'Live Token Display Screen (TV Mode)',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.neutralMid,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Digital Live Clock
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time_filled_rounded, size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  _formatClock(_currentTime),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: BlocConsumer<QueueBloc, QueueState>(
        listenWhen: (previous, current) {
          if (previous is QueueLoaded && current is QueueLoaded) {
            final prevServing = previous.tickets.where((t) => t.isInService || t.isCalled).firstOrNull?.id;
            final currServing = current.tickets.where((t) => t.isInService || t.isCalled).firstOrNull?.id;
            return currServing != null && currServing != prevServing;
          }
          return false;
        },
        listener: (context, state) {
          if (state is QueueLoaded) {
            final servingTicket = state.tickets.where((t) => t.isInService || t.isCalled).firstOrNull;
            if (servingTicket != null) {
              HapticFeedback.vibrate();
              NotificationService.instance.speakBilingualTokenAnnouncement(
                tokenNumber: servingTicket.tokenNumber,
                customerName: servingTicket.customerName,
              );
            }
          }
        },
        builder: (context, state) {
          if (state is QueueLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is QueueLoaded) {
            final tickets = state.tickets;
            final servingTicket = tickets.where((t) => t.isInService || t.isCalled).firstOrNull;
            final nextWaitingTickets = tickets.where((t) => t.isWaiting || t.isConfirmed).toList();

            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // 1. HERO SERVING TOKEN DISPLAY CARD (HUGE TEXT FOR DISTANCE VISIBILITY)
                  Expanded(
                    flex: 3,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: servingTicket != null
                              ? [const Color(0xFF2563EB), const Color(0xFF1D4ED8)]
                              : (isDark
                                  ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                                  : [Colors.white, const Color(0xFFF8FAFC)]),
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: servingTicket != null
                                ? const Color(0xFF2563EB).withValues(alpha: 0.35)
                                : Colors.black.withValues(alpha: 0.05),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                        border: Border.all(
                          color: servingTicket != null
                              ? Colors.white.withValues(alpha: 0.2)
                              : (isDark ? AppColors.darkBorder : Colors.grey.shade300),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.campaign_rounded,
                                color: servingTicket != null ? Colors.white70 : AppColors.neutralMid,
                                size: 28,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'NOW SERVING',
                                style: GoogleFonts.inter(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2.0,
                                  color: servingTicket != null ? Colors.white70 : AppColors.neutralMid,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // ULTRA BOLD HUGE TOKEN NUMBER
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              servingTicket != null
                                  ? '#${servingTicket.tokenNumber.toString().padLeft(3, '0')}'
                                  : '---',
                              style: GoogleFonts.outfit(
                                fontSize: 130,
                                fontWeight: FontWeight.w900,
                                color: servingTicket != null
                                    ? Colors.white
                                    : (isDark ? Colors.white38 : AppColors.neutralDark),
                                letterSpacing: 2.0,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // CUSTOMER NAME
                          Text(
                            servingTicket != null
                                ? (servingTicket.customerName.trim().isEmpty || servingTicket.customerName == 'Walk-in'
                                    ? 'Walk-in Customer'
                                    : servingTicket.customerName)
                                : 'No Customer Being Served',
                            style: GoogleFonts.inter(
                              fontSize: 26,
                              fontWeight: FontWeight.w600,
                              color: servingTicket != null ? Colors.white : AppColors.neutralMid,
                            ),
                          ),
                          if (servingTicket != null) ...[
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () {
                                HapticFeedback.vibrate();
                                NotificationService.instance.speakBilingualTokenAnnouncement(
                                  tokenNumber: servingTicket.tokenNumber,
                                  customerName: servingTicket.customerName,
                                );
                              },
                              icon: const Icon(Icons.volume_up_rounded, size: 20),
                              label: const Text('Re-announce Voice'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white.withValues(alpha: 0.2),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 2. NEXT IN LINE HORIZONTAL PREVIEW BAR
                  Expanded(
                    flex: 1,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'UPCOMING TOKENS',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                              color: AppColors.neutralMid,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: nextWaitingTickets.isEmpty
                                ? Center(
                                    child: Text(
                                      'No upcoming tokens waiting',
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        color: AppColors.neutralMid,
                                      ),
                                    ),
                                  )
                                : ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: nextWaitingTickets.length,
                                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                                    itemBuilder: (context, index) {
                                      final ticket = nextWaitingTickets[index];
                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? AppColors.darkBackground
                                              : AppColors.primaryLight,
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: AppColors.primary.withValues(alpha: 0.3),
                                          ),
                                        ),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              '#${ticket.tokenNumber.toString().padLeft(3, '0')}',
                                              style: GoogleFonts.outfit(
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                            Text(
                                              ticket.customerName.isEmpty ? 'Walk-in' : ticket.customerName,
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                color: isDark ? AppColors.darkText : AppColors.neutralDark,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return const Center(child: Text('Unable to load queue stream'));
        },
      ),
    );
  }
}
