import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../shop/domain/entities/shop_entity.dart';
import '../../../shop/presentation/bloc/shop_bloc.dart';
import '../../../shop/presentation/bloc/shop_event.dart';
import '../../../shop/presentation/bloc/shop_state.dart';

import '../bloc/queue_bloc.dart';
import '../bloc/queue_event.dart';
import '../bloc/queue_state.dart';
import 'customer_ticket_screen.dart';

class CustomerShopListScreen extends StatefulWidget {
  final UserEntity user;

  const CustomerShopListScreen({super.key, required this.user});

  @override
  State<CustomerShopListScreen> createState() => _CustomerShopListScreenState();
}

class _CustomerShopListScreenState extends State<CustomerShopListScreen> {
  final _searchController = TextEditingController();
  String _selectedCategory = 'All';

  final List<String> _categories = ['All', 'Clinic', 'Salon', 'Repair', 'Bank', 'Restaurant'];

  @override
  void initState() {
    super.initState();
    context.read<ShopBloc>().add(const ShopFetchRequested());
    context.read<QueueBloc>().add(WatchCustomerActiveTicketsRequested(widget.user.id));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    context.read<ShopBloc>().add(ShopFetchRequested(query: query));
  }

  void _filterCategory(String category) {
    setState(() {
      _selectedCategory = category;
    });
    final query = category == 'All' ? '' : category;
    _searchController.text = query;
    _onSearch(query);
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.confirmation_number_rounded, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('LineZero'),
          ],
        ),
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
                                  context.read<QueueBloc>().add(ResetQueueState());
                                  context.read<AuthBloc>().add(AuthSignOutRequested());
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
      body: SafeArea(
        child: Column(
          children: [
            // Search & Banner Header
            Container(
              padding: const EdgeInsets.all(20),
              color: isDark ? AppColors.darkCard : AppColors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome, ${widget.user.name.split(' ').first.toLowerCase()}',
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.darkText : AppColors.neutralDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Find a shop near you and join the queue remotely.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.neutralMid,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchController,
                    onChanged: _onSearch,
                    decoration: InputDecoration(
                      hintText: 'Search clinic, salon, repair...',
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.neutralMid),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: AppColors.neutralMid),
                              onPressed: () {
                                _searchController.clear();
                                _filterCategory('All');
                              },
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Category Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _categories.map((cat) {
                        final isSelected = _selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: GestureDetector(
                            onTap: () => _filterCategory(cat),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary
                                    : (isDark ? AppColors.darkCard : Colors.white),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : (isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB)),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                cat,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white
                                      : (isDark ? AppColors.darkText : const Color(0xFF4B5563)),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.border),

            // Shops List
            Expanded(
              child: BlocBuilder<ShopBloc, ShopState>(
                builder: (context, state) {
                  if (state is ShopInitial || state is ShopLoading) {
                    return const SkeletonCardList(count: 3);
                  }

                  if (state is ShopsLoaded) {
                    final shops = state.shops;

                    if (shops.isEmpty) {
                      return EmptyStateWidget(
                        icon: Icons.search_off_rounded,
                        title: 'No shops found',
                        subtitle: 'Try searching for another category or shop name.',
                        buttonLabel: 'Reset filters',
                        onButtonPressed: () {
                          _searchController.clear();
                          _filterCategory('All');
                        },
                      );
                    }

                    return RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: () async {
                        context.read<ShopBloc>().add(ShopFetchRequested(query: _searchController.text));
                        context.read<QueueBloc>().add(WatchCustomerActiveTicketsRequested(widget.user.id));
                        await Future.delayed(const Duration(milliseconds: 600));
                      },
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(20),
                        itemCount: shops.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final shop = shops[index];
                          return _buildShopCard(shop, isDark);
                        },
                      ),
                    );
                  }

                  return const EmptyStateWidget(
                    icon: Icons.error_outline_rounded,
                    title: 'Failed to load shops',
                    subtitle: 'Check connection and try again.',
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShopCard(ShopEntity shop, bool isDark) {
    final categoryIcon = _getCategoryIcon(shop.category);

    final queueState = context.watch<QueueBloc>().state;
    bool hasActiveTicket = false;
    if (queueState is QueueLoaded) {
      hasActiveTicket = queueState.activeCustomerTicketsByShopId.containsKey(shop.id);
    }

    final buttonLabel = hasActiveTicket
        ? 'View queue'
        : (shop.isQueueOpen ? 'Join queue' : 'Closed');
    final buttonIcon = hasActiveTicket
        ? Icons.visibility_outlined
        : Icons.confirmation_number_outlined;
    final isDisabled = !hasActiveTicket && !shop.isQueueOpen;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Soft Blue Rounded Square Icon Badge
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBackground : AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(categoryIcon, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 14),

                // Shop Title, Subtitle & Status
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                      const SizedBox(height: 3),
                      Text(
                        '${shop.category} • ${shop.address}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.neutralMid,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),

                      // Green Dot + Queue Open · ~10 min
                      Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: shop.isQueueOpen ? AppColors.success : AppColors.warningUrgent,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              shop.isQueueOpen
                                  ? 'Queue open • ~${shop.avgServiceTimeMinutes} min'
                                  : 'Queue closed',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: shop.isQueueOpen ? AppColors.success : AppColors.warningUrgent,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Full-Width Action Button (Join queue vs View queue)
            CustomButton(
              label: buttonLabel,
              isCompact: false,
              isDisabled: isDisabled,
              icon: buttonIcon,
              color: AppColors.primary,
              onPressed: () async {
                if (!hasActiveTicket) {
                  context.read<QueueBloc>().add(
                        JoinQueueRequested(
                          shopId: shop.id,
                          customerId: widget.user.id,
                          customerName: widget.user.name,
                        ),
                      );
                }

                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CustomerTicketScreen(
                      shop: shop,
                      user: widget.user,
                    ),
                  ),
                );

                if (mounted) {
                  context.read<QueueBloc>().add(WatchCustomerActiveTicketsRequested(widget.user.id));
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
