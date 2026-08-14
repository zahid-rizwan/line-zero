import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_colors.dart';

class OnboardingScreen extends StatefulWidget {
  final Widget targetScreen;

  const OnboardingScreen({super.key, required this.targetScreen});

  static const String keyHasSeenOnboarding = 'has_seen_onboarding';

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingItem> _items = [
    OnboardingItem(
      title: 'Zero Waiting in Lines',
      subtitle:
          'Say goodbye to crowded waiting rooms. Join digital queues from anywhere with just one tap.',
      icon: Icons.confirmation_number_rounded,
      iconColor: AppColors.primary,
      bgColor: AppColors.primaryLight,
    ),
    OnboardingItem(
      title: 'Live Alerts & Voice Updates',
      subtitle:
          'Receive instant push notifications & voice alerts when your turn is near. Shop or relax stress-free.',
      icon: Icons.notifications_active_rounded,
      iconColor: AppColors.amber,
      bgColor: AppColors.amberLight,
    ),
    OnboardingItem(
      title: 'Smart Queues Everywhere',
      subtitle:
          'Clinics, salons, restaurants, & service centers — experience smooth digital queues everywhere.',
      icon: Icons.storefront_rounded,
      iconColor: AppColors.success,
      bgColor: AppColors.successLight,
    ),
  ];

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(OnboardingScreen.keyHasSeenOnboarding, true);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, anim1, anim2) => widget.targetScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar: Skip Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (_currentPage < _items.length - 1)
                    TextButton(
                      onPressed: _completeOnboarding,
                      child: Text(
                        'Skip',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.neutralMid,
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 48),
                ],
              ),
            ),

            // Onboarding PageView Slider
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _items.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Illustration/Icon Circle
                        Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkCard : item.bgColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: item.iconColor.withValues(alpha: 0.15),
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Icon(
                            item.icon,
                            size: 80,
                            color: item.iconColor,
                          ),
                        ),

                        const SizedBox(height: 48),

                        // Title
                        Text(
                          item.title,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkText : AppColors.neutralDark,
                            height: 1.25,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Subtitle Description
                        Text(
                          item.subtitle,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            color: isDark
                                ? AppColors.darkText.withValues(alpha: 0.7)
                                : AppColors.neutralMid,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom Navigation Footer (Dots Centered in Middle, Button Floating on Right)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Centered Dot Indicators in Middle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _items.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? AppColors.primary
                              : (isDark
                                  ? AppColors.darkBorder
                                  : AppColors.border),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),

                  // Circular Action Icon Button on Right
                  Align(
                    alignment: Alignment.centerRight,
                    child: Material(
                      color: AppColors.primary,
                      shape: const CircleBorder(),
                      elevation: 2,
                      shadowColor: AppColors.primary.withValues(alpha: 0.3),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () {
                          if (_currentPage < _items.length - 1) {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 350),
                              curve: Curves.easeInOut,
                            );
                          } else {
                            _completeOnboarding();
                          }
                        },
                        child: Container(
                          width: 56,
                          height: 56,
                          alignment: Alignment.center,
                          child: Icon(
                            _currentPage == _items.length - 1
                                ? Icons.check_rounded
                                : Icons.chevron_right_rounded,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ),
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

class OnboardingItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;

  OnboardingItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
  });
}
