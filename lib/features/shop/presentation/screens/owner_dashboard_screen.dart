import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../queue/domain/entities/ticket_entity.dart';
import '../../../queue/presentation/bloc/queue_bloc.dart';
import '../../../queue/presentation/bloc/queue_event.dart';
import '../../../queue/presentation/bloc/queue_state.dart';
import '../../domain/entities/shop_entity.dart';
import '../bloc/shop_bloc.dart';
import '../bloc/shop_event.dart';
import '../bloc/shop_state.dart';
import 'create_shop_screen.dart';
import '../../../subscription/presentation/bloc/subscription_bloc.dart';
import '../../../subscription/presentation/bloc/subscription_event.dart';
import '../../../subscription/presentation/bloc/subscription_state.dart';
import '../../../subscription/domain/entities/subscription_entity.dart';
import '../../../subscription/presentation/screens/paywall_screen.dart';

class OwnerDashboardScreen extends StatefulWidget {
  final String ownerId;

  const OwnerDashboardScreen({super.key, required this.ownerId});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ShopBloc>().add(OwnerShopFetchRequested(widget.ownerId));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.neutralLight,
      appBar: AppBar(
        title: const Text('Owner Queue Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign Out',
            onPressed: () {
              showDialog(
                context: context,
                builder: (dialogContext) => Dialog(
                  backgroundColor: isDark ? AppColors.darkCard : Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sign out',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: isDark ? AppColors.darkText : AppColors.neutralDark,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Are you sure you want to sign out of your account?',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: isDark ? AppColors.darkText.withValues(alpha: 0.8) : AppColors.neutralMid,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.of(dialogContext).pop(),
                              child: Text(
                                'Cancel',
                                style: GoogleFonts.inter(
                                  color: AppColors.neutralMid,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Material(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(10),
                              child: InkWell(
                                onTap: () {
                                  Navigator.of(dialogContext).pop();
                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    if (context.mounted) {
                                      Navigator.of(context).popUntil((route) => route.isFirst);
                                      context.read<QueueBloc>().add(ResetQueueState());
                                      context.read<AuthBloc>().add(AuthSignOutRequested());
                                    }
                                  });
                                },
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                  child: Text(
                                    'Sign out',
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
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
            },
          ),
        ],
      ),
      body: BlocBuilder<ShopBloc, ShopState>(
        builder: (context, shopState) {
          if (shopState is ShopInitial || shopState is ShopLoading) {
            return const SkeletonCardList(count: 3);
          }

          if (shopState is OwnerShopLoaded) {
            final shop = shopState.shop;
            if (shop == null) {
              return EmptyStateWidget(
                icon: Icons.store_rounded,
                title: 'No Shop Found',
                subtitle:
                    'Create your shop profile to start managing digital queues.',
                buttonLabel: 'Create Shop Profile',
                onButtonPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CreateShopScreen(ownerId: widget.ownerId),
                    ),
                  );
                },
              );
            }

            return _OwnerDashboardContent(shop: shop);
          }

          return const EmptyStateWidget(
            icon: Icons.error_outline_rounded,
            title: 'Unable to Load Shop',
            subtitle: 'Could not fetch shop profile details. Please try again.',
          );
        },
      ),
    );
  }
}

class _OwnerDashboardContent extends StatefulWidget {
  final ShopEntity shop;

  const _OwnerDashboardContent({required this.shop});

  @override
  State<_OwnerDashboardContent> createState() => _OwnerDashboardContentState();
}

class _OwnerDashboardContentState extends State<_OwnerDashboardContent> {
  @override
  void initState() {
    super.initState();
    context.read<QueueBloc>().add(WatchQueueRequested(widget.shop.id));
    context.read<SubscriptionBloc>().add(SubscriptionFetchRequested(widget.shop.id));
  }

