import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../domain/entities/shop_entity.dart';
import '../bloc/shop_bloc.dart';
import '../bloc/shop_event.dart';
import '../bloc/shop_state.dart';
import 'owner_dashboard_screen.dart';

class CreateShopScreen extends StatefulWidget {
  final String ownerId;

  const CreateShopScreen({super.key, required this.ownerId});

  @override
  State<CreateShopScreen> createState() => _CreateShopScreenState();
}

class _CreateShopScreenState extends State<CreateShopScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  String _selectedCategory = 'Clinic';
  int _avgServiceTime = 10;

  final List<String> _categories = ['Clinic', 'Salon', 'Repair', 'Bank', 'Restaurant', 'Other'];

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _onSaveShop() {
    if (_formKey.currentState!.validate()) {
      final shop = ShopEntity(
        id: '',
        name: _nameController.text.trim(),
        category: _selectedCategory,
        ownerId: widget.ownerId,
        address: _addressController.text.trim(),
        isQueueOpen: true,
        avgServiceTimeMinutes: _avgServiceTime,
      );

      context.read<ShopBloc>().add(ShopCreateRequested(shop));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutralLight,
      appBar: AppBar(
        title: const Text('Create Shop Profile'),
      ),
      body: BlocConsumer<ShopBloc, ShopState>(
        listener: (context, state) {
          if (state is OwnerShopLoaded && state.shop != null) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => OwnerDashboardScreen(ownerId: widget.ownerId),
              ),
            );
          } else if (state is ShopError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.warningUrgent,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is ShopLoading;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Shop Information',
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.neutralDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Set up your digital queue profile so customers can find you.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.neutralMid,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Shop Name
                    Text(
                      'Shop / Business Name',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.neutralDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      validator: (val) => val == null || val.trim().isEmpty ? 'Please enter shop name' : null,
                      decoration: const InputDecoration(
                        hintText: 'e.g., Apex Health Clinic',
                        prefixIcon: Icon(Icons.storefront_rounded, color: AppColors.neutralMid),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Category Dropdown
                    Text(
                      'Category',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.neutralDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCategory,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.category_outlined, color: AppColors.neutralMid),
                      ),
                      items: _categories.map((cat) {
                        return DropdownMenuItem(
                          value: cat,
                          child: Text(cat),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedCategory = val);
                        }
                      },
                    ),
                    const SizedBox(height: 20),

                    // Address
                    Text(
                      'Address / Location Details',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.neutralDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _addressController,
                      validator: (val) => val == null || val.trim().isEmpty ? 'Please enter address' : null,
                      decoration: const InputDecoration(
                        hintText: 'e.g., 42 Main Street, Sector 15',
                        prefixIcon: Icon(Icons.location_on_outlined, color: AppColors.neutralMid),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Avg Service Time Slider
                    Text(
                      'Estimated Avg Service Time per Customer',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.neutralDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '$_avgServiceTime minutes',
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              const Icon(Icons.timer_outlined, color: AppColors.primary),
                            ],
                          ),
                          Slider(
                            value: _avgServiceTime.toDouble(),
                            min: 3,
                            max: 60,
                            divisions: 19,
                            activeColor: AppColors.primary,
                            label: '$_avgServiceTime mins',
                            onChanged: (val) {
                              setState(() {
                                _avgServiceTime = val.round();
                              });
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 36),
                    CustomButton(
                      label: 'Create & Open Queue',
                      onPressed: _onSaveShop,
                      isLoading: isLoading,
                      icon: Icons.check_circle_outline,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
