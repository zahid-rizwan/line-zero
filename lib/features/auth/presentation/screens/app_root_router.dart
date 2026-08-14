import 'package:flutter/material.dart';
import 'package:queue_token_app/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:queue_token_app/features/auth/domain/entities/user_entity.dart';
import 'package:queue_token_app/features/queue/presentation/screens/customer_shop_list_screen.dart';
import 'package:queue_token_app/features/shop/presentation/screens/owner_dashboard_screen.dart';

class AppRootRouter extends StatelessWidget {
  final UserEntity user;

  const AppRootRouter({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    // 1. Super Admin Role
    if (user.role == 'admin') {
      return AdminDashboardScreen(adminUser: user);
    }

    // 2. Shop Owner Role
    if (user.role == 'owner') {
      return OwnerDashboardScreen(ownerId: user.id);
    }

    // 3. Customer Role (Default)
    return CustomerShopListScreen(user: user);
  }
}
