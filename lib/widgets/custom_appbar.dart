import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../core/app_constants.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final bool showBackButton;
  final List<Widget>? actions;

  const CustomAppBar({
    super.key,
    this.title,
    this.showBackButton = true,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: title != null
          ? Text(
              title!,
              style: const TextStyle(fontWeight: FontWeight.bold),
            )
          : Row(
              children: [
                Icon(Icons.eco, color: AppTheme.primary, size: 28),
                const SizedBox(width: 8),
                Text(
                  AppConstants.appName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
              ],
            ),
      centerTitle: false,
      elevation: 0,
      automaticallyImplyLeading: showBackButton,
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
