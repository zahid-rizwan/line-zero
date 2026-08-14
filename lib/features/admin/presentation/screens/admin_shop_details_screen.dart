import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:queue_token_app/core/theme/app_colors.dart';
import 'package:queue_token_app/core/widgets/empty_state_widget.dart';
import 'package:queue_token_app/core/widgets/skeleton_loader.dart';
import 'package:queue_token_app/core/widgets/status_badge.dart';
import 'package:queue_token_app/features/queue/domain/entities/ticket_entity.dart';
import 'package:queue_token_app/features/queue/presentation/bloc/queue_bloc.dart';
import 'package:queue_token_app/features/queue/presentation/bloc/queue_event.dart';
import 'package:queue_token_app/features/queue/presentation/bloc/queue_state.dart';
import 'package:queue_token_app/features/shop/domain/entities/shop_entity.dart';
import 'package:queue_token_app/features/shop/presentation/bloc/shop_bloc.dart';
import 'package:queue_token_app/features/shop/presentation/bloc/shop_event.dart';

class AdminShopDetailsScreen extends StatefulWidget {
  final ShopEntity shop;

  const AdminShopDetailsScreen({super.key, required this.shop});

  @override
  State<AdminShopDetailsScreen> createState() => _AdminShopDetailsScreenState();
}

class _AdminShopDetailsScreenState extends State<AdminShopDetailsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<QueueBloc>().add(WatchQueueRequested(widget.shop.id));
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'clinic':
        return Icons.medical_services_rounded;
      case 'salon':
        return Icons.content_cut_rounded;
      case 'repair':
        return Icons.build_rounded;
      case 'bank':
        return Icons.account_balance_rounded;
      case 'restaurant':
        return Icons.restaurant_rounded;
      default:
        return Icons.storefront_rounded;
    }
  }

  void _confirmDeleteShop(BuildContext context, ShopEntity shop, bool isDark) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Shop',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: isDark ? AppColors.darkText : AppColors.neutralDark,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${shop.name}"? This action cannot be undone.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: isDark ? AppColors.darkText.withValues(alpha: 0.8) : AppColors.neutralMid,
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        actions: [
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.inter(
                    color: AppColors.neutralMid,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pop(dialogContext);
                  context.read<ShopBloc>().add(ShopDeleteRequested(shop.id));
                  Navigator.pop(context); // Pop shop details screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${shop.name} deleted successfully.'),
                      backgroundColor: AppColors.neutralDark,
                    ),
                  );
                },
                child: Text(
                  'Delete',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shop = widget.shop;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categoryIcon = _getCategoryIcon(shop.category);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(
          'Shop Details',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.warningUrgent),
            tooltip: 'Delete Shop',
            onPressed: () => _confirmDeleteShop(context, shop, isDark),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          context.read<QueueBloc>().add(WatchQueueRequested(shop.id));
          await Future.delayed(const Duration(milliseconds: 600));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Shop Header Info Tile
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkBackground : AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(categoryIcon, color: AppColors.primary, size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                shop.name,
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppColors.darkText : AppColors.neutralDark,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${shop.category} • ${shop.address}',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: AppColors.neutralMid,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.border),
                    const SizedBox(height: 14),

                    // Owner Info & Copy Button
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Owner ID',
                                style: GoogleFonts.inter(fontSize: 11, color: AppColors.neutralMid),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                shop.ownerId,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppColors.darkText : AppColors.neutralDark,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        InkWell(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: shop.ownerId));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Owner ID copied to clipboard'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.copy_rounded, size: 14, color: AppColors.primary),
                                const SizedBox(width: 6),
                                Text(
                                  'Copy ID',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // KPI Metrics Grid
              BlocBuilder<QueueBloc, QueueState>(
                builder: (context, state) {
                  int totalTokens = 0;
                  int currentlyServing = 0;
                  int waitingCount = 0;

                  if (state is QueueLoaded) {
                    totalTokens = state.tickets.length;
                    final serving = state.tickets.where((t) => t.isInService).firstOrNull;
                    currentlyServing = serving?.tokenNumber ?? 0;
                    waitingCount = state.tickets.where((t) => t.isWaiting).length;
                  }

                  return Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          title: 'Total Tokens',
                          value: totalTokens > 0 ? '$totalTokens' : '0',
                          icon: Icons.confirmation_number_rounded,
                          color: AppColors.primary,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricCard(
                          title: 'Now Serving',
                          value: currentlyServing > 0 ? '#${currentlyServing.toString().padLeft(3, '0')}' : '--',
                          icon: Icons.notifications_active_rounded,
                          color: AppColors.amber,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricCard(
                          title: 'In Line',
                          value: '$waitingCount',
                          icon: Icons.people_alt_rounded,
                          color: AppColors.success,
                          isDark: isDark,
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 24),

              // Live Queue List Section Header
              Text(
                'Live Queue Stream',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkText : AppColors.neutralDark,
                ),
              ),
              const SizedBox(height: 12),

              // Live Queue Tickets List
              BlocBuilder<QueueBloc, QueueState>(
                builder: (context, state) {
                  if (state is QueueInitial || state is QueueLoading) {
                    return const SkeletonCardList(count: 2);
                  }

                  if (state is QueueLoaded) {
                    final tickets = state.tickets.where((t) => !t.isCompleted && !t.isCancelled).toList();

                    if (tickets.isEmpty) {
                      return const EmptyStateWidget(
                        icon: Icons.queue_rounded,
                        title: 'No Active Tokens',
                        subtitle: 'Queue is currently empty for this shop.',
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: tickets.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final ticket = tickets[index];
                        return _buildAdminTicketRow(ticket, isDark);
                      },
                    );
                  }

                  return const EmptyStateWidget(
                    icon: Icons.error_outline_rounded,
                    title: 'Unable to Load Stream',
                    subtitle: 'Check connection and try again.',
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.darkText : AppColors.neutralDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.neutralMid,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminTicketRow(TicketEntity ticket, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ticket.isInService
              ? AppColors.amber
              : (isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB)),
          width: ticket.isInService ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          // Token Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: ticket.isInService ? AppColors.amber : AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '#${ticket.tokenNumber.toString().padLeft(3, '0')}',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: ticket.isInService ? Colors.white : AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Customer Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ticket.customerName,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkText : AppColors.neutralDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Joined: ${_formatTime(ticket.joinedAt)}',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.neutralMid),
                ),
              ],
            ),
          ),

          // Status Badge
          StatusBadge(status: ticket.status),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : (dateTime.hour == 0 ? 12 : dateTime.hour);
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}
