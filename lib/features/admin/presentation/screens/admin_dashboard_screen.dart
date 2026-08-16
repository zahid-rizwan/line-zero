import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:queue_token_app/core/theme/app_colors.dart';
import 'package:queue_token_app/core/widgets/custom_button.dart';
import 'package:queue_token_app/core/widgets/custom_dropdown.dart';
import 'package:queue_token_app/features/auth/domain/entities/user_entity.dart';
import 'package:queue_token_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:queue_token_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:queue_token_app/features/shop/domain/entities/shop_entity.dart';
import 'package:queue_token_app/features/shop/presentation/bloc/shop_bloc.dart';
import 'package:queue_token_app/features/shop/presentation/bloc/shop_event.dart';
import 'package:queue_token_app/core/services/firebase_service.dart';
import 'package:queue_token_app/core/services/mock_service.dart';
import 'package:queue_token_app/features/shop/presentation/bloc/shop_state.dart';
import 'package:queue_token_app/features/queue/presentation/bloc/queue_bloc.dart';
import 'package:queue_token_app/features/queue/presentation/bloc/queue_event.dart';
import 'package:queue_token_app/core/widgets/skeleton_loader.dart';
import 'admin_shop_details_screen.dart';
import 'package:queue_token_app/features/subscription/domain/entities/pricing_config_entity.dart';
import 'package:queue_token_app/features/subscription/presentation/bloc/subscription_bloc.dart';
import 'package:queue_token_app/features/subscription/presentation/bloc/subscription_event.dart';
import 'package:queue_token_app/features/subscription/presentation/bloc/subscription_state.dart';

class AdminDashboardScreen extends StatefulWidget {
  final UserEntity adminUser;

  const AdminDashboardScreen({super.key, required this.adminUser});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ShopBloc>().add(const ShopFetchRequested());
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'clinic':
        return Icons.local_hospital_rounded;
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

