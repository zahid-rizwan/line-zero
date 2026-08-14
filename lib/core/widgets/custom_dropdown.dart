import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class DropdownItemOption<T> {
  final T value;
  final String label;
  final IconData? icon;

  const DropdownItemOption({
    required this.value,
    required this.label,
    this.icon,
  });
}

class CustomDropdownFormField<T> extends StatefulWidget {
  final T? value;
  final String hintText;
  final IconData? prefixIcon;
  final List<DropdownItemOption<T>> items;
  final ValueChanged<T?> onChanged;
  final bool isDark;

  const CustomDropdownFormField({
    super.key,
    required this.value,
    required this.hintText,
    required this.items,
    required this.onChanged,
    this.prefixIcon,
    this.isDark = false,
  });

  @override
  State<CustomDropdownFormField<T>> createState() => _CustomDropdownFormFieldState<T>();
}

class _CustomDropdownFormFieldState<T> extends State<CustomDropdownFormField<T>>
    with SingleTickerProviderStateMixin {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _removeOverlay();
    _animationController.dispose();
    super.dispose();
  }

  void _toggleDropdown() {
    if (_isOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            // Backdrop to close dropdown on tap outside
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _closeDropdown,
                child: const SizedBox.expand(),
              ),
            ),

            // Connected Overlay Panel directly below input field with matching width
            CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: Offset(0, size.height + 6),
              child: Material(
                elevation: 8,
                shadowColor: Colors.black.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                color: widget.isDark ? AppColors.darkCard : Colors.white,
                child: Container(
                  width: size.width,
                  constraints: const BoxConstraints(maxHeight: 260),
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                  decoration: BoxDecoration(
                    color: widget.isDark ? AppColors.darkCard : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: widget.isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB),
                      width: 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: widget.items.length,
                      separatorBuilder: (context, index) => Divider(
                        height: 1,
                        thickness: 0.5,
                        color: widget.isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB),
                      ),
                      itemBuilder: (context, index) {
                        final item = widget.items[index];
                        final isSelected = item.value == widget.value;

                        return InkWell(
                          onTap: () {
                            widget.onChanged(item.value);
                            _closeDropdown();
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? (widget.isDark
                                      ? AppColors.primaryDark.withValues(alpha: 0.4)
                                      : AppColors.primaryLight)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                if (item.icon != null) ...[
                                  Icon(
                                    item.icon,
                                    size: 18,
                                    color: isSelected
                                        ? AppColors.primary
                                        : (widget.isDark ? AppColors.neutralMid : AppColors.neutralDark),
                                  ),
                                  const SizedBox(width: 10),
                                ],
                                Expanded(
                                  child: Text(
                                    item.label,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                      color: isSelected
                                          ? AppColors.primary
                                          : (widget.isDark ? AppColors.darkText : AppColors.neutralDark),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(
                                    Icons.check_rounded,
                                    size: 18,
                                    color: AppColors.primary,
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isOpen = true);
    _animationController.forward();
  }

  void _closeDropdown() {
    _removeOverlay();
    if (mounted) {
      setState(() => _isOpen = false);
      _animationController.reverse();
    }
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    DropdownItemOption<T>? selectedItem;
    try {
      selectedItem = widget.items.firstWhere((item) => item.value == widget.value);
    } catch (_) {
      selectedItem = null;
    }

    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: _toggleDropdown,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: widget.isDark ? AppColors.darkBackground : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isOpen
                  ? AppColors.primary
                  : (widget.isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB)),
              width: _isOpen ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              if (widget.prefixIcon != null) ...[
                Icon(
                  widget.prefixIcon,
                  color: const Color(0xFF9CA3AF),
                  size: 20,
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  selectedItem != null ? selectedItem.label : widget.hintText,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: selectedItem != null
                        ? (widget.isDark ? AppColors.darkText : AppColors.neutralDark)
                        : const Color(0xFF9CA3AF),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              RotationTransition(
                turns: Tween<double>(begin: 0.0, end: 0.5).animate(_animationController),
                child: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Color(0xFF9CA3AF),
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
