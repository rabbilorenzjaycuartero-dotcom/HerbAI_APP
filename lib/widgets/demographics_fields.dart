import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/context_extensions.dart';
import '../services/user_profile_service.dart';
import '../utils/name_input.dart';
import 'custom_textfield.dart';

const int minUserAge = 10;
const int maxUserAge = 100;

/// Holds the Age / Designation / "please specify" inputs shared by the
/// Create Account, Complete Profile and Edit Profile screens.
class DemographicsController {
  final TextEditingController age = TextEditingController();
  final TextEditingController other = TextEditingController();
  String? designation;

  DemographicsController({int? initialAge, String? initialDesignation, String? initialOther}) {
    if (initialAge != null) age.text = '$initialAge';
    designation = designationOptions.contains(initialDesignation) ? initialDesignation : null;
    other.text = initialOther ?? '';
  }

  int? get ageValue => int.tryParse(age.text.trim());
  String? get otherValue => designation == 'Others' ? normalizeName(other.text) : null;

  void dispose() {
    age.dispose();
    other.dispose();
  }
}

String designationKey(String value) =>
    'designation_${value.toLowerCase().replaceAll(' ', '_')}';

/// Age (digits only, 10-100), Designation dropdown, and a required
/// "please specify" field when "Others" is chosen. Validates through the
/// enclosing Form.
class DemographicsFields extends StatefulWidget {
  final DemographicsController controller;
  final bool enabled;

  const DemographicsFields({super.key, required this.controller, this.enabled = true});

  @override
  State<DemographicsFields> createState() => _DemographicsFieldsState();
}

class _DemographicsFieldsState extends State<DemographicsFields> {
  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextField(
          hintText: context.tr('age_hint'),
          controller: c.age,
          enabled: widget.enabled,
          keyboardType: TextInputType.number,
          prefixIcon: const Icon(Icons.cake_outlined),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(3),
          ],
          validator: (value) {
            final age = int.tryParse((value ?? '').trim());
            if (age == null) return context.trRead('please_enter_age');
            if (age < minUserAge || age > maxUserAge) return context.trRead('age_out_of_range');
            return null;
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: c.designation,
          isExpanded: true,
          decoration: InputDecoration(
            hintText: context.tr('designation_hint'),
            prefixIcon: const Icon(Icons.badge_outlined),
          ),
          items: [
            for (final option in designationOptions)
              DropdownMenuItem(value: option, child: Text(context.tr(designationKey(option)))),
          ],
          onChanged: widget.enabled ? (value) => setState(() => c.designation = value) : null,
          validator: (value) => value == null ? context.trRead('please_select_designation') : null,
        ),
        if (c.designation == 'Others') ...[
          const SizedBox(height: 16),
          CustomTextField(
            hintText: context.tr('designation_other_hint'),
            controller: c.other,
            enabled: widget.enabled,
            prefixIcon: const Icon(Icons.edit_outlined),
            textCapitalization: TextCapitalization.words,
            inputFormatters: nameInputFormatters,
            validator: (value) => (value ?? '').trim().length < 2
                ? context.trRead('please_specify_designation')
                : null,
          ),
        ],
      ],
    );
  }
}
