import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../providers/symptom_provider.dart';
import '../widgets/custom_appbar.dart';
import '../widgets/custom_button.dart';
import '../widgets/decorative_blobs.dart';

class DescribeSymptomsScreen extends StatefulWidget {
  const DescribeSymptomsScreen({super.key});

  @override
  State<DescribeSymptomsScreen> createState() => _DescribeSymptomsScreenState();
}

class _DescribeSymptomsScreenState extends State<DescribeSymptomsScreen> {
  final TextEditingController _describeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // This flow starts from a clean selection so its results aren't mixed
    // with symptoms picked on the symptom list.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<SymptomProvider>();
      provider.clearSymptoms();
      provider.clearExtractionResult();
    });
  }

  @override
  void dispose() {
    _describeController.dispose();
    super.dispose();
  }

  void _detectSymptoms() {
    final provider = context.read<SymptomProvider>();
    final text = _describeController.text.trim();
    if (text.isEmpty || provider.isExtractingSymptoms) return;
    FocusScope.of(context).unfocus();
    provider.addSymptomsFromText(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Describe Your Symptoms'),
      body: Stack(
        children: [
          const DecorativeBlobs(),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildInputField(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFeedbackSection(),
                        _buildDetectedSymptoms(),
                      ],
                    ),
                  ),
                ),
                _buildBottomButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How are you feeling?',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Describe your symptoms in English, Bisaya, or Tagalog. '
            'We will pick the matching symptoms for you.',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 15,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField() {
    return Consumer<SymptomProvider>(
      builder: (context, provider, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: TextField(
            controller: _describeController,
            maxLines: 3,
            minLines: 1,
            maxLength: 500,
            textInputAction: TextInputAction.send,
            onChanged: (_) => provider.clearExtractionResult(),
            onSubmitted: (_) => _detectSymptoms(),
            decoration: InputDecoration(
              counterText: '',
              hintText: 'e.g. "headache and fever" or "sakit akong ulo"',
              hintStyle: TextStyle(color: AppTheme.textSecondary.withValues(alpha: 0.6)),
              prefixIcon: Icon(Icons.edit_note_rounded, color: AppTheme.textSecondary),
              suffixIcon: provider.isExtractingSymptoms
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : IconButton(
                      tooltip: 'Detect symptoms',
                      icon: Icon(Icons.send_rounded, color: AppTheme.primary),
                      onPressed: _detectSymptoms,
                    ),
              filled: true,
              fillColor: AppTheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(color: AppTheme.primary, width: 2.0),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeedbackSection() {
    return Consumer<SymptomProvider>(
      builder: (context, provider, child) {
        final extraction = provider.lastExtraction;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (provider.extractionError != null)
              _buildFeedback(
                provider.extractionError!,
                AppTheme.textSecondary,
                Icons.error_outline_rounded,
              ),
            if (extraction != null) ...[
              for (final s in extraction.spellingSuggestions)
                _buildFeedback(
                  "Did you mean '${s.suggestion}' instead of '${s.typed}'? "
                  'Please correct your spelling.',
                  Colors.orange.shade800,
                  Icons.spellcheck_rounded,
                ),
              if (extraction.symptomIds.isEmpty)
                _buildFeedback(
                  'No matching symptom found. Try rephrasing or check spelling.',
                  AppTheme.textSecondary,
                  Icons.search_off_rounded,
                )
              else
                _buildFeedback(
                  'Found ${extraction.symptomIds.length} symptom(s) from your description.',
                  AppTheme.primary,
                  Icons.check_circle_outline_rounded,
                ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildFeedback(String message, Color color, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 13, height: 1.4, color: color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetectedSymptoms() {
    return Consumer<SymptomProvider>(
      builder: (context, provider, child) {
        final symptoms = provider.selectedSymptoms;
        if (symptoms.isEmpty) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.only(top: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Detected symptoms (tap x to remove)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: symptoms
                    .map(
                      (symptom) => InputChip(
                        label: Text(symptom.name),
                        labelStyle: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary,
                        ),
                        backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                        side: BorderSide(color: AppTheme.primary.withValues(alpha: 0.3)),
                        deleteIconColor: AppTheme.primary,
                        onDeleted: () => provider.toggleSymptom(symptom),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomButton() {
    return Consumer<SymptomProvider>(
      builder: (context, provider, child) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.background,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: CustomButton(
              text: 'Get Recommendations',
              onPressed: provider.hasSelectedSymptoms
                  ? () {
                      context.push('/health-check');
                    }
                  : null,
              borderRadius: 30,
            ),
          ),
        );
      },
    );
  }
}
