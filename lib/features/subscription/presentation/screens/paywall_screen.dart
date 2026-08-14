import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:queue_token_app/core/theme/app_colors.dart';
import 'package:queue_token_app/core/widgets/custom_button.dart';
import '../bloc/subscription_bloc.dart';
import '../bloc/subscription_event.dart';
import '../bloc/subscription_state.dart';

class PaywallScreen extends StatefulWidget {
  final String shopId;
  final String shopName;

  const PaywallScreen({
    super.key,
    required this.shopId,
    required this.shopName,
  });

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  String _selectedPlan = 'yearly'; // 'monthly' | 'yearly'

  @override
  Widget build(BuildContext context) {
    return BlocListener<SubscriptionBloc, SubscriptionState>(
      listener: (context, state) {
        if (state is SubscriptionLoaded && state.subscription.isActive) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎉 Subscription Activated! Queue controls unlocked.'),
              backgroundColor: AppColors.trustBlue,
            ),
          );
        } else if (state is SubscriptionFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.coralRed,
            ),
          );
        }
      },
      child: Container(
        color: AppColors.slateDark,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 12),
              // Header Badge & Icon
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.amber.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.star_rounded,
                  size: 42,
                  color: AppColors.amber,
                ),
              ),
              const SizedBox(height: 20),

              // Title & Subtitle
              Text(
                'Unlock LineZero Pro',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Free Trial for ${widget.shopName} has ended.\nSubscribe to continue serving customers seamlessly.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.white70,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),

              // Plan Cards (Monthly vs Yearly)
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildPlanCard(
                        planKey: 'yearly',
                        title: 'Yearly Access',
                        price: '₹2,799 / year',
                        subtitle: 'Equivalent to ₹233/month. Billed annually.',
                        badgeText: 'SAVE 20%',
                      ),
                      const SizedBox(height: 16),
                      _buildPlanCard(
                        planKey: 'monthly',
                        title: 'Monthly Access',
                        price: '₹299 / month',
                        subtitle: 'Flexible month-to-month subscription. Cancel anytime.',
                        badgeText: null,
                      ),
                      const SizedBox(height: 24),

                      // Data Reassurance Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.shield_outlined, color: AppColors.trustBlue, size: 28),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                'Your shop profile and queue records are completely safe and will unlock instantly upon subscribing.',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.white70,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // CTA Subscribe Button
              BlocBuilder<SubscriptionBloc, SubscriptionState>(
                builder: (context, state) {
                  final isLoading = state is SubscriptionLoading;
                  return CustomButton(
                    label: 'Subscribe Now (${_selectedPlan == 'yearly' ? '₹2,799/yr' : '₹299/mo'})',
                    isLoading: isLoading,
                    onPressed: () {
                      context.read<SubscriptionBloc>().add(
                            SubscribeRequested(
                              shopId: widget.shopId,
                              plan: _selectedPlan,
                            ),
                          );
                    },
                  );
                },
              ),

              const SizedBox(height: 12),

              // Restore Purchases Button
              TextButton(
                onPressed: () {
                  context.read<SubscriptionBloc>().add(
                        RestorePurchasesRequested(widget.shopId),
                      );
                },
                child: Text(
                  'Restore Previous Purchases',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.white54,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCard({
    required String planKey,
    required String title,
    required String price,
    required String subtitle,
    String? badgeText,
  }) {
    final isSelected = _selectedPlan == planKey;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPlan = planKey;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.trustBlue.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.trustBlue : Colors.white12,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Radio Circle
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.trustBlue : Colors.white38,
                  width: 2,
                ),
                color: isSelected ? AppColors.trustBlue : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 16),

            // Plan Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      if (badgeText != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.amber,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            badgeText,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.slateDark,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    price,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? AppColors.trustBlue : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
