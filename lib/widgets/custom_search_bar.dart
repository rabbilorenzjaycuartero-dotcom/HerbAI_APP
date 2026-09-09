import 'package:flutter/material.dart';
import 'custom_textfield.dart';

class CustomSearchBar extends StatelessWidget {
  final TextEditingController? controller;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final String hintText;
  final VoidCallback? onTap;
  final bool? enabled;

  const CustomSearchBar({
    super.key,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.hintText = 'Search herbs...',
    this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: IgnorePointer(
        ignoring: onTap != null,
        child: CustomTextField(
          hintText: hintText,
          controller: controller,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          prefixIcon: const Icon(Icons.search),
          textInputAction: TextInputAction.search,
          enabled: enabled ?? true,
        ),
      ),
    );
  }
}