  String _truncateOwnerId(String id) {
    if (id.length <= 13) return id;
    return '${id.substring(0, 6)}...${id.substring(id.length - 5)}';
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    required IconData icon,
    required bool isDark,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.inter(
        fontSize: 14,
        color: const Color(0xFF9CA3AF),
      ),
      prefixIcon: Icon(icon, color: const Color(0xFF9CA3AF), size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: isDark ? AppColors.darkBackground : Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }

  void _openCreateShopModal(BuildContext context) {
    final nameController = TextEditingController();
    final addressController = TextEditingController();
    final ownerEmailController = TextEditingController();
    final ownerNameController = TextEditingController();
    final ownerPasswordController = TextEditingController(text: 'owner123');
    String selectedCategory = 'Clinic';
    int avgTime = 10;
    bool obscureOwnerPassword = true;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkCard : AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 16,
                left: 24,
                right: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Drag Indicator Bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Provision New Shop & Owner',
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? AppColors.darkText
                                  : AppColors.neutralDark,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            color: AppColors.neutralMid,
                          ),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Section 1: Shop Profile
                    Row(
                      children: [
                        const Icon(
                          Icons.storefront_rounded,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Shop profile details',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: nameController,
                      decoration: _buildInputDecoration(
                        hintText: 'Shop Name (e.g. Apex Health Clinic)',
                        icon: Icons.store_outlined,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(height: 12),

                    CustomDropdownFormField<String>(
                      value: selectedCategory,
                      hintText: 'Select Category',
                      prefixIcon: Icons.category_outlined,
                      isDark: isDark,
                      items: const [
                        DropdownItemOption(
                          value: 'Clinic',
                          label: 'Clinic',
                          icon: Icons.local_hospital_rounded,
                        ),
                        DropdownItemOption(
                          value: 'Salon',
                          label: 'Salon',
                          icon: Icons.content_cut_rounded,
                        ),
                        DropdownItemOption(
                          value: 'Repair',
                          label: 'Repair',
                          icon: Icons.build_rounded,
                        ),
                        DropdownItemOption(
                          value: 'Bank',
                          label: 'Bank',
                          icon: Icons.account_balance_rounded,
                        ),
                        DropdownItemOption(
                          value: 'Restaurant',
                          label: 'Restaurant',
                          icon: Icons.restaurant_rounded,
                        ),
                        DropdownItemOption(
                          value: 'Other',
                          label: 'Other',
                          icon: Icons.storefront_rounded,
                        ),
                      ],
                      onChanged: (val) =>
                          setModalState(() => selectedCategory = val!),
                    ),
                    const SizedBox(height: 12),

                    CustomDropdownFormField<int>(
                      value: avgTime,
                      hintText: 'Avg Service Duration',
                      prefixIcon: Icons.timer_outlined,
                      isDark: isDark,
                      items: const [
                        DropdownItemOption(
                          value: 5,
                          label: '5 mins service time',
                        ),
                        DropdownItemOption(
                          value: 10,
                          label: '10 mins service time',
                        ),
                        DropdownItemOption(
                          value: 15,
                          label: '15 mins service time',
                        ),
                        DropdownItemOption(
                          value: 20,
                          label: '20 mins service time',
                        ),
                        DropdownItemOption(
                          value: 30,
                          label: '30 mins service time',
                        ),
                      ],
                      onChanged: (val) => setModalState(() => avgTime = val!),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: addressController,
                      decoration: _buildInputDecoration(
                        hintText: 'Shop Address (e.g. 102 Central Market)',
                        icon: Icons.location_on_outlined,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Section 2: Owner Account
                    Row(
                      children: [
                        const Icon(
                          Icons.badge_outlined,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Owner account credentials',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    TextField(
                      controller: ownerNameController,
                      decoration: _buildInputDecoration(
                        hintText: 'Owner Full Name (e.g. Dr. Rajesh Sharma)',
                        icon: Icons.person_outline_rounded,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: ownerEmailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _buildInputDecoration(
                        hintText: 'Owner Email (e.g. owner@clinic.com)',
                        icon: Icons.email_outlined,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: ownerPasswordController,
                      obscureText: obscureOwnerPassword,
                      decoration: _buildInputDecoration(
                        hintText: 'Assign Owner Password (min 6 chars, default: owner123)',
                        icon: Icons.lock_outline_rounded,
                        isDark: isDark,
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureOwnerPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: const Color(0xFF9CA3AF),
                            size: 20,
                          ),
                          onPressed: () => setModalState(
                            () => obscureOwnerPassword = !obscureOwnerPassword,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '* Password must be at least 6 characters. Leave blank for default "owner123".',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.neutralMid,
                      ),
                    ),
                    const SizedBox(height: 24),

                    CustomButton(
                      label: 'Provision Shop & Owner',
                      icon: Icons.check_circle_rounded,
                      color: AppColors.primary,
                      onPressed: () async {
                        final shopName = nameController.text.trim();
                        final address = addressController.text.trim();
                        final ownerEmail = ownerEmailController.text.trim();
                        final ownerPass = ownerPasswordController.text.trim();

                        if (shopName.isEmpty || ownerEmail.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please fill in Shop Name and Owner Email.',
                              ),
                            ),
                          );
                          return;
                        }

                        if (ownerPass.isNotEmpty && ownerPass.length < 6) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                '⚠️ Owner password must be at least 6 characters long.',
                              ),
                              backgroundColor: AppColors.warningUrgent,
                            ),
                          );
                          return;
                        }

                        final ownerDisplayName = ownerNameController.text
                            .trim();
                        final cleanOwnerEmail = ownerEmail.toLowerCase().trim();

                        String finalOwnerPass = ownerPass.trim();
                        if (finalOwnerPass.isEmpty || finalOwnerPass.length < 6) {
                          finalOwnerPass = 'owner123';
                        }

                        String newOwnerId =
                            'owner-${DateTime.now().millisecondsSinceEpoch}';

                        if (FirebaseService.isInitialized) {
                          final firebaseUid =
                              await FirebaseService.createFirebaseOwnerAuthAccount(
                                email: cleanOwnerEmail,
                                password: finalOwnerPass,
                                name: ownerDisplayName.isEmpty
                                    ? 'Shop Owner'
                                    : ownerDisplayName,
                              );
                          if (firebaseUid != null) {
                            newOwnerId = firebaseUid;
                          }
                        }

                        MockDatabaseService.instance.registerUserAccount(
                          cleanOwnerEmail,
                          ownerDisplayName.isEmpty
                              ? 'Shop Owner'
                              : ownerDisplayName,
                          'owner',
                          newOwnerId,
                        );

                        final newShop = ShopEntity(
                          id: '',
                          name: shopName,
                          category: selectedCategory,
                          ownerId: newOwnerId,
                          address: address.isEmpty ? 'Main Market' : address,
                          isQueueOpen: true,
                          avgServiceTimeMinutes: avgTime,
                        );

                        if (!context.mounted) return;
                        context.read<ShopBloc>().add(
                          ShopCreateRequested(newShop),
                        );
                        Navigator.pop(ctx);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Shop "$shopName" created! Owner login: $cleanOwnerEmail (Pass: $finalOwnerPass)',
                            ),
                            backgroundColor: AppColors.success,
                            duration: const Duration(seconds: 5),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openPricingControllerModal(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    context.read<SubscriptionBloc>().add(PricingConfigFetchRequested());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkCard : AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return BlocBuilder<SubscriptionBloc, SubscriptionState>(
          builder: (context, state) {
            PricingConfigEntity config = PricingConfigEntity.defaultConfig();
            if (state is PricingConfigLoaded) {
              config = state.config;
            } else if (state is SubscriptionLoaded) {
              config = state.pricingConfig;
            }

            final monthlyController = TextEditingController(text: config.monthlyPrice.toString());
            final yearlyController = TextEditingController(text: config.yearlyPrice.toString());
            final saleMonthlyController = TextEditingController(text: config.saleMonthlyPrice.toString());
            final saleYearlyController = TextEditingController(text: config.saleYearlyPrice.toString());
            final discountController = TextEditingController(text: config.discountPercentage.toString());
            final bannerController = TextEditingController(text: config.saleBannerText);
            bool isSaleActive = config.isSaleActive;

            return StatefulBuilder(
              builder: (modalCtx, setModalState) {
                return Padding(
                  padding: EdgeInsets.only(
                    top: 20,
                    left: 24,
                    right: 24,
                    bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 24,
                  ),
                  child: SingleChildScrollView(
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
                        Row(
                          children: [
                            const Icon(Icons.sell_rounded, color: AppColors.amber, size: 24),
                            const SizedBox(width: 10),
                            Text(
                              'Pricing & Sale Control',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppColors.darkText : AppColors.neutralDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Update pricing dynamically across all shops or toggle live sale offers.',
                          style: GoogleFonts.inter(fontSize: 13, color: AppColors.neutralMid),
                        ),
                        const SizedBox(height: 20),

                        // Toggle Sale Mode
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'Activate Sale Discount Mode',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.darkText : AppColors.neutralDark,
                            ),
                          ),
                          subtitle: Text(
                            'Show discounted prices & sale banner on Paywall screen',
                            style: GoogleFonts.inter(fontSize: 12, color: AppColors.neutralMid),
                          ),
                          value: isSaleActive,
                          activeColor: AppColors.amber,
                          onChanged: (val) {
                            setModalState(() {
                              isSaleActive = val;
                            });
                          },
                        ),
                        const SizedBox(height: 16),

                        // Normal Prices
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: monthlyController,
                                keyboardType: TextInputType.number,
                                decoration: _buildInputDecoration(
                                  hintText: '1',
                                  icon: Icons.currency_rupee,
                                  isDark: isDark,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: yearlyController,
                                keyboardType: TextInputType.number,
                                decoration: _buildInputDecoration(
                                  hintText: '12',
                                  icon: Icons.calendar_today_rounded,
                                  isDark: isDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Sale Prices
                        if (isSaleActive) ...[
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: saleMonthlyController,
                                  keyboardType: TextInputType.number,
                                  decoration: _buildInputDecoration(
                                    hintText: 'Sale Monthly (199)',
                                    icon: Icons.local_offer_rounded,
                                    isDark: isDark,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: saleYearlyController,
                                  keyboardType: TextInputType.number,
                                  decoration: _buildInputDecoration(
                                    hintText: 'Sale Yearly (1999)',
                                    icon: Icons.local_offer_rounded,
                                    isDark: isDark,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: bannerController,
                            decoration: _buildInputDecoration(
                              hintText: 'Sale Banner Text',
                              icon: Icons.campaign_rounded,
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        CustomButton(
                          label: 'Save Pricing Changes',
                          icon: Icons.save_rounded,
                          color: AppColors.primary,
                          onPressed: () {
                            final updated = PricingConfigEntity(
                              monthlyPrice: int.tryParse(monthlyController.text.trim()) ?? 299,
                              yearlyPrice: int.tryParse(yearlyController.text.trim()) ?? 2799,
                              discountPercentage: int.tryParse(discountController.text.trim()) ?? 20,
                              isSaleActive: isSaleActive,
                              saleBannerText: bannerController.text.trim().isEmpty ? '🔥 SPECIAL SALE!' : bannerController.text.trim(),
                              saleMonthlyPrice: int.tryParse(saleMonthlyController.text.trim()) ?? 199,
                              saleYearlyPrice: int.tryParse(saleYearlyController.text.trim()) ?? 1999,
                            );

                            context.read<SubscriptionBloc>().add(PricingConfigUpdateRequested(updated));
                            Navigator.of(ctx).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('✅ Subscription pricing updated successfully!'),
                                backgroundColor: AppColors.trustBlue,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.neutralLight,
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(
              Icons.admin_panel_settings_rounded,
              color: AppColors.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Super Admin Portal',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sell_rounded, color: AppColors.amber),
            tooltip: 'Subscription Pricing & Sale Controller',
            onPressed: () => _openPricingControllerModal(context),
          ),
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
      body: BlocBuilder<ShopBloc, ShopState>(
        builder: (context, state) {
          if (state is ShopInitial || state is ShopLoading) {
            return const SkeletonCardList(count: 4);
          }

          if (state is ShopError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.message),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => context.read<ShopBloc>().add(
                      const ShopFetchRequested(),
                    ),
                    child: const Text('Retry Loading'),
                  ),
                ],
              ),
            );
          }

          List<ShopEntity> shops = [];
          if (state is ShopsLoaded) {
            shops = state.shops;
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              context.read<ShopBloc>().add(const ShopFetchRequested());
              await Future.delayed(const Duration(milliseconds: 600));
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              children: [
                // System Overview Header Card (Flat Solid Blue #2C6FB0)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'System Control Center',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.white.withOpacity(0.85),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'SUPER ADMIN',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${shops.length} Active Registered Shops',
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Manage shops, provision owner accounts, and oversee system queues.',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Single Provision Shop CTA Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'All Registered Shops',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.darkText
                              : AppColors.neutralDark,
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _openCreateShopModal(context),
                      icon: const Icon(
                        Icons.add_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                      label: Text(
                        'Provision Shop',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        minimumSize: const Size(0, 36),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                if (shops.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Text(
                        'No shops provisioned yet.\nClick "Provision Shop" above to add the first shop!',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(color: AppColors.neutralMid),
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: shops.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final shop = shops[index];
                      return InkWell(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  AdminShopDetailsScreen(shop: shop),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkCard
                                : AppColors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.darkBorder
                                  : AppColors.border,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Distinct Category Icon in Light Blue Rounded Square Badge
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.darkBackground
                                      : AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  _getCategoryIcon(shop.category),
                                  color: AppColors.primary,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 14),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      shop.name,
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? AppColors.darkText
                                            : AppColors.neutralDark,
                                      ),
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
                                    const SizedBox(height: 4),

                                    // Truncated Owner ID with Copy Icon
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            'Owner ID: ${_truncateOwnerId(shop.ownerId)}',
                                            style: GoogleFonts.inter(
                                              fontSize: 11,
                                              color: AppColors.neutralMid,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        InkWell(
                                          onTap: () {
                                            Clipboard.setData(
                                              ClipboardData(text: shop.ownerId),
                                            );
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Owner ID copied to clipboard',
                                                ),
                                                duration: Duration(seconds: 2),
                                              ),
                                            );
                                          },
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          child: const Padding(
                                            padding: EdgeInsets.all(2.0),
                                            child: Icon(
                                              Icons.copy_rounded,
                                              size: 13,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // Queue Status Badge (Green for Open)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: shop.isQueueOpen
                                      ? AppColors.successLight
                                      : AppColors.warningUrgent.withValues(
                                          alpha: 0.12,
                                        ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  shop.isQueueOpen
                                      ? 'Queue Open'
                                      : 'Queue Closed',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: shop.isQueueOpen
                                        ? AppColors.success
                                        : AppColors.warningUrgent,
                                  ),
                                ),
                              ),

                              const SizedBox(width: 4),

                              // Delete Shop Button
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: AppColors.warningUrgent,
                                  size: 20,
                                ),
                                tooltip: 'Delete Shop',
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
                                              'Delete Shop',
                                              style: GoogleFonts.inter(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                                color: isDark ? AppColors.darkText : AppColors.neutralDark,
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            Text(
                                              'Are you sure you want to delete "${shop.name}"? This action cannot be undone.',
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
                                                  color: AppColors.warningUrgent,
                                                  borderRadius: BorderRadius.circular(10),
                                                  child: InkWell(
                                                    onTap: () {
                                                      Navigator.of(dialogContext).pop();
                                                      context.read<ShopBloc>().add(
                                                            ShopDeleteRequested(shop.id),
                                                          );
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                            '${shop.name} deleted successfully.',
                                                          ),
                                                          backgroundColor: AppColors.neutralDark,
                                                        ),
                                                      );
                                                    },
                                                    borderRadius: BorderRadius.circular(10),
                                                    child: Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                                      child: Text(
                                                        'Delete',
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
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
