import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../shop/presentation/bloc/shop_bloc.dart';
import '../../../shop/presentation/bloc/shop_event.dart';
import '../../../shop/presentation/screens/owner_dashboard_screen.dart';
import '../../../queue/presentation/screens/customer_shop_list_screen.dart';
import '../../domain/entities/user_entity.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';

class RoleSelectionScreen extends StatefulWidget {
  final UserEntity user;

  const RoleSelectionScreen({super.key, required this.user});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  String _selectedRole = 'customer';

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.user.role;
  }

  void _onRoleSelected(String role) {
    setState(() {
      _selectedRole = role;
    });
    context.read<AuthBloc>().add(AuthRoleUpdated(role));

    if (role == 'owner') {
      context.read<ShopBloc>().add(OwnerShopFetchRequested(widget.user.id));
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => OwnerDashboardScreen(ownerId: widget.user.id),
        ),
      );
    } else {
      context.read<ShopBloc>().add(const ShopFetchRequested());
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => CustomerShopListScreen(user: widget.user),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutralLight,
      appBar: AppBar(
        title: const Text('Select Your Role'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthBloc>().add(AuthSignOutRequested());
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'How will you use Q-Token today?',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.neutralDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select your mode to continue.',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: AppColors.neutralMid,
                ),
              ),
              const SizedBox(height: 32),

              // Customer Role Card
              _buildRoleOptionCard(
                title: 'Customer',
                description: 'Join live queues, track real-time position remotely, get notified when your turn is near.',
                icon: Icons.person_rounded,
                role: 'customer',
                isSelected: _selectedRole == 'customer',
                onTap: () => _onRoleSelected('customer'),
              ),

              const SizedBox(height: 20),

              // Shop Owner Role Card
              _buildRoleOptionCard(
                title: 'Shop Owner / Manager',
                description: 'Manage live shop queue, call next customer, skip/complete tokens, toggle queue status.',
                icon: Icons.store_rounded,
                role: 'owner',
                isSelected: _selectedRole == 'owner',
                onTap: () => _onRoleSelected('owner'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleOptionCard({
    required String title,
    required String description,
    required IconData icon,
    required String role,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight.withAlpha(120) : AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppColors.primary.withAlpha(30),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.neutralLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                size: 28,
                color: isSelected ? AppColors.white : AppColors.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.neutralDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.neutralMid,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.arrow_forward_ios_rounded,
              color: isSelected ? AppColors.primary : AppColors.neutralMid,
              size: isSelected ? 24 : 16,
            ),
          ],
        ),
      ),
    );
  }
}