  Widget _buildSubscriptionHeaderBadge(SubscriptionEntity? subscription, bool isDark) {
    if (subscription == null) return const SizedBox.shrink();

    if (subscription.isActive) {
      return Container(
        width: double.infinity,
        color: Colors.green.withValues(alpha: 0.1),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.star_rounded, color: Colors.green, size: 18),
            const SizedBox(width: 8),
            Text(
              'Pro Subscription Active (${subscription.plan == 'yearly' ? 'Yearly' : 'Monthly'})',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 13),
            ),
          ],
        ),
      );
    }

    final daysLeft = subscription.daysLeftInTrial;
    final isExpired = subscription.isExpired;

    return Container(
      width: double.infinity,
      color: isExpired ? AppColors.coralRed.withValues(alpha: 0.1) : AppColors.amber.withValues(alpha: 0.12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(
            isExpired ? Icons.lock_clock_rounded : Icons.timer_rounded,
            color: isExpired ? AppColors.coralRed : AppColors.amber,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isExpired
                  ? 'Free Trial Expired — Dashboard Locked'
                  : 'Free Trial: $daysLeft Day${daysLeft == 1 ? '' : 's'} Remaining',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                color: isExpired ? AppColors.coralRed : (isDark ? AppColors.amber : Colors.brown.shade800),
                fontSize: 13,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => PaywallScreen(shopId: widget.shop.id, shopName: widget.shop.name),
              );
            },
            child: Text(
              isExpired ? 'Unlock Now' : 'Upgrade',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                color: isExpired ? AppColors.coralRed : AppColors.trustBlue,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shop = widget.shop;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<SubscriptionBloc, SubscriptionState>(
      builder: (context, subState) {
        SubscriptionEntity? subscription;
        if (subState is SubscriptionLoaded) {
          subscription = subState.subscription;
        }

        final isExpired = subscription?.isExpired ?? false;

        return Scaffold(
          backgroundColor: isDark
              ? AppColors.darkBackground
              : const Color(0xFFF9FAFB),
          body: Stack(
            children: [
              Column(
                children: [
                  _buildSubscriptionHeaderBadge(subscription, isDark),
                  // Shop Status Header Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    color: isDark ? AppColors.darkCard : AppColors.white,
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    shop.name,
                                    style: GoogleFonts.inter(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? AppColors.darkText
                                          : AppColors.neutralDark,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${shop.category} • ${shop.address}',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: AppColors.neutralMid,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  shop.isQueueOpen ? 'OPEN' : 'CLOSED',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: shop.isQueueOpen
                                        ? AppColors.success
                                        : AppColors.warningUrgent,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Switch(
                                  value: shop.isQueueOpen,
                                  activeThumbColor: AppColors.success,
                                  onChanged: (val) {
                                    context.read<ShopBloc>().add(
                                      ShopToggleQueueRequested(
                                        shopId: shop.id,
                                        isOpen: val,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  Divider(
                    height: 1,
                    color: isDark ? AppColors.darkBorder : AppColors.border,
                  ),

                  // Live Queue Stream View
                  Expanded(
                    child: BlocBuilder<QueueBloc, QueueState>(
                      builder: (context, queueState) {
                        if (queueState is QueueLoading) {
                          return const SkeletonCardList(count: 3);
                        }

                        if (queueState is QueueLoaded) {
                          final tickets = queueState.tickets;
                          final activeTickets = tickets
                              .where((t) => !t.isCompleted && !t.isCancelled)
                              .toList();
                          final inServiceTicket = tickets
                              .where((t) => t.isInService)
                              .firstOrNull;
                          final waitingCount = tickets.where((t) => t.isWaiting).length;

                          if (activeTickets.isEmpty) {
                            return const EmptyStateWidget(
                              icon: Icons.people_outline_rounded,
                              title: 'Queue is Empty',
                              subtitle: 'No customers waiting in line right now.',
                            );
                          }

                          return Column(
                            children: [
                              // Overview Stats Bar
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                color: isDark
                                    ? AppColors.darkCard
                                    : AppColors.primaryLight.withValues(alpha: 0.4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildStatItem(
                                      'Currently Serving',
                                      inServiceTicket != null
                                          ? '#${inServiceTicket.tokenNumber.toString().padLeft(3, '0')}'
                                          : 'None',
                                      AppColors.amber,
                                      isDark,
                                    ),
                                    Container(
                                      height: 24,
                                      width: 1,
                                      color: isDark
                                          ? AppColors.darkBorder
                                          : AppColors.border,
                                    ),
                                    _buildStatItem(
                                      'Waiting in Line',
                                      '$waitingCount customers',
                                      AppColors.primary,
                                      isDark,
                                    ),
                                  ],
                                ),
                              ),

                              Expanded(
                                child: RefreshIndicator(
                                  color: AppColors.primary,
                                  onRefresh: () async {
                                    context.read<QueueBloc>().add(
                                      WatchQueueRequested(shop.id),
                                    );
                                    await Future.delayed(
                                      const Duration(milliseconds: 600),
                                    );
                                  },
                                  child: ListView.separated(
                                    physics: const AlwaysScrollableScrollPhysics(),
                                    padding: const EdgeInsets.all(16),
                                    itemCount: activeTickets.length,
                                    separatorBuilder: (_, _) =>
                                        const SizedBox(height: 12),
                                    itemBuilder: (context, index) {
                                      final ticket = activeTickets[index];
                                      return _buildOwnerTicketRow(ticket, isDark);
                                    },
                                  ),
                                ),
                              ),
                            ],
                          );
                        }

                        return const EmptyStateWidget(
                          icon: Icons.cloud_off_rounded,
                          title: 'Disconnected',
                          subtitle: 'Unable to connect to live queue stream.',
                        );
                      },
                    ),
                  ),
                ],
              ),
              if (isExpired)
                Positioned.fill(
                  child: PaywallScreen(
                    shopId: widget.shop.id,
                    shopName: widget.shop.name,
                  ),
                ),
            ],
          ),

          // Pinned Bottom Bar: CALL NEXT CUSTOMER (Always Visible)
          bottomNavigationBar: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.white,
              border: Border(
                top: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.border,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: CustomButton(
                label: 'Call Next Customer',
                icon: Icons.campaign_rounded,
                color: AppColors.primary,
                onPressed: (shop.isQueueOpen && !isExpired)
                    ? () {
                        context.read<QueueBloc>().add(CallNextRequested(shop.id));
                      }
                    : null,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, Color color, bool isDark) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, color: AppColors.neutralMid),
        ),
      ],
    );
  }

  Widget _buildOwnerTicketRow(TicketEntity ticket, bool isDark) {
    final isInService = ticket.isInService;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isInService
            ? (isDark
                  ? AppColors.amber.withValues(alpha: 0.15)
                  : AppColors.amberLight)
            : (isDark ? AppColors.darkCard : AppColors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isInService
              ? AppColors.amber
              : (isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB)),
          width: isInService ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isInService
                ? AppColors.amber.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Token Badge (#004)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isInService
                  ? AppColors.amber
                  : (isDark
                        ? AppColors.darkBackground
                        : AppColors.primaryLight),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '#${ticket.tokenNumber.toString().padLeft(3, '0')}',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isInService ? Colors.white : AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Customer Name & Status Badge
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  ticket.customerName,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkText : AppColors.neutralDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                StatusBadge(status: ticket.status),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Action Buttons (Complete for in-service, Skip for waiting)
          if (isInService) ...[
            ElevatedButton.icon(
              onPressed: () {
                context.read<QueueBloc>().add(
                  UpdateStatusRequested(
                    shopId: widget.shop.id,
                    ticketId: ticket.id,
                    newStatus: 'completed',
                  ),
                );
              },
              icon: const Icon(
                Icons.check_circle_rounded,
                size: 16,
                color: Colors.white,
              ),
              label: Text(
                'Complete',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: const Size(0, 40),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ] else if (ticket.isWaiting) ...[
            OutlinedButton(
              onPressed: () {
                context.read<QueueBloc>().add(
                  UpdateStatusRequested(
                    shopId: widget.shop.id,
                    ticketId: ticket.id,
                    newStatus: 'skipped',
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.neutralMid,
                side: BorderSide(
                  color: isDark
                      ? AppColors.darkBorder
                      : const Color(0xFFE5E7EB),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                minimumSize: const Size(0, 38),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Skip',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
