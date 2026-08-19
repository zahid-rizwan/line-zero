import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/services/notification_service.dart';
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
      body: BlocBuilder<ShopBloc, ShopState>(
        builder: (context, shopState) {
          if (shopState is ShopInitial || shopState is ShopLoading) {
            return Scaffold(
              appBar: AppBar(title: const Text('Owner Queue Dashboard')),
              body: const SkeletonCardList(count: 3),
            );
          }

          if (shopState is OwnerShopLoaded) {
            final shop = shopState.shop;
            if (shop == null) {
              return Scaffold(
                appBar: AppBar(title: const Text('Owner Queue Dashboard')),
                body: EmptyStateWidget(
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
                ),
              );
            }

            return _OwnerDashboardContent(shop: shop);
          }

          return Scaffold(
            appBar: AppBar(title: const Text('Owner Queue Dashboard')),
            body: const EmptyStateWidget(
              icon: Icons.error_outline_rounded,
              title: 'Unable to Load Shop',
              subtitle: 'Could not fetch shop profile details. Please try again.',
            ),
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
  String _selectedFilter = 'all'; // 'all' | 'active' | 'pending'

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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          children: [
            const Icon(Icons.star_rounded, color: Colors.green, size: 16),
            const SizedBox(width: 6),
            Text(
              'Pro Subscription Active (${subscription.plan == 'yearly' ? 'Yearly' : 'Monthly'})',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 12),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Row(
        children: [
          Icon(
            isExpired ? Icons.lock_clock_rounded : Icons.timer_rounded,
            color: isExpired ? AppColors.coralRed : AppColors.amber,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isExpired
                  ? 'Free Trial Expired — Dashboard Locked'
                  : 'Free Trial: $daysLeft Day${daysLeft == 1 ? '' : 's'} Remaining',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                color: isExpired ? AppColors.coralRed : (isDark ? AppColors.amber : Colors.brown.shade800),
                fontSize: 12,
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
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              isExpired ? 'Unlock Now' : 'Upgrade',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                color: isExpired ? AppColors.coralRed : AppColors.trustBlue,
                fontSize: 12,
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
          appBar: AppBar(
            titleSpacing: 16,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  shop.name,
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkText : AppColors.neutralDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  '${shop.category} • ${shop.address}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.neutralMid,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: (shop.isQueueOpen && !isExpired)
                    ? () => _openAddWalkInModal(context, shop.id)
                    : null,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  backgroundColor: AppColors.primaryLight,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  '+ Walk-in',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
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
              const SizedBox(width: 6),
              IconButton(
                icon: const Icon(Icons.logout_rounded),
                tooltip: 'Sign Out',
                onPressed: () => _showSignOutDialog(context, isDark),
              ),
            ],
          ),
          body: Stack(
            children: [
              Column(
                children: [
                  _buildSubscriptionHeaderBadge(subscription, isDark),

                  // Live Queue Stream View
                  Expanded(
                    child: BlocConsumer<QueueBloc, QueueState>(
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
                      builder: (context, queueState) {
                        if (queueState is QueueLoading) {
                          return const SkeletonCardList(count: 3);
                        }

                        if (queueState is QueueLoaded) {
                          final tickets = queueState.tickets;
                          final waitingList = tickets
                              .where((t) => t.isWaiting || t.isConfirmed || t.isCalled || t.isInService)
                              .toList();
                          final pendingHighList = tickets.where((t) => t.isPendingHigh).toList();
                          final pendingLowList = tickets.where((t) => t.isPendingLow).toList();

                          final inServiceTicket = tickets.where((t) => t.isInService || t.isCalled).firstOrNull;
                          final totalWaitingCount = waitingList.where((t) => t.isWaiting || t.isConfirmed).length;

                          if (waitingList.isEmpty && pendingHighList.isEmpty && pendingLowList.isEmpty) {
                            return const EmptyStateWidget(
                              icon: Icons.people_outline_rounded,
                              title: 'Queue is Empty',
                              subtitle: 'No customers waiting in line right now. Tap "+ Walk-in" to add customers.',
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
                                  children: [
                                    Expanded(
                                      child: _buildStatItem(
                                        'Currently Serving',
                                        inServiceTicket != null
                                            ? '#${inServiceTicket.tokenNumber.toString().padLeft(3, '0')}'
                                            : 'None',
                                        AppColors.amber,
                                        isDark,
                                        onAction: inServiceTicket != null
                                            ? () {
                                                HapticFeedback.vibrate();
                                                NotificationService.instance.speakBilingualTokenAnnouncement(
                                                  tokenNumber: inServiceTicket.tokenNumber,
                                                  customerName: inServiceTicket.customerName,
                                                );
                                              }
                                            : null,
                                      ),
                                    ),
                                    Container(
                                      height: 24,
                                      width: 1,
                                      color: isDark
                                          ? AppColors.darkBorder
                                          : AppColors.border,
                                    ),
                                    Expanded(
                                      child: _buildStatItem(
                                        'Active Line',
                                        '$totalWaitingCount waiting',
                                        AppColors.primary,
                                        isDark,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Filter Tab Chips Bar
                              _buildFilterBar(waitingList.length, pendingHighList.length + pendingLowList.length, isDark),

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
                                  child: ListView(
                                    padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 90),
                                    children: [
                                      // 1. ACTIVE QUEUE SECTION
                                      if ((_selectedFilter == 'all' || _selectedFilter == 'active') && waitingList.isNotEmpty) ...[
                                        _buildSectionHeader('ACTIVE QUEUE', waitingList.length, AppColors.primary, isDark, icon: Icons.play_circle_fill_rounded),
                                        const SizedBox(height: 8),
                                        ...waitingList.map((ticket) => Padding(
                                              padding: const EdgeInsets.only(bottom: 12),
                                              child: _buildOwnerTicketRow(ticket, isDark),
                                            )),
                                        const SizedBox(height: 16),
                                      ],

                                      // 2. PENDING HIGH PRIORITY SECTION (CALLED EARLY)
                                      if ((_selectedFilter == 'all' || _selectedFilter == 'pending') && pendingHighList.isNotEmpty) ...[
                                        _buildSectionHeader('PENDING (CALLED EARLY)', pendingHighList.length, AppColors.amber, isDark, icon: Icons.bolt_rounded),
                                        const SizedBox(height: 8),
                                        ...pendingHighList.map((ticket) => Padding(
                                              padding: const EdgeInsets.only(bottom: 12),
                                              child: _buildOwnerTicketRow(ticket, isDark),
                                            )),
                                        const SizedBox(height: 16),
                                      ],

                                      // 3. PENDING LOW PRIORITY SECTION (MISSED ESTIMATE)
                                      if ((_selectedFilter == 'all' || _selectedFilter == 'pending') && pendingLowList.isNotEmpty) ...[
                                        _buildSectionHeader('PENDING (MISSED ESTIMATE)', pendingLowList.length, const Color(0xFFEA580C), isDark, icon: Icons.history_toggle_off_rounded),
                                        const SizedBox(height: 8),
                                        ...pendingLowList.map((ticket) => Padding(
                                              padding: const EdgeInsets.only(bottom: 12),
                                              child: _buildOwnerTicketRow(ticket, isDark),
                                            )),
                                      ],

                                      // Empty Filter State
                                      if (_selectedFilter == 'active' && waitingList.isEmpty)
                                        const Padding(
                                          padding: EdgeInsets.only(top: 40),
                                          child: EmptyStateWidget(
                                            icon: Icons.check_circle_outline_rounded,
                                            title: 'No Active Customers',
                                            subtitle: 'There are no active customers waiting in line right now.',
                                          ),
                                        ),

                                      if (_selectedFilter == 'pending' && pendingHighList.isEmpty && pendingLowList.isEmpty)
                                        const Padding(
                                          padding: EdgeInsets.only(top: 40),
                                          child: EmptyStateWidget(
                                            icon: Icons.history_toggle_off_rounded,
                                            title: 'No Pending Customers',
                                            subtitle: 'There are no missed or pending customers right now.',
                                          ),
                                        ),
                                    ],
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

          // Transparent Floating Bottom Bar: CALL NEXT CUSTOMER
          bottomNavigationBar: Container(
            color: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    final local = time.toLocal();
    final hour = local.hour == 0 ? 12 : (local.hour > 12 ? local.hour - 12 : local.hour);
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  Widget _buildStatItem(
    String label,
    String value,
    Color color,
    bool isDark, {
    VoidCallback? onAction,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            if (onAction != null) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onAction,
                child: Icon(
                  Icons.volume_up_rounded,
                  color: color,
                  size: 18,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, color: AppColors.neutralMid),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, int count, Color accentColor, bool isDark, {IconData? icon}) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 16, color: accentColor),
          const SizedBox(width: 6),
        ],
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              color: accentColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: accentColor,
            ),
          ),
        ),
      ],
    );
  }

  void _showSignOutDialog(BuildContext context, bool isDark) {
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
                        context.read<QueueBloc>().add(ResetQueueState());
                        context.read<AuthBloc>().add(AuthSignOutRequested());
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
  }

  Widget _buildFilterBar(int activeCount, int pendingCount, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('all', 'All (${activeCount + pendingCount})', isDark, icon: Icons.format_list_bulleted_rounded),
            const SizedBox(width: 8),
            _buildFilterChip('active', 'Active ($activeCount)', isDark, icon: Icons.play_circle_fill_rounded, iconColor: AppColors.primary),
            const SizedBox(width: 8),
            _buildFilterChip('pending', 'Pending ($pendingCount)', isDark, icon: Icons.history_toggle_off_rounded, iconColor: const Color(0xFFEA580C)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, bool isDark, {IconData? icon, Color? iconColor}) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedFilter = value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : (isDark ? AppColors.darkCard : AppColors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB)),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : (iconColor ?? AppColors.neutralMid),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : (isDark ? AppColors.darkText : AppColors.neutralDark),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openAddWalkInModal(BuildContext context, String shopId) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nameController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkCard : AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (modalCtx) {
        return Padding(
          padding: EdgeInsets.only(
            top: 24,
            left: 24,
            right: 24,
            bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBorder : AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Add Walk-in Customer',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkText : AppColors.neutralDark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Assign next available token number from the atomic counter.',
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.neutralMid),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Customer Name (Optional - e.g. Ramesh)',
                  filled: true,
                  fillColor: isDark ? AppColors.darkBackground : const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              CustomButton(
                label: 'Issue Walk-in Token',
                color: AppColors.primary,
                onPressed: () {
                  final name = nameController.text.trim();
                  context.read<QueueBloc>().add(
                        AddWalkInRequested(
                          shopId: shopId,
                          customerName: name.isEmpty ? null : name,
                        ),
                      );
                  Navigator.pop(modalCtx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Walk-in customer "${name.isEmpty ? 'Walk-in' : name}" added to queue!'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOwnerTicketRow(TicketEntity ticket, bool isDark) {
    final isInService = ticket.isInService || ticket.isCalled;
    final isPending = ticket.isPending;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isInService
            ? (isDark
                  ? AppColors.amber.withValues(alpha: 0.15)
                  : AppColors.amberLight)
            : isPending
                ? (isDark
                      ? const Color(0xFFEA580C).withValues(alpha: 0.12)
                      : const Color(0xFFFFEDD5))
                : (isDark ? AppColors.darkCard : AppColors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isInService
              ? AppColors.amber
              : isPending
                  ? const Color(0xFFEA580C)
                  : (isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB)),
          width: isInService || isPending ? 2 : 1,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Token Badge (#004)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isInService
                      ? AppColors.amber
                      : isPending
                          ? const Color(0xFFEA580C)
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
                    color: isInService || isPending ? Colors.white : AppColors.primary,
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            ticket.customerName,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.darkText : AppColors.neutralDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (ticket.isWalkIn) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'WALK-IN',
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: AppColors.neutralMid,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        StatusBadge(status: ticket.status),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.schedule_rounded, size: 12, color: AppColors.neutralMid),
                            const SizedBox(width: 3),
                            Text(
                              'Joined: ${_formatTime(ticket.joinedAt)}',
                              style: GoogleFonts.inter(fontSize: 11, color: AppColors.neutralMid),
                            ),
                          ],
                        ),
                        if (ticket.isPending && ticket.movedToPendingAt != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.history_toggle_off_rounded, size: 12, color: Color(0xFFEA580C)),
                              const SizedBox(width: 3),
                              Text(
                                'On Hold: ${_formatTime(ticket.movedToPendingAt)}',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFEA580C),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Action Buttons Bar (Responsive Wrap)
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: [
                if (isInService) ...[
                  OutlinedButton.icon(
                    onPressed: () {
                      context.read<QueueBloc>().add(
                            MoveToPendingRequested(
                              shopId: widget.shop.id,
                              ticketId: ticket.id,
                            ),
                          );
                    },
                    icon: const Icon(Icons.history_toggle_off_rounded, size: 15),
                    label: const Text('Move to Pending'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFEA580C),
                      side: const BorderSide(color: Color(0xFFEA580C)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: const Size(0, 34),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
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
                    icon: const Icon(Icons.check_circle_rounded, size: 16, color: Colors.white),
                    label: Text(
                      'Complete',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size(0, 34),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ] else if (isPending) ...[
                  OutlinedButton.icon(
                    onPressed: () {
                      context.read<QueueBloc>().add(
                            ReaddFromPendingRequested(
                              shopId: widget.shop.id,
                              ticketId: ticket.id,
                            ),
                          );
                    },
                    icon: const Icon(Icons.refresh_rounded, size: 15),
                    label: const Text('Re-add'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: const Size(0, 34),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      context.read<QueueBloc>().add(
                            UpdateStatusRequested(
                              shopId: widget.shop.id,
                              ticketId: ticket.id,
                              newStatus: 'in_service',
                            ),
                          );
                    },
                    icon: const Icon(Icons.campaign_rounded, size: 16, color: Colors.white),
                    label: Text(
                      'Call Now',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEA580C),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size(0, 34),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ] else if (ticket.isWaiting || ticket.isConfirmed) ...[
                  OutlinedButton.icon(
                    onPressed: () {
                      context.read<QueueBloc>().add(
                            MoveToPendingRequested(
                              shopId: widget.shop.id,
                              ticketId: ticket.id,
                            ),
                          );
                    },
                    icon: const Icon(Icons.redo_rounded, size: 15),
                    label: const Text('Skip / Pending'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.neutralMid,
                      side: BorderSide(color: isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: const Size(0, 34),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
