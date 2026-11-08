import 'package:flutter/material.dart';

/// Green checkmark badge for herbs matching DOH's list of 10 clinically
/// tested herbal medicines (see api_server.py's "DOH Approved" column) --
/// informational only, does not affect recommendation ranking.
class DohApprovedBadge extends StatelessWidget {
  final double size;

  const DohApprovedBadge({super.key, this.size = 16});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'DOH Clinically Approved',
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Colors.green,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.check_rounded, size: size * 0.7, color: Colors.white),
      ),
    );
  }
}
